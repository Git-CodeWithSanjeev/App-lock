package com.example.screen_lock

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.JSONMessageCodec

/**
 * Native Overlay Controller.
 *
 * Dispatches the overlay trigger directly from Android native background services.
 * Using TYPE_APPLICATION_OVERLAY allows the lock UI to render immediately over
 * the target application without waiting for Flutter's main navigation stack.
 */
object OverlayController {
    private const val TAG = "OverlayController"

    // Exact constants from flutter_overlay_window library
    private const val CACHED_ENGINE_TAG = "myCachedEngine"
    private const val MESSENGER_CHANNEL_TAG = "x-slayer/overlay_messenger"

    fun ensureEngineInitialized(context: Context) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            Handler(Looper.getMainLooper()).post { ensureEngineInitialized(context) }
            return
        }

        var engine = FlutterEngineCache.getInstance().get(CACHED_ENGINE_TAG)
        if (engine == null) {
            try {
                val enn = io.flutter.embedding.engine.FlutterEngineGroup(context.applicationContext)
                val dEntry = io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint(
                    io.flutter.FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                    "overlayMain"
                )
                engine = enn.createAndRunEngine(context.applicationContext, dEntry)
                FlutterEngineCache.getInstance().put(CACHED_ENGINE_TAG, engine)
                Log.i(TAG, "Initialized and cached overlay FlutterEngine successfully")
            } catch (e: Throwable) {
                Log.e(TAG, "Failed to pre-warm overlay FlutterEngine: ${e.message}", e)
            }
        }

        if (engine != null) {
            registerChannels(engine, context.applicationContext)
        }
    }

    fun registerChannels(engine: io.flutter.embedding.engine.FlutterEngine, context: Context) {
        val messenger = engine.dartExecutor.binaryMessenger

        io.flutter.plugin.common.MethodChannel(messenger, NativeBridgeConstants.SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "unlockPackageSession" -> {
                        val pkg = call.argument<String>("package") ?: NativeLockManager.currentForegroundPackage ?: ""
                        if (pkg.isNotEmpty()) {
                            NativeLockManager.markAppUnlocked(context, pkg)
                            if (pkg == context.packageName) {
                                NativeLockManager.markUninstallAuthorized()
                            }
                        }
                        dismissOverlay(context)
                        result.success(true)
                    }
                    "goHome" -> {
                        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(homeIntent)
                        dismissOverlay(context)
                        result.success(true)
                    }
                    "notifyOverlayClosed" -> {
                        dismissOverlay(context)
                        result.success(true)
                    }
                    "triggerBiometric" -> {
                        val pkg = call.argument<String>("package") ?: NativeLockManager.currentForegroundPackage ?: ""
                        val appName = call.argument<String>("appName") ?: "Protected App"
                        BiometricPromptActivity.startWithCallback(context, pkg, appName, BiometricPromptActivity.MODE_UNLOCK) { success ->
                            Handler(Looper.getMainLooper()).post {
                                try {
                                    result.success(success)
                                } catch (e: Exception) {
                                    Log.w(TAG, "Biometric callback note: ${e.message}")
                                }
                            }
                        }
                    }
                    "triggerForgotPinVerification" -> {
                        val pkg = call.argument<String>("package") ?: NativeLockManager.currentForegroundPackage ?: ""
                        val appName = call.argument<String>("appName") ?: "Protected App"
                        BiometricPromptActivity.startWithCallback(context, pkg, appName, BiometricPromptActivity.MODE_FORGOT_PIN) { success ->
                            Handler(Looper.getMainLooper()).post {
                                try {
                                    result.success(success)
                                } catch (e: Exception) {
                                    Log.w(TAG, "Biometric forgot pin callback note: ${e.message}")
                                }
                            }
                        }
                    }
                    "verifyPin" -> {
                        val pin = call.argument<String>("pin") ?: ""
                        val saved = context.getSharedPreferences(NativeBridgeConstants.PREFS_NAME, Context.MODE_PRIVATE)
                            .getString(NativeBridgeConstants.KEY_PIN_HASH, "")
                            ?.takeIf { it.isNotEmpty() }
                            ?: context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                                .getString("flutter.pref_pin_hash", "")
                                ?.takeIf { it.isNotEmpty() }
                            ?: "123456"
                        result.success(pin.isNotEmpty() && pin == saved)
                    }
                    "isBiometricAvailable" -> {
                        result.success(BiometricPromptActivity.isBiometricAvailable(context))
                    }
                    else -> result.notImplemented()
                }
            }

        val closeHandler = io.flutter.plugin.common.MethodChannel.MethodCallHandler { call, result ->
            if (call.method == "closeOverlay") {
                dismissOverlay(context)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
        io.flutter.plugin.common.MethodChannel(messenger, "x-slayer/overlay_channel").setMethodCallHandler(closeHandler)
        io.flutter.plugin.common.MethodChannel(messenger, "x-slayer/overlay").setMethodCallHandler(closeHandler)
    }

    fun showLockOverlay(context: Context, targetPackage: String) {
        if (!Settings.canDrawOverlays(context)) {
            Log.w(TAG, "Cannot show overlay: SYSTEM_ALERT_WINDOW permission not granted")
            return
        }

        // Avoid re-triggering if already active for this package
        if (NativeLockManager.activeOverlayPackage == targetPackage && NativeLockManager.isOverlayVisible) {
            Log.d(TAG, "Overlay is already active for $targetPackage; ignoring duplicate show request.")
            return
        }

        NativeLockManager.activeOverlayPackage = targetPackage
        NativeLockManager.isOverlayVisible = true
        NativeLockManager.currentForegroundPackage = targetPackage
        Log.d(TAG, "Triggering lock overlay for package: $targetPackage")

        // CRITICAL: MUST execute all Flutter and WindowManager interactions on Android Main UI Thread
        Handler(Looper.getMainLooper()).post {
            try {
                // 1. Ensure the overlay Flutter engine exists before starting service
                ensureEngineInitialized(context)

                // 2. Synchronously persist target package & PIN to Flutter's SharedPreferences
                val prefsEdit = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit()
                prefsEdit.putString("flutter.current_locked_target_package", targetPackage)
                val currentPin = context.getSharedPreferences(NativeBridgeConstants.PREFS_NAME, Context.MODE_PRIVATE)
                    .getString(NativeBridgeConstants.KEY_PIN_HASH, null)
                if (currentPin != null && currentPin.isNotEmpty()) {
                    prefsEdit.putString("flutter.pref_pin_hash", currentPin)
                }
                prefsEdit.commit()

                // 3. Pre-configure WindowSetup properties via reflection for full screen & touch focus
                try {
                    val windowSetupClass = Class.forName("flutter.overlay.window.flutter_overlay_window.WindowSetup")
                    windowSetupClass.getDeclaredField("width").apply { isAccessible = true; set(null, -1999) }
                    windowSetupClass.getDeclaredField("height").apply { isAccessible = true; set(null, -1999) }
                    val isPrivacy = MainActivity.isRecentAppsPrivacyEnabled(context)
                    val overlayFlags = if (isPrivacy) {
                        android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                            android.view.WindowManager.LayoutParams.FLAG_SECURE
                    } else {
                        android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                    }
                    windowSetupClass.getDeclaredField("flag").apply {
                        isAccessible = true
                        set(null, overlayFlags)
                    }
                } catch (e: Throwable) {
                    Log.w(TAG, "WindowSetup reflection configuration note: ${e.message}")
                }

                // 4. Dispatch start intent to OverlayService
                val overlayServiceClass = Class.forName("flutter.overlay.window.flutter_overlay_window.OverlayService")
                val intent = Intent(context, overlayServiceClass).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("startX", 0)
                    putExtra("startY", 0)
                    putExtra(NativeBridgeConstants.EXTRA_TARGET_PACKAGE, targetPackage)
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(intent)
                    } else {
                        context.startService(intent)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start OverlayService: ${e.message}", e)
                }

                // 5. Send targetPackage to running Flutter engine if already active
                val cachedEngine = FlutterEngineCache.getInstance().get(CACHED_ENGINE_TAG)
                if (cachedEngine != null) {
                    registerChannels(cachedEngine, context.applicationContext)
                    val channel = BasicMessageChannel(
                        cachedEngine.dartExecutor.binaryMessenger,
                        MESSENGER_CHANNEL_TAG,
                        JSONMessageCodec.INSTANCE
                    )
                    channel.send(targetPackage)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to launch OverlayService: ${e.message}", e)
            }
        }
    }

    fun sendToOverlay(message: String) {
        Handler(Looper.getMainLooper()).post {
            try {
                val cachedEngine = FlutterEngineCache.getInstance().get(CACHED_ENGINE_TAG)
                if (cachedEngine != null) {
                    val channel = BasicMessageChannel(
                        cachedEngine.dartExecutor.binaryMessenger,
                        MESSENGER_CHANNEL_TAG,
                        JSONMessageCodec.INSTANCE
                    )
                    channel.send(message)
                }
            } catch (e: Exception) {
                Log.e(TAG, "sendToOverlay failed: ${e.message}", e)
            }
        }
    }

    fun dismissOverlay(context: Context) {
        NativeLockManager.activeOverlayPackage = null
        NativeLockManager.isOverlayVisible = false
        Handler(Looper.getMainLooper()).post {
            try {
                val overlayServiceClass = Class.forName("flutter.overlay.window.flutter_overlay_window.OverlayService")
                val instanceField = overlayServiceClass.getDeclaredField("instance").apply { isAccessible = true }
                val sInstance = instanceField.get(null)
                if (sInstance != null) {
                    val wmField = overlayServiceClass.getDeclaredField("windowManager").apply { isAccessible = true }
                    val fvField = overlayServiceClass.getDeclaredField("flutterView").apply { isAccessible = true }
                    val wm = wmField.get(sInstance) as? android.view.WindowManager
                    val fv = fvField.get(sInstance) as? android.view.View
                    if (wm != null && fv != null) {
                        try {
                            wm.removeView(fv)
                        } catch (e: Exception) {
                            Log.w(TAG, "wm.removeView: ${e.message}")
                        }
                        wmField.set(sInstance, null)
                    }
                    try {
                        val detachMethod = fv?.javaClass?.getMethod("detachFromFlutterEngine")
                        detachMethod?.invoke(fv)
                    } catch (_: Throwable) {}
                    try {
                        (sInstance as? android.app.Service)?.stopSelf()
                    } catch (_: Throwable) {}
                }

                val isRunningField = overlayServiceClass.getDeclaredField("isRunning").apply { isAccessible = true }
                isRunningField.setBoolean(null, false)
                Log.i(TAG, "Direct overlay window removal executed successfully")
            } catch (e: Exception) {
                Log.w(TAG, "Direct removal note: ${e.message}")
            }

            // Fallback intent
            try {
                val overlayServiceClass = Class.forName("flutter.overlay.window.flutter_overlay_window.OverlayService")
                val intent = Intent(context, overlayServiceClass).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    putExtra("IsCloseWindow", true)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (_: Throwable) {
                try {
                    val overlayServiceClass = Class.forName("flutter.overlay.window.flutter_overlay_window.OverlayService")
                    val intent = Intent(context, overlayServiceClass)
                    context.stopService(intent)
                } catch (_: Throwable) {}
            }
        }
    }
}
