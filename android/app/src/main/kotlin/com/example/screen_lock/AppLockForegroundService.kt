package com.example.screen_lock

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Native Android Background Service.
 *
 * Runs a continuous Coroutine loop (every 250ms) querying UsageStatsManager
 * to detect the current foreground app as a robust fallback.
 * Keeps the security process resilient against Android OS and Samsung One UI background killing.
 */
class AppLockForegroundService : Service() {

    companion object {
        private const val TAG = "AppLockForegroundSvc"
        const val POLLING_INTERVAL_MS = 250L

        @Volatile
        var isServiceActive = false

        fun start(context: Context) {
            val intent = Intent(context, AppLockForegroundService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start AppLockForegroundService: ${e.message}")
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, AppLockForegroundService::class.java)
            context.stopService(intent)
        }
    }

    private var pollingJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Default)
    private var usageStatsManager: UsageStatsManager? = null
    private var lastObservedPackage: String? = null

    private val screenReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                Log.d(TAG, "Screen off broadcast received. Relocking all applications immediately.")
                NativeLockManager.clearAllUnlockedSessions()
                // DO NOT dismiss the overlay on screen off.
                // Keeping the overlay in place ensures that when the device screen turns back on,
                // the lock overlay is already covering the protected application.
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        isServiceActive = true
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
        createNotificationChannel()
        startAsForeground()

        try {
            val filter = android.content.IntentFilter(Intent.ACTION_SCREEN_OFF)
            registerReceiver(screenReceiver, filter)
        } catch (e: Exception) {
            Log.w(TAG, "Could not register screenReceiver: ${e.message}")
        }

        startPollingLoop()
        Log.i(TAG, "AppLockForegroundService initialized and active")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isServiceActive = true
        if (pollingJob == null || pollingJob?.isActive != true) {
            startPollingLoop()
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NativeBridgeConstants.NOTIFICATION_CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.notification_channel_desc)
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startAsForeground() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification: Notification = NotificationCompat.Builder(this, NativeBridgeConstants.NOTIFICATION_CHANNEL_ID)
            .setContentTitle(getString(R.string.notification_title))
            .setContentText(getString(R.string.notification_text))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (Build.VERSION.SDK_INT >= 34) { // Android 14+
                startForeground(
                    NativeBridgeConstants.NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NativeBridgeConstants.NOTIFICATION_ID, notification)
            }
        } else {
            startForeground(NativeBridgeConstants.NOTIFICATION_ID, notification)
        }
    }

    private fun startPollingLoop() {
        pollingJob?.cancel()
        pollingJob = serviceScope.launch {
            while (isActive) {
                try {
                    checkForegroundPackage()
                } catch (e: Exception) {
                    Log.e(TAG, "Error in usage stats polling: ${e.message}")
                }
                // When 0ms AccessibilityService is actively capturing window transitions,
                // relax UsageStats polling to save battery and CPU on entry-level/low-end devices.
                val interval = if (AppLockAccessibilityService.isServiceRunning) {
                    1500L
                } else {
                    POLLING_INTERVAL_MS
                }
                delay(interval)
            }
        }
    }

    private fun checkForegroundPackage() {
        val mgr = usageStatsManager ?: return
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 5 // Scan last 5 seconds

        val events = mgr.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        var lastResumedPackage: String? = null

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    if (!NativeLockManager.isSystemOrTransientPackage(pkg)) {
                        lastResumedPackage = pkg
                    }
                }
                UsageEvents.Event.KEYGUARD_SHOWN,
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    NativeLockManager.clearAllUnlockedSessions()
                }
            }
        }

        // Inactivity does NOT mean the user exited the application.
        // If no new resume events were dispatched in this polling window, retain the last observed package.
        val currentPackage = lastResumedPackage ?: lastObservedPackage

        if (currentPackage != null && !NativeLockManager.isSystemOrTransientPackage(currentPackage)) {
            if (currentPackage != lastObservedPackage) {
                lastObservedPackage = currentPackage
                NativeLockManager.onForegroundPackageChanged(applicationContext, currentPackage)
            }

            // CRITICAL CONTINUOUS LOCK ENFORCEMENT:
            // Ensure the lock screen overlay remains active and visible indefinitely
            // until the user enters the correct PIN or passes valid biometric authentication.
            if (NativeLockManager.shouldLock(applicationContext, currentPackage)) {
                if (!NativeLockManager.isOverlayVisible || NativeLockManager.activeOverlayPackage != currentPackage) {
                    Log.d(TAG, "Enforcing lock screen for: $currentPackage")
                    OverlayController.showLockOverlay(applicationContext, currentPackage)
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceActive = false
        pollingJob?.cancel()
        try {
            unregisterReceiver(screenReceiver)
        } catch (_: Exception) {}
        Log.i(TAG, "AppLockForegroundService stopped")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
