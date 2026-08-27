package com.example.screen_lock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Boot Receiver.
 *
 * Restarts the AppLockForegroundService upon device restart so that protected
 * apps remain secured immediately without requiring the user to manually reopen
 * the app lock manager.
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val action = intent.action
        Log.i(TAG, "Received broadcast action: $action")

        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            if (NativeLockManager.isProtectionEnabled(context)) {
                Log.i(TAG, "Auto-starting AppLockForegroundService after device reboot")
                AppLockForegroundService.start(context)
            }
        }
    }
}
