import 'storage_keys.dart';

/// Application-wide constants for channel names, preferences keys, and timeouts.
class AppConstants {
  // MethodChannel Names
  static const String serviceChannel = 'com.example.screen_lock/service';
  static const String samsungChannel = 'com.example.screen_lock/samsung';

  // SharedPreferences Keys (mapped directly to StorageKeys)
  static const String keyPinHash = StorageKeys.pinHash;
  static const String keyHasSetPin = StorageKeys.hasSetPin;
  static const String keyBiometricEnabled = StorageKeys.biometricEnabled;
  static const String keyProtectionEnabled = StorageKeys.protectionEnabled;
  static const String keyLockedPackages = StorageKeys.lockedPackages;
  static const String keyRelockTimeoutMs = StorageKeys.relockTimeoutMs;
  static const String keyHasSeenSamsungGuide = StorageKeys.hasSeenSamsungGuide;
  static const String keyHasCompletedPermissions = StorageKeys.hasCompletedPermissions;
  static const String keyLastLockedPackage = StorageKeys.lastLockedPackage;
  static const String keyRecentAppsPrivacy = StorageKeys.recentAppsPrivacy;
  static const String keyUninstallProtection = StorageKeys.uninstallProtection;

  // Default PIN for fresh installation (6-digit master PIN)
  static const String defaultPin = '123456';

  static const Map<String, int> timeoutOptions = {
    'Immediately': 0,
    'After 30 seconds': 30 * 1000,
    'After 1 minute': 60 * 1000,
    'After 5 minutes': 5 * 60 * 1000,
    'After 15 minutes': 15 * 60 * 1000,
  };
}
