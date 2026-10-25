import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/application_info.dart';
import '../models/lock_settings.dart';
import '../platform/app_lock_channel.dart';

export '../models/application_info.dart';
export '../models/lock_settings.dart';

/// Central repository managing app lock state, local preferences, and installed apps.
///
/// Uses lightweight ValueNotifiers instead of heavy state management frameworks
/// (such as flutter_bloc), ensuring fluid UI performance and minimal APK size.
class AppLockRepository {
  static final AppLockRepository instance = AppLockRepository._internal();
  AppLockRepository._internal();

  SharedPreferences? _prefs;

  final ValueNotifier<Set<String>> lockedPackages = ValueNotifier<Set<String>>(
    {},
  );
  final ValueNotifier<LockSettings> settings = ValueNotifier<LockSettings>(
    const LockSettings(),
  );
  final ValueNotifier<List<AppInfoItem>> installedApps =
      ValueNotifier<List<AppInfoItem>>([]);
  final ValueNotifier<bool> isServiceRunning = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingApps = ValueNotifier<bool>(false);

  // Security stats displayed on Home dashboard
  final ValueNotifier<int> blockedAttempts = ValueNotifier<int>(3);
  final ValueNotifier<String> lastUnlockText = ValueNotifier<String>('2m');

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs?.reload();

    final savedList =
        _prefs?.getStringList(AppConstants.keyLockedPackages) ?? [];
    lockedPackages.value = savedList.toSet();

    final protection =
        _prefs?.getBool(AppConstants.keyProtectionEnabled) ?? true;
    final biometric = _prefs?.getBool(AppConstants.keyBiometricEnabled) ?? true;
    final timeout = _prefs?.getInt(AppConstants.keyRelockTimeoutMs) ?? 0;
    final pin =
        _prefs?.getString(AppConstants.keyPinHash) ?? AppConstants.defaultPin;
    final privacy = _prefs?.getBool(AppConstants.keyRecentAppsPrivacy) ?? true;
    final uninstallProt =
        _prefs?.getBool(AppConstants.keyUninstallProtection) ?? false;

    settings.value = LockSettings(
      protectionEnabled: protection,
      biometricEnabled: biometric,
      relockTimeoutMs: timeout,
      pinHash: pin,
      recentAppsPrivacy: privacy,
      uninstallProtection: uninstallProt,
    );

    await syncToNative();

    if (protection) {
      await AppLockChannel.startService();
    }

    await refreshServiceStatus();
  }

  /// Synchronizes current settings and package sets to native Kotlin memory.
  Future<void> syncToNative() async {
    await AppLockChannel.syncLockedPackages(lockedPackages.value.toList());
    await AppLockChannel.syncSettings(
      protectionEnabled: settings.value.protectionEnabled,
      relockTimeoutMs: settings.value.relockTimeoutMs,
      uninstallProtection: settings.value.uninstallProtection,
    );
    await AppLockChannel.syncPin(settings.value.pinHash);
    await AppLockChannel.setRecentAppsPrivacy(settings.value.recentAppsPrivacy);
  }

  Future<void> refreshServiceStatus() async {
    final running = await AppLockChannel.isServiceRunning();
    isServiceRunning.value = running;
  }

  /// Toggles master protection ON or OFF.
  Future<void> toggleMasterProtection(bool enabled) async {
    final updated = settings.value.copyWith(protectionEnabled: enabled);
    settings.value = updated;
    await _prefs?.setBool(AppConstants.keyProtectionEnabled, enabled);

    if (enabled) {
      await AppLockChannel.startService();
    } else {
      await AppLockChannel.stopService();
    }

    await syncToNative();
    await refreshServiceStatus();
  }

  /// Toggles lock status for a specific app package.
  Future<void> toggleAppLock(String packageName, bool lock) async {
    final current = Set<String>.from(lockedPackages.value);
    if (lock) {
      current.add(packageName);
    } else {
      current.remove(packageName);
    }
    lockedPackages.value = current;

    await _prefs?.setStringList(
      AppConstants.keyLockedPackages,
      current.toList(),
    );
    await AppLockChannel.syncLockedPackages(current.toList());

    if (lock && settings.value.protectionEnabled) {
      await AppLockChannel.startService();
      await refreshServiceStatus();
    }

    // Update in-memory installed apps list
    final apps = List<AppInfoItem>.from(installedApps.value);
    final idx = apps.indexWhere((a) => a.packageName == packageName);
    if (idx != -1) {
      apps[idx] = apps[idx].copyWith(isLocked: lock);
      installedApps.value = apps;
    }
  }

  /// Locks or unlocks multiple packages at once.
  Future<void> setMultipleAppLock(List<String> packageNames, bool lock) async {
    final current = Set<String>.from(lockedPackages.value);
    if (lock) {
      current.addAll(packageNames);
    } else {
      current.removeAll(packageNames);
    }
    lockedPackages.value = current;

    await _prefs?.setStringList(
      AppConstants.keyLockedPackages,
      current.toList(),
    );
    await AppLockChannel.syncLockedPackages(current.toList());

    // Update in-memory installed apps list
    final apps = List<AppInfoItem>.from(installedApps.value);
    for (int i = 0; i < apps.length; i++) {
      if (packageNames.contains(apps[i].packageName)) {
        apps[i] = apps[i].copyWith(isLocked: lock);
      }
    }
    installedApps.value = apps;
  }

  /// Updates re-lock timeout setting.
  Future<void> updateRelockTimeout(int timeoutMs) async {
    settings.value = settings.value.copyWith(relockTimeoutMs: timeoutMs);
    await _prefs?.setInt(AppConstants.keyRelockTimeoutMs, timeoutMs);
    await syncToNative();
  }

  /// Toggles biometric unlock setting.
  Future<void> updateBiometricEnabled(bool enabled) async {
    settings.value = settings.value.copyWith(biometricEnabled: enabled);
    await _prefs?.setBool(AppConstants.keyBiometricEnabled, enabled);
  }

  /// Toggles Recent Apps privacy (FLAG_SECURE + task preview prevention).
  Future<void> updateRecentAppsPrivacy(bool enabled) async {
    settings.value = settings.value.copyWith(recentAppsPrivacy: enabled);
    await _prefs?.setBool(AppConstants.keyRecentAppsPrivacy, enabled);
    await AppLockChannel.setRecentAppsPrivacy(enabled);
  }

  /// Toggles best-effort uninstall protection.
  Future<void> updateUninstallProtection(bool enabled) async {
    settings.value = settings.value.copyWith(uninstallProtection: enabled);
    await _prefs?.setBool(AppConstants.keyUninstallProtection, enabled);
    await AppLockChannel.setUninstallProtection(enabled);
    await syncToNative();
  }

  /// Updates security PIN and immediately synchronizes to native Android memory.
  Future<void> updatePin(String newPin) async {
    settings.value = settings.value.copyWith(pinHash: newPin);
    await _prefs?.setString(AppConstants.keyPinHash, newPin);
    await AppLockChannel.syncPin(newPin);
    await setHasSetPin(true);
  }

  bool hasSetPin() {
    return _prefs?.getBool(AppConstants.keyHasSetPin) ?? false;
  }

  Future<void> setHasSetPin(bool value) async {
    await _prefs?.setBool(AppConstants.keyHasSetPin, value);
  }

  /// Checks if an entered PIN is correct.
  bool verifyPin(String inputPin) {
    if (inputPin == settings.value.pinHash) {
      return true;
    }
    final diskPin = _prefs?.getString(AppConstants.keyPinHash);
    if (diskPin != null && diskPin.isNotEmpty && inputPin == diskPin) {
      settings.value = settings.value.copyWith(pinHash: diskPin);
      return true;
    }
    return false;
  }

  /// Loads all installed apps with icons, filtering out self package and handling Knox apps.
  Future<void> loadInstalledApplications() async {
    isLoadingApps.value = true;
    try {
      final List<AppInfo> rawApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: true,
      );

      final currentLocked = lockedPackages.value;
      final List<AppInfoItem> items = [];

      for (final app in rawApps) {
        final pkg = app.packageName.trim();
        final name = app.name.trim();
        if (pkg.isEmpty || name.isEmpty) continue;
        if (pkg == 'com.example.screen_lock') continue;

        // Skip internal low-level android system daemons without user UI
        if (pkg == 'android' ||
            pkg == 'com.android.systemui' ||
            pkg.startsWith('com.android.providers.') ||
            pkg.startsWith('com.android.cts.') ||
            name.toLowerCase() == 'android system') {
          continue;
        }

        // Instant Knox / Secure Folder detection without serial channel lag
        final isKnox =
            pkg.startsWith('com.sec.knox.') ||
            pkg.startsWith('com.samsung.knox.') ||
            pkg.contains('.knox.') ||
            pkg.startsWith('sec_container_');

        items.add(
          AppInfoItem(
            name: name,
            packageName: pkg,
            iconBytes: app.icon,
            versionName: app.versionName,
            isSystemApp: false,
            isKnoxProtected: isKnox,
            isLocked: currentLocked.contains(pkg),
          ),
        );
      }

      // Sort alphabetically with locked apps first
      items.sort((a, b) {
        if (a.isLocked != b.isLocked) {
          return a.isLocked ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      installedApps.value = items;
    } catch (e) {
      debugPrint('Error loading installed apps: $e');
    } finally {
      isLoadingApps.value = false;
    }
  }

  // Onboarding status helpers
  bool hasSeenSamsungGuide() {
    return _prefs?.getBool(AppConstants.keyHasSeenSamsungGuide) ?? false;
  }

  Future<void> setSeenSamsungGuide(bool seen) async {
    await _prefs?.setBool(AppConstants.keyHasSeenSamsungGuide, seen);
  }

  bool hasCompletedPermissions() {
    return _prefs?.getBool(AppConstants.keyHasCompletedPermissions) ?? false;
  }

  Future<void> setCompletedPermissions(bool completed) async {
    await _prefs?.setBool(AppConstants.keyHasCompletedPermissions, completed);
  }
}
