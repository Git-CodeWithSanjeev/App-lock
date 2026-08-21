/// Keys used for SharedPreferences persistence across the application.
class StorageKeys {
  static const String pinHash = 'pref_pin_hash';
  static const String hasSetPin = 'pref_has_set_pin';
  static const String biometricEnabled = 'pref_biometric_enabled';
  static const String protectionEnabled = 'pref_protection_enabled';
  static const String lockedPackages = 'pref_locked_packages';
  static const String relockTimeoutMs = 'pref_relock_timeout_ms';
  static const String hasSeenSamsungGuide = 'pref_has_seen_samsung_guide';
  static const String hasCompletedPermissions = 'pref_has_completed_permissions';
  static const String lastLockedPackage = 'current_locked_target_package';
  static const String recentAppsPrivacy = 'pref_recent_apps_privacy';
  static const String uninstallProtection = 'pref_uninstall_protection';
}
