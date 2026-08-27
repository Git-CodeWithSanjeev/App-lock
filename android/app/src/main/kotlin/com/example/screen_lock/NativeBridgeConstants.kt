package com.example.screen_lock

/**
 * Constants used across Native Android background services and platform channels.
 *
 * All foreground app monitoring and overlay window triggers run natively in Android
 * Kotlin code because Dart isolates cannot run persistently when the app is backgrounded,
 * especially under aggressive battery management such as Samsung One UI's "Sleeping Apps".
 */
object NativeBridgeConstants {
    // Platform Channel Identifiers
    const val SERVICE_CHANNEL = "com.example.screen_lock/service"
    const val SAMSUNG_CHANNEL = "com.example.screen_lock/samsung"

    // SharedPreferences for Synchronous Native Access
    const val PREFS_NAME = "app_lock_native_prefs"
    const val KEY_LOCKED_PACKAGES = "locked_packages"
    const val KEY_PROTECTION_ENABLED = "protection_enabled"
    const val KEY_RELOCK_TIMEOUT_MS = "relock_timeout_ms"
    const val KEY_LAST_UNLOCKED_PACKAGE = "last_unlocked_package"
    const val KEY_LAST_UNLOCKED_TIME = "last_unlocked_time"
    const val KEY_PIN_HASH = "pin_hash"
    const val KEY_BIOMETRIC_ENABLED = "biometric_enabled"
    const val KEY_UNINSTALL_PROTECTION = "uninstall_protection"

    // Foreground Service & Notification
    const val NOTIFICATION_CHANNEL_ID = "app_lock_foreground_channel"
    const val NOTIFICATION_ID = 10101

    // Actions & Intents
    const val ACTION_SHOW_OVERLAY = "com.example.screen_lock.SHOW_OVERLAY"
    const val EXTRA_TARGET_PACKAGE = "extra_target_package"
    const val EXTRA_APP_NAME = "extra_app_name"
}
