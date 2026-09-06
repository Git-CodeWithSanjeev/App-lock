import 'package:get/get.dart';
import '../../../data/platform/app_lock_channel.dart';
import '../../../data/repositories/app_lock_repository.dart';
import '../../privacy/services/recent_apps_privacy_service.dart';

/// GetX Controller managing settings preferences and system permission states.
class SettingsController extends GetxController {
  static SettingsController get to => Get.find<SettingsController>();

  final AppLockRepository _repo = AppLockRepository.instance;
  final RecentAppsPrivacyService _privacyService = RecentAppsPrivacyService();

  // Reactive settings object mirrored from repo
  late final Rx<LockSettings> settings;

  // Reactive individual settings fields
  final RxBool biometricEnabled = true.obs;
  final RxInt relockTimeoutMs = 0.obs;
  final RxBool recentAppsPrivacy = true.obs;
  final RxBool uninstallProtection = false.obs;

  // Reactive permission states
  final RxBool hasUsageAccess = false.obs;
  final RxBool hasOverlay = false.obs;
  final RxBool isAccessibility = false.obs;
  final RxBool isServiceRunning = false.obs;

  @override
  void onInit() {
    super.onInit();
    settings = _repo.settings.value.obs;
    _syncFromRepo();
    checkPermissions();
  }

  void _syncFromRepo() {
    final s = _repo.settings.value;
    settings.value = s;
    biometricEnabled.value = s.biometricEnabled;
    relockTimeoutMs.value = s.relockTimeoutMs;
    recentAppsPrivacy.value = s.recentAppsPrivacy;
    uninstallProtection.value = s.uninstallProtection;

    _repo.settings.addListener(() {
      final s = _repo.settings.value;
      settings.value = s;
      if (biometricEnabled.value != s.biometricEnabled) {
        biometricEnabled.value = s.biometricEnabled;
      }
      if (relockTimeoutMs.value != s.relockTimeoutMs) {
        relockTimeoutMs.value = s.relockTimeoutMs;
      }
      if (recentAppsPrivacy.value != s.recentAppsPrivacy) {
        recentAppsPrivacy.value = s.recentAppsPrivacy;
      }
      if (uninstallProtection.value != s.uninstallProtection) {
        uninstallProtection.value = s.uninstallProtection;
      }
    });
  }

  /// Queries native Android permissions and background monitoring status.
  Future<void> checkPermissions() async {
    try {
      hasUsageAccess.value = await AppLockChannel.hasUsageStatsPermission();
    } catch (_) {}
    try {
      hasOverlay.value = await AppLockChannel.hasOverlayPermission();
    } catch (_) {}
    try {
      isAccessibility.value = await AppLockChannel.isAccessibilityEnabled();
    } catch (_) {}
    try {
      isServiceRunning.value = await AppLockChannel.isServiceRunning();
    } catch (_) {}
  }

  /// Opens native usage stats settings
  Future<void> requestUsageAccess() async {
    await AppLockChannel.requestUsageStatsPermission();
    await checkPermissions();
  }

  /// Opens native overlay permission settings
  Future<void> requestOverlay() async {
    await AppLockChannel.requestOverlayPermission();
    await checkPermissions();
  }

  /// Opens native accessibility settings
  Future<void> openAccessibilitySettings() async {
    await AppLockChannel.openAccessibilitySettings();
    await checkPermissions();
  }

  /// Updates biometric authentication preference.
  Future<void> updateBiometric(bool enabled) async {
    biometricEnabled.value = enabled;
    await _repo.updateBiometricEnabled(enabled);
  }

  /// Updates re-lock timeout duration.
  Future<void> updateRelockTimeout(int timeoutMs) async {
    relockTimeoutMs.value = timeoutMs;
    await _repo.updateRelockTimeout(timeoutMs);
  }

  /// Toggles Recent Apps Privacy (FLAG_SECURE + task preview hiding).
  Future<void> updateRecentAppsPrivacy(bool enabled) async {
    recentAppsPrivacy.value = enabled;
    await _privacyService.setRecentAppsPrivacy(enabled);
    await _repo.updateRecentAppsPrivacy(enabled);
  }

  /// Toggles best-effort uninstall protection.
  Future<void> updateUninstallProtection(bool enabled) async {
    uninstallProtection.value = enabled;
    await _repo.updateUninstallProtection(enabled);
  }
}
