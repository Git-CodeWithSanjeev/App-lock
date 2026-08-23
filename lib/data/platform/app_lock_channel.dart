import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

/// Platform channel bridge interfacing Flutter with the native Android OS.
///
/// Every native call here encapsulates an Android OS mechanism that CANNOT
/// be implemented in pure Dart because Dart isolates lack OS-level privileges,
/// cannot query system services like UsageStatsManager or AppOpsManager directly,
/// and cannot survive persistent background execution under Android's aggressive
/// process reaper (especially Samsung One UI's "Sleeping Apps").
class AppLockChannel {
  static const MethodChannel _channel = MethodChannel(AppConstants.serviceChannel);

  /// Starts the native Android Foreground Service.
  static Future<bool> startService() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('startService');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Stops the native Android Foreground Service.
  static Future<bool> stopService() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('stopService');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks if either the native Foreground Service or the Accessibility Service is running.
  static Future<bool> isServiceRunning() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks whether PACKAGE_USAGE_STATS permission is granted in system AppOps.
  static Future<bool> hasUsageStatsPermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Launches the system Usage Access Settings screen.
  static Future<bool> requestUsageStatsPermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('requestUsageStatsPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks whether SYSTEM_ALERT_WINDOW (Draw over other apps) permission is granted.
  static Future<bool> hasOverlayPermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Launches the system Draw Over Other Apps permission settings screen for this app.
  static Future<bool> requestOverlayPermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks whether our custom Accessibility Service is enabled in system settings.
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Launches the Android Accessibility Settings screen.
  static Future<bool> requestAccessibilityPermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('requestAccessibilityPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Synchronizes the set of locked package names directly to native Android SharedPreferences.
  static Future<bool> syncLockedPackages(List<String> packages) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('syncLockedPackages', {
        'packages': packages,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Synchronizes security settings (master toggle and re-lock timeout) to native memory.
  static Future<bool> syncSettings({
    required bool protectionEnabled,
    required int relockTimeoutMs,
    bool uninstallProtection = false,
  }) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('syncSettings', {
        'protectionEnabled': protectionEnabled,
        'relockTimeoutMs': relockTimeoutMs,
        'uninstallProtection': uninstallProtection,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Sets whether best-effort uninstall protection is active.
  static Future<bool> setUninstallProtection(bool enabled) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('setUninstallProtection', {
        'enabled': enabled,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks whether best-effort uninstall protection is active.
  static Future<bool> getUninstallProtection() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('getUninstallProtection');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Marks a package as temporarily unlocked in native memory and dismisses the lock overlay.
  static Future<bool> unlockPackageSession(String packageName) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('unlockPackageSession', {
        'package': packageName,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks whether a given package is protected by Samsung Knox or Secure Folder.
  static Future<bool> isKnoxProtected(String packageName) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isKnoxProtected', {
        'package': packageName,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Triggers the lock overlay directly for testing and diagnostic verification.
  static Future<bool> testShowOverlay([String packageName = 'com.whatsapp']) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('testShowOverlay', {
        'package': packageName,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Synchronously writes user-configured PIN to native Android memory and preferences.
  static Future<bool> syncPin(String pin) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('syncPin', {
        'pin': pin,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Verifies PIN against native Android storage for cross-engine/cross-isolate consistency.
  static Future<bool> verifyPin(String pin) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('verifyPin', {
        'pin': pin,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Navigates the device safely to the Android Home launcher and dismisses the lock overlay.
  static Future<bool> goHome() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('goHome');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Notifies native manager that overlay window has closed.
  static Future<bool> notifyOverlayClosed() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('notifyOverlayClosed');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Triggers native Android BiometricPrompt (fingerprint) over the overlay window or activity.
  static Future<bool> triggerBiometricUnlock({
    required String packageName,
    required String appName,
  }) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('triggerBiometric', {
        'package': packageName,
        'appName': appName,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if physical biometric (fingerprint) hardware is available and enrolled.
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isBiometricAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers native Android BiometricPrompt with DEVICE_CREDENTIAL fallback
  static Future<bool> triggerForgotPinVerification({
    required String packageName,
    required String appName,
  }) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('triggerForgotPinVerification', {
        'package': packageName,
        'appName': appName,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Configures Android FLAG_SECURE and recents screenshot prevention.
  static Future<bool> setRecentAppsPrivacy(bool enabled) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('setRecentAppsPrivacy', {
        'enabled': enabled,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Alias for setRecentAppsPrivacy
  static Future<bool> setRecentAppsBlur(bool enabled) => setRecentAppsPrivacy(enabled);

  /// Alias for requestAccessibilityPermission
  static Future<bool> openAccessibilitySettings() => requestAccessibilityPermission();

  /// Checks if Recent Apps privacy is enabled natively.
  static Future<bool> isRecentAppsPrivacyEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isRecentAppsPrivacyEnabled');
      return result ?? true;
    } on PlatformException catch (_) {
      return true;
    }
  }
}
