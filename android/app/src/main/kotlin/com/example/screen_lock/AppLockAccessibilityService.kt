package com.example.screen_lock

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Native Accessibility Service.
 *
 * Provides near-instant (0ms) foreground window transition detection via
 * AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED. This acts as the primary instant-detection
 * mechanism, intercepting locked applications before their windows finish rendering.
 */
class AppLockAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppLockAccessibility"
        @Volatile
        var isServiceRunning = false

        /**
         * Checks whether the user has enabled this Accessibility Service in system settings.
         */
        fun isEnabled(context: Context): Boolean {
            val expectedServiceName = "${context.packageName}/${AppLockAccessibilityService::class.java.canonicalName}"
            val enabledServices = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServices)

            while (colonSplitter.hasNext()) {
                val componentName = colonSplitter.next()
                if (componentName.equals(expectedServiceName, ignoreCase = true)) {
                    return true
                }
            }
            return false
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        Log.i(TAG, "AppLockAccessibilityService connected and actively listening for window state changes")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            val className = event.className?.toString() ?: ""

            // 1. Check Uninstall Protection before ignoring transient/system packages
            if (NativeLockManager.isUninstallProtectionEnabled(applicationContext) &&
                NativeLockManager.isUninstallOrAppDetailsAttempt(packageName, className)
            ) {
                if (!NativeLockManager.isUninstallAuthorized()) {
                    Log.d(TAG, "Intercepted uninstall / app details attempt: $packageName / $className")
                    OverlayController.showLockOverlay(applicationContext, applicationContext.packageName)
                    return
                }
            }

            // Ignore system dialogs, keyboards, volume, toasts, and transient system windows
            if (NativeLockManager.isSystemOrTransientPackage(packageName, className) ||
                className.contains("InputMethod") ||
                className.contains("VolumeDialog") ||
                className.contains("Toast")
            ) {
                return
            }

            NativeLockManager.onForegroundPackageChanged(applicationContext, packageName, className)

            // Evaluate lock status synchronously in native memory
            if (NativeLockManager.shouldLock(applicationContext, packageName)) {
                Log.d(TAG, "Instant lock triggered via Accessibility for: $packageName")
                OverlayController.showLockOverlay(applicationContext, packageName)
            }
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "AppLockAccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        Log.i(TAG, "AppLockAccessibilityService destroyed")
    }
}
