package com.example.screen_lock

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity extending FlutterFragmentActivity.
 *
 * NOTE: FlutterFragmentActivity is required by the `local_auth` plugin on Android
 * to display the native biometric prompt dialog.
 *
 * It bridges Flutter with native Android services for:
 * 1. Background foreground-app detection service management.
 * 2. System permissions (Usage Access, Display Overlay, Accessibility).
 * 3. Samsung One UI battery optimization and Knox handling.
 * 4. Synchronization of locked packages to native memory.
 */
class MainActivity : FlutterFragmentActivity() {

    companion object {
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val KEY_RECENT_APPS_PRIVACY = "flutter.pref_recent_apps_privacy"

        fun isRecentAppsPrivacyEnabled(context: Context): Boolean {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getBoolean(KEY_RECENT_APPS_PRIVACY, true)
        }

        fun setRecentAppsPrivacyEnabled(context: Context, enabled: Boolean) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean(KEY_RECENT_APPS_PRIVACY, enabled).commit()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyPrivacyFlags(isRecentAppsPrivacyEnabled(this))
    }

    override fun onResume() {
        super.onResume()
        applyPrivacyFlags(isRecentAppsPrivacyEnabled(this))
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        applyPrivacyFlags(isRecentAppsPrivacyEnabled(this))
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            applyPrivacyFlags(isRecentAppsPrivacyEnabled(this))
        }
    }

    private fun applyPrivacyFlags(enabled: Boolean) {
        runOnUiThread {
            if (enabled) {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    try {
                        setRecentsScreenshotEnabled(false)
                    } catch (e: Throwable) {
                        // OEM fallback
                    }
                }
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    try {
                        setRecentsScreenshotEnabled(true)
                    } catch (e: Throwable) {
                        // OEM fallback
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Pre-warm the overlay Flutter Engine so it is instantly available
        OverlayController.ensureEngineInitialized(this)

        // 1. Service & Permission Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeBridgeConstants.SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        NativeLockManager.setProtectionEnabled(this, true)
                        AppLockForegroundService.start(this)
                        result.success(true)
                    }
                    "stopService" -> {
                        NativeLockManager.setProtectionEnabled(this, false)
                        AppLockForegroundService.stop(this)
                        result.success(true)
                    }
                    "notifyOverlayClosed" -> {
                        NativeLockManager.activeOverlayPackage = null
                        NativeLockManager.isOverlayVisible = false
                        OverlayController.dismissOverlay(this)
                        result.success(true)
                    }
                    "isServiceRunning" -> {
                        val active = AppLockForegroundService.isServiceActive || AppLockAccessibilityService.isServiceRunning
                        result.success(active)
                    }
                    "hasUsageStatsPermission" -> {
                        result.success(hasUsageStatsPermission())
                    }
                    "requestUsageStatsPermission" -> {
                        try {
                            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to open Usage Access settings: ${e.message}", null)
                        }
                    }
                    "hasOverlayPermission" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }
                    "requestOverlayPermission" -> {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to open Overlay settings: ${e.message}", null)
                        }
                    }
                    "isAccessibilityEnabled" -> {
                        result.success(AppLockAccessibilityService.isEnabled(this))
                    }
                    "requestAccessibilityPermission" -> {
                        try {
                            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to open Accessibility settings: ${e.message}", null)
                        }
                    }
                    "syncLockedPackages" -> {
                        val packages = call.argument<List<String>>("packages")
                        if (packages != null) {
                            NativeLockManager.setLockedPackages(this, packages.toSet())
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Package list is required", null)
                        }
                    }
                    "syncSettings" -> {
                        val enabled = call.argument<Boolean>("protectionEnabled") ?: true
                        val timeout = call.argument<Number>("relockTimeoutMs")?.toLong() ?: 0L
                        val uninstallProt = call.argument<Boolean>("uninstallProtection") ?: false
                        NativeLockManager.setProtectionEnabled(this, enabled)
                        NativeLockManager.setRelockTimeoutMs(this, timeout)
                        NativeLockManager.setUninstallProtectionEnabled(this, uninstallProt)
                        result.success(true)
                    }
                    "setUninstallProtection" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        NativeLockManager.setUninstallProtectionEnabled(this, enabled)
                        result.success(true)
                    }
                    "getUninstallProtection" -> {
                        result.success(NativeLockManager.isUninstallProtectionEnabled(this))
                    }
                    "unlockPackageSession" -> {
                        val pkg = call.argument<String>("package") ?: NativeLockManager.currentForegroundPackage ?: ""
                        if (pkg.isNotEmpty()) {
                            NativeLockManager.markAppUnlocked(this, pkg)
                        }
                        OverlayController.dismissOverlay(this)
                        result.success(true)
                    }
                    "isKnoxProtected" -> {
                        val pkg = call.argument<String>("package") ?: ""
                        result.success(SamsungHelper.isKnoxPackageSafe(this, pkg))
                    }
                    "testShowOverlay" -> {
                        val pkg = call.argument<String>("package") ?: "com.whatsapp"
                        OverlayController.showLockOverlay(this, pkg)
                        result.success(true)
                    }
                    "syncPin" -> {
                        val pin = call.argument<String>("pin") ?: ""
                        if (pin.isNotEmpty()) {
                            getSharedPreferences(NativeBridgeConstants.PREFS_NAME, Context.MODE_PRIVATE)
                                .edit()
                                .putString(NativeBridgeConstants.KEY_PIN_HASH, pin)
                                .commit()
                            getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                                .edit()
                                .putString("flutter.pref_pin_hash", pin)
                                .commit()
                            result.success(true)
                        } else {
                            result.error("INVALID_PIN", "PIN cannot be empty", null)
                        }
                    }
                    "verifyPin" -> {
                        val pin = call.argument<String>("pin") ?: ""
                        val saved = getSharedPreferences(NativeBridgeConstants.PREFS_NAME, Context.MODE_PRIVATE)
                            .getString(NativeBridgeConstants.KEY_PIN_HASH, "")
                            ?.takeIf { it.isNotEmpty() }
                            ?: getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                                .getString("flutter.pref_pin_hash", "")
                                ?.takeIf { it.isNotEmpty() }
                            ?: "123456"
                        result.success(pin.isNotEmpty() && pin == saved)
                    }
                    "goHome" -> {
                        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(homeIntent)
                        OverlayController.dismissOverlay(this)
                        result.success(true)
                    }
                    "triggerBiometric" -> {
                        val pkg = call.argument<String>("package") ?: NativeLockManager.currentForegroundPackage ?: ""
                        val appName = call.argument<String>("appName") ?: "Protected App"
                        BiometricPromptActivity.startWithCallback(this, pkg, appName, BiometricPromptActivity.MODE_UNLOCK) { success ->
                            runOnUiThread {
                                try {
                                    result.success(success)
                                } catch (e: Exception) {
                                    android.util.Log.w("MainActivity", "Biometric callback note: ${e.message}")
                                }
                            }
                        }
                    }
                    "triggerForgotPinVerification" -> {
                        val pkg = call.argument<String>("package") ?: NativeLockManager.currentForegroundPackage ?: ""
                        val appName = call.argument<String>("appName") ?: "Protected App"
                        BiometricPromptActivity.startWithCallback(this, pkg, appName, BiometricPromptActivity.MODE_FORGOT_PIN) { success ->
                            runOnUiThread {
                                try {
                                    result.success(success)
                                } catch (e: Exception) {
                                    android.util.Log.w("MainActivity", "Biometric forgot pin callback note: ${e.message}")
                                }
                            }
                        }
                    }
                    "isBiometricAvailable" -> {
                        result.success(BiometricPromptActivity.isBiometricAvailable(this))
                    }
                    "setRecentAppsPrivacy" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        setRecentAppsPrivacyEnabled(this, enabled)
                        applyPrivacyFlags(enabled)
                        result.success(true)
                    }
                    "isRecentAppsPrivacyEnabled" -> {
                        result.success(isRecentAppsPrivacyEnabled(this))
                    }
                    else -> result.notImplemented()
                }
            }

        // 2. Samsung One UI Specific Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeBridgeConstants.SAMSUNG_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSamsungDevice" -> {
                        result.success(SamsungHelper.isSamsungDevice())
                    }
                    "getOneUiVersion" -> {
                        result.success(SamsungHelper.getOneUiVersion())
                    }
                    "isBatteryOptimizationIgnored" -> {
                        result.success(SamsungHelper.isBatteryOptimizationIgnored(this))
                    }
                    "requestIgnoreBatteryOptimization" -> {
                        val opened = SamsungHelper.openSamsungBatterySettings(this)
                        result.success(opened)
                    }
                    "openSamsungAutoRunSettings" -> {
                        val opened = SamsungHelper.openSamsungAutoRunSettings(this)
                        result.success(opened)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageStatsPermission(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            } else {
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }
}
