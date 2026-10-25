package com.example.screen_lock

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.util.Log
import java.util.Collections
import java.util.HashSet

/**
 * Manages synchronous lock evaluation in native Android.
 *
 * This MUST run in native code because evaluating whether to block a newly launched
 * application must happen in under 1 millisecond. Routing this back-and-forth across
 * Flutter isolates would introduce a visible window flicker where the locked app's
 * private contents could be seen before the lock screen appears.
 */
object NativeLockManager {
    private const val TAG = "NativeLockManager"

    @Volatile
    var currentForegroundPackage: String? = null

    @Volatile
    var currentlyUnlockedForegroundPackage: String? = null

    @Volatile
    var isOverlayVisible: Boolean = false

    @Volatile
    var activeOverlayPackage: String? = null

    // Thread-safe in-memory cache of locked package names
    private val inMemoryLockedPackages: MutableSet<String> = Collections.synchronizedSet(HashSet())

    // Cache of unlocked packages and the timestamp when unlocked
    private val unlockedSessions = HashMap<String, Long>()

    // Cache of packages and the timestamp when the user moved away from them to background
    private val lastLeftTimes = HashMap<String, Long>()

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(NativeBridgeConstants.PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun isProtectionEnabled(context: Context): Boolean {
        return getPrefs(context).getBoolean(NativeBridgeConstants.KEY_PROTECTION_ENABLED, true)
    }

    fun setProtectionEnabled(context: Context, enabled: Boolean) {
        getPrefs(context).edit().putBoolean(NativeBridgeConstants.KEY_PROTECTION_ENABLED, enabled).apply()
    }

    fun getLockedPackages(context: Context): Set<String> {
        if (inMemoryLockedPackages.isNotEmpty()) {
            return inMemoryLockedPackages
        }
        val saved = getPrefs(context).getStringSet(NativeBridgeConstants.KEY_LOCKED_PACKAGES, emptySet()) ?: emptySet()
        inMemoryLockedPackages.addAll(saved)
        return inMemoryLockedPackages
    }

    fun setLockedPackages(context: Context, packages: Set<String>) {
        inMemoryLockedPackages.clear()
        inMemoryLockedPackages.addAll(packages)
        getPrefs(context).edit().putStringSet(NativeBridgeConstants.KEY_LOCKED_PACKAGES, packages).apply()
        Log.d(TAG, "Synchronized locked packages: $packages")
    }

    fun getRelockTimeoutMs(context: Context): Long {
        return getPrefs(context).getLong(NativeBridgeConstants.KEY_RELOCK_TIMEOUT_MS, 0L) // 0 = Immediately
    }

    fun setRelockTimeoutMs(context: Context, timeoutMs: Long) {
        getPrefs(context).edit().putLong(NativeBridgeConstants.KEY_RELOCK_TIMEOUT_MS, timeoutMs).apply()
    }

    fun isUninstallProtectionEnabled(context: Context): Boolean {
        return getPrefs(context).getBoolean(NativeBridgeConstants.KEY_UNINSTALL_PROTECTION, false)
    }

    fun setUninstallProtectionEnabled(context: Context, enabled: Boolean) {
        getPrefs(context).edit().putBoolean(NativeBridgeConstants.KEY_UNINSTALL_PROTECTION, enabled).apply()
        Log.d(TAG, "Uninstall protection set to: $enabled")
    }

    // Timestamp when user entered PIN to authorize uninstallation / app management
    @Volatile
    var uninstallAuthorizedTimestamp: Long = 0L

    fun isUninstallAuthorized(): Boolean {
        val elapsed = System.currentTimeMillis() - uninstallAuthorizedTimestamp
        return elapsed in 0..60000 // 60-second authorized window after entering correct PIN
    }

    fun markUninstallAuthorized() {
        uninstallAuthorizedTimestamp = System.currentTimeMillis()
        Log.i(TAG, "Uninstall flow authorized by user PIN")
    }

    /**
     * Detects if the foreground window represents an Android uninstallation or
     * App Details screen attempt targeting this application (com.example.screen_lock).
     */
    fun isUninstallOrAppDetailsAttempt(packageName: String?, className: String? = null): Boolean {
        if (packageName == null) return false
        val pkg = packageName.lowercase()
        val cls = className?.lowercase() ?: ""

        // Package installers (AOSP, Google, Samsung, Xiaomi)
        val isPackageInstaller = pkg == "com.android.packageinstaller" ||
            pkg == "com.google.android.packageinstaller" ||
            pkg == "com.samsung.android.packageinstaller" ||
            pkg == "com.sec.android.app.uninstaller" ||
            pkg.contains("packageinstaller") ||
            pkg.contains("uninstaller")

        if (isPackageInstaller) {
            return true
        }

        // System Settings App Details / Manage Applications screen
        val isSettingsAppDetails = pkg == "com.android.settings" && (
            cls.contains("installedappdetail") ||
            cls.contains("appdetail") ||
            cls.contains("manageapplication") ||
            cls.contains("uninstall")
        )

        return isSettingsAppDetails
    }

    /**
     * Checks if an event corresponds to the Android Recent Apps / Task Switcher window.
     */
    fun isRecentsWindow(packageName: String?, className: String? = null): Boolean {
        if (packageName == null && className == null) return false
        val cls = className?.lowercase() ?: ""
        val pkg = packageName?.lowercase() ?: ""
        return cls.contains("recents") ||
            cls.contains("overview") ||
            cls.contains("taskswitcher") ||
            cls.contains("quickstep") ||
            pkg.contains("recents")
    }

    /**
     * Checks if a package name belongs to a system dialog, status bar, keyboard,
     * or transient non-application window that must NEVER dismiss or bypass the lock overlay.
     */
    fun isSystemOrTransientPackage(packageName: String?, className: String? = null): Boolean {
        if (packageName == null || packageName.isEmpty()) return true
        // If it is the Recents task switcher, do NOT treat as transient; it represents user exiting foreground app
        if (isRecentsWindow(packageName, className)) {
            return false
        }
        if (packageName == "android" ||
            packageName == "com.android.systemui" ||
            packageName.contains("systemui") ||
            packageName == "com.google.android.inputmethod.latin" ||
            packageName.contains("inputmethod") ||
            packageName == "android.intent.action.MAIN"
        ) {
            return true
        }
        return false
    }

    /**
     * Checks if a package belongs to an Android Home Launcher.
     */
    fun isLauncherPackage(context: Context, packageName: String?): Boolean {
        if (packageName == null || packageName.isEmpty()) return false
        if (packageName == "com.sec.android.app.launcher" ||
            packageName == "com.google.android.apps.nexuslauncher" ||
            packageName == "com.android.launcher3" ||
            packageName == "com.miui.home" ||
            packageName == "com.oppo.launcher" ||
            packageName == "com.huawei.android.launcher" ||
            packageName.contains("launcher")
        ) {
            return true
        }
        try {
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            val resolveInfo = context.packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
            if (resolveInfo?.activityInfo?.packageName == packageName) {
                return true
            }
        } catch (_: Exception) {}
        return false
    }

    /**
     * Called whenever a foreground package transition is observed.
     * Manages re-lock logic when user navigates away from an unlocked app.
     */
    fun onForegroundPackageChanged(context: Context, newPackage: String, className: String? = null) {
        // Ignore transient system packages, notifications, keyboards, and internal intent actions
        if (isSystemOrTransientPackage(newPackage, className)) {
            Log.d(TAG, "Ignoring transient system package in foreground transition: $newPackage")
            return
        }

        val isRecents = isRecentsWindow(newPackage, className)
        val isLauncher = isLauncherPackage(context, newPackage)

        val activeUnlocked = currentlyUnlockedForegroundPackage
        if (activeUnlocked != null && (newPackage != activeUnlocked || isRecents || isLauncher)) {
            val timeoutMs = getRelockTimeoutMs(context)
            if (timeoutMs == 0L) {
                // Immediate re-lock policy (0ms): invalidate unlock session immediately
                unlockedSessions.remove(activeUnlocked)
                lastLeftTimes.remove(activeUnlocked)
                Log.d(TAG, "Relocking $activeUnlocked immediately upon foreground exit")
            } else {
                // Configured relock timeout (>0ms): record timestamp when app entered background
                lastLeftTimes[activeUnlocked] = System.currentTimeMillis()
                Log.d(TAG, "Recorded background exit for $activeUnlocked with relockTimeout=${timeoutMs}ms")
            }
            currentlyUnlockedForegroundPackage = null
        }

        // If user navigated away from the locked target app, handle overlay state cleanly
        val currentLocked = activeOverlayPackage
        if (currentLocked != null && (newPackage != currentLocked || isRecents || isLauncher) && newPackage != context.packageName) {
            val isDestinationLocked = getLockedPackages(context).contains(newPackage) && isProtectionEnabled(context)
            if (isDestinationLocked && !isRecents && !isLauncher) {
                // The new app is ALSO locked: transfer lock overlay seamlessly without exposing either app
                Log.d(TAG, "Transitioning between locked apps: $currentLocked -> $newPackage")
                activeOverlayPackage = newPackage
                OverlayController.showLockOverlay(context, newPackage)
            } else {
                // User navigated away (to Recents, Launcher, or unprotected app)
                Log.d(TAG, "User navigated away from locked app ($currentLocked -> $newPackage, isRecents=$isRecents). Dismissing overlay.")
                activeOverlayPackage = null
                isOverlayVisible = false
                OverlayController.dismissOverlay(context)
            }
        }

        if (!isRecents) {
            currentForegroundPackage = newPackage
        }
    }

    /**
     * Determines if a package should be blocked by the lock screen right now.
     */
    fun shouldLock(context: Context, packageName: String): Boolean {
        // Ignore self app to prevent locking our own UI
        if (packageName == context.packageName) return false

        // Never lock Recents or Launcher windows
        if (isRecentsWindow(packageName, null) || isLauncherPackage(context, packageName)) {
            return false
        }

        // Ignore transient system packages
        if (isSystemOrTransientPackage(packageName)) return false

        // If overlay is already actively visible for this package, do not re-trigger
        if ((activeOverlayPackage == packageName || currentForegroundPackage == packageName) && isOverlayVisible) {
            return false
        }

        // Ignore common system launcher, and document/file picker dialogs
        if (packageName == "com.android.documentsui" ||
            packageName == "com.google.android.documentsui"
        ) {
            return false
        }

        // Check if master protection toggle is ON
        if (!isProtectionEnabled(context)) return false

        // Check if this package is locked by user
        val lockedSet = getLockedPackages(context)
        if (!lockedSet.contains(packageName)) return false

        // If user is actively using the unlocked session right now
        if (currentlyUnlockedForegroundPackage == packageName) {
            return false
        }

        // Check timeout grace period
        val timeoutMs = getRelockTimeoutMs(context)
        if (unlockedSessions.containsKey(packageName)) {
            if (timeoutMs == 0L) {
                // Configured policy is immediate lock on background
                unlockedSessions.remove(packageName)
                lastLeftTimes.remove(packageName)
                return true
            }

            val leftTime = lastLeftTimes[packageName]
            if (leftTime == null) {
                // Package was unlocked and user never left it
                currentlyUnlockedForegroundPackage = packageName
                return false
            }

            val elapsed = System.currentTimeMillis() - leftTime
            if (elapsed < timeoutMs) {
                // Returned within configured timeout! Restore active session
                currentlyUnlockedForegroundPackage = packageName
                lastLeftTimes.remove(packageName)
                Log.d(TAG, "Restored unlocked session for $packageName (elapsed=${elapsed}ms < timeout=${timeoutMs}ms)")
                return false
            } else {
                // Timeout elapsed! Lock application
                unlockedSessions.remove(packageName)
                lastLeftTimes.remove(packageName)
                Log.d(TAG, "Relock timeout expired for $packageName (elapsed=${elapsed}ms >= timeout=${timeoutMs}ms)")
                return true
            }
        }

        return true
    }

    /**
     * Called when the user enters the correct PIN or passes biometric authentication.
     */
    fun markAppUnlocked(context: Context, packageName: String) {
        unlockedSessions[packageName] = System.currentTimeMillis()
        lastLeftTimes.remove(packageName)
        currentlyUnlockedForegroundPackage = packageName
        activeOverlayPackage = null
        isOverlayVisible = false
        Log.d(TAG, "Unlocked session recorded for package: $packageName")
    }

    /**
     * Resets unlock sessions (e.g. when screen turns off or locked app is backgrounded beyond timeout)
     */
    fun clearUnlockedSession(packageName: String) {
        unlockedSessions.remove(packageName)
        lastLeftTimes.remove(packageName)
        if (currentlyUnlockedForegroundPackage == packageName) {
            currentlyUnlockedForegroundPackage = null
        }
    }

    /**
     * Revokes all unlocked credentials immediately.
     * Note: Does NOT clear activeOverlayPackage or isOverlayVisible, ensuring any active
     * lock screen remains visible over the app even when the device turns off or sleeps.
     */
    fun clearAllUnlockedSessions() {
        unlockedSessions.clear()
        lastLeftTimes.clear()
        currentlyUnlockedForegroundPackage = null
    }
}
