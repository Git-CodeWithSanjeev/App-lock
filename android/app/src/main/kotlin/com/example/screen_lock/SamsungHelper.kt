package com.example.screen_lock

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * Helper class handling Samsung One UI specifics.
 *
 * One UI aggressively kills background services through "Sleeping Apps" and
 * "Deep Sleeping Apps". This helper detects Samsung hardware and navigates users
 * directly to Samsung-specific battery and background management settings.
 * It also protects against Knox/Secure Folder SecurityExceptions.
 */
object SamsungHelper {
    private const val TAG = "SamsungHelper"

    /**
     * Checks if the device manufacturer is Samsung.
     */
    fun isSamsungDevice(): Boolean {
        return Build.MANUFACTURER.equals("samsung", ignoreCase = true)
    }

    /**
     * Retrieves the Samsung One UI / SEP (Samsung Experience Platform) version if available.
     * Uses reflection on android.os.SystemProperties.
     */
    fun getOneUiVersion(): String? {
        if (!isSamsungDevice()) return null
        return try {
            val systemPropertiesClass = Class.forName("android.os.SystemProperties")
            val getMethod = systemPropertiesClass.getMethod("get", String::class.java)

            // One UI version integer property (e.g. 150100 for One UI 6.1)
            val oneUiVal = getMethod.invoke(null, "ro.build.version.oneui") as? String
            if (!oneUiVal.isNullOrBlank()) {
                val num = oneUiVal.toIntOrNull()
                if (num != null && num > 0) {
                    val major = num / 10000
                    val minor = (num % 10000) / 100
                    return "One UI $major.$minor"
                }
                return "One UI $oneUiVal"
            }

            // Fallback for earlier Samsung devices
            val sepVal = getMethod.invoke(null, "ro.build.version.sep") as? String
            if (!sepVal.isNullOrBlank()) {
                "SEP $sepVal"
            } else {
                "Samsung One UI"
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to retrieve One UI version: ${e.message}")
            "Samsung Device"
        }
    }

    /**
     * Verifies if battery optimization is already disabled (unrestricted) for this app.
     */
    fun isBatteryOptimizationIgnored(context: Context): Boolean {
        return try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            powerManager?.isIgnoringBatteryOptimizations(context.packageName) ?: false
        } catch (e: Exception) {
            Log.e(TAG, "Error checking battery optimization: ${e.message}")
            false
        }
    }

    /**
     * Attempts to open Samsung's Device Care / Battery management screen directly.
     * If the Samsung component isn't found, safely falls back to standard Android battery settings.
     */
    fun openSamsungBatterySettings(context: Context): Boolean {
        val samsungIntents = listOf(
            // Samsung Device Care Battery Activity
            Intent().setComponent(
                ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity")
            ),
            // Samsung Device Care Main Activity
            Intent().setComponent(
                ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity")
            ),
            // Smart Manager legacy Battery Activity
            Intent().setComponent(
                ComponentName("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity")
            ),
            // Samsung Device Care App List
            Intent().setComponent(
                ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.setting.DeepSleepingAppsActivity")
            )
        )

        for (intent in samsungIntents) {
            try {
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
                return true
            } catch (ignored: Exception) {
                // Try next intent
            }
        }

        // Standard Android Battery Optimization intent
        return try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            // Ultimate fallback to App Info Details
            openAppDetailsSettings(context)
        }
    }

    /**
     * Attempts to launch Samsung's Auto Run / Auto Start management screen.
     */
    fun openSamsungAutoRunSettings(context: Context): Boolean {
        val intents = listOf(
            Intent().setComponent(
                ComponentName("com.samsung.android.sm", "com.samsung.android.sm.app.dashboard.SmartManagerListener")
            ),
            Intent().setComponent(
                ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity")
            )
        )

        for (intent in intents) {
            try {
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
                return true
            } catch (ignored: Exception) {
            }
        }

        return openAppDetailsSettings(context)
    }

    /**
     * Safe fallback opening the App Details settings screen (where user can tap Battery > Unrestricted).
     */
    fun openAppDetailsSettings(context: Context): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open app details: ${e.message}")
            false
        }
    }

    /**
     * Gracefully checks if a package is a Knox-protected or Secure Folder application.
     * Prevents SecurityException crashes when querying package info across Samsung profiles.
     */
    fun isKnoxPackageSafe(context: Context, packageName: String): Boolean {
        if (packageName.startsWith("com.sec.knox.") ||
            packageName.startsWith("com.samsung.knox.") ||
            packageName.contains(".knox.") ||
            packageName.startsWith("sec_container_")
        ) {
            return true
        }

        return try {
            val pm = context.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            // Knox containers typically reside in secondary user profiles or have container flags
            false
        } catch (e: SecurityException) {
            // Knox / Secure Folder protected across profile boundaries
            Log.d(TAG, "Knox SecurityException caught safely for package $packageName")
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        } catch (e: Exception) {
            false
        }
    }
}
