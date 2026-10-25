import 'dart:ui';
import 'package:get/get.dart';
import '../../../data/platform/app_lock_channel.dart';
import '../../../data/repositories/app_lock_repository.dart';

/// GetX Controller managing master app-lock state, protected packages,
/// lock/unlock state, and background/recents re-lock lifecycle.
class AppLockController extends GetxController {
  static AppLockController get to => Get.find<AppLockController>();

  final AppLockRepository _repo = AppLockRepository.instance;

  final RxBool isProtectionEnabled = true.obs;
  final RxSet<String> lockedPackages = <String>{}.obs;
  final RxBool isSelfAuthenticated = false.obs;
  final RxBool isServiceRunning = false.obs;

  // Security and lifecycle timestamps
  DateTime? _lastPausedTime;

  @override
  void onInit() {
    super.onInit();
    _syncFromRepo();
  }

  void _syncFromRepo() {
    isProtectionEnabled.value = _repo.settings.value.protectionEnabled;
    lockedPackages.assignAll(_repo.lockedPackages.value);
    isServiceRunning.value = _repo.isServiceRunning.value;

    // Listen to repository ValueNotifiers for synchronization
    _repo.lockedPackages.addListener(() {
      if (lockedPackages.toSet() != _repo.lockedPackages.value) {
        lockedPackages.assignAll(_repo.lockedPackages.value);
      }
    });
    _repo.settings.addListener(() {
      if (isProtectionEnabled.value != _repo.settings.value.protectionEnabled) {
        isProtectionEnabled.value = _repo.settings.value.protectionEnabled;
      }
    });
    _repo.isServiceRunning.addListener(() {
      if (isServiceRunning.value != _repo.isServiceRunning.value) {
        isServiceRunning.value = _repo.isServiceRunning.value;
      }
    });
  }

  /// Toggles protection for an individual application package.
  Future<void> toggleAppLock(String packageName, bool lock) async {
    if (lock) {
      lockedPackages.add(packageName);
    } else {
      lockedPackages.remove(packageName);
    }
    await _repo.toggleAppLock(packageName, lock);
  }

  /// Locks or unlocks multiple packages simultaneously.
  Future<void> setMultipleAppLock(List<String> packages, bool lock) async {
    if (lock) {
      lockedPackages.addAll(packages);
    } else {
      lockedPackages.removeAll(packages);
    }
    await _repo.setMultipleAppLock(packages, lock);
  }

  /// Toggles master app-lock protection globally.
  Future<void> toggleMasterProtection(bool enabled) async {
    isProtectionEnabled.value = enabled;
    await _repo.toggleMasterProtection(enabled);
    await refreshServiceStatus();
  }

  /// Unlocks a protected third-party package for the active session.
  Future<void> unlockPackageSession(String packageName) async {
    if (packageName.isNotEmpty) {
      await AppLockChannel.unlockPackageSession(packageName);
    } else {
      await AppLockChannel.notifyOverlayClosed();
    }
  }

  /// Marks App Lock self-lock as authenticated.
  void authenticateSelf() {
    _lastPausedTime = null;
    isSelfAuthenticated.value = true;
  }

  /// Explicitly locks App Lock (forces authentication gate).
  void lockSelf() {
    isSelfAuthenticated.value = false;
  }

  void handleAppLifecycleState(AppLifecycleState state, int relockTimeoutMs) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (isSelfAuthenticated.value) {
        _lastPausedTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (isSelfAuthenticated.value && _lastPausedTime != null) {
        final elapsed = DateTime.now()
            .difference(_lastPausedTime!)
            .inMilliseconds;

        if (relockTimeoutMs == 0 || elapsed >= relockTimeoutMs) {
          isSelfAuthenticated.value = false;
        }
      }
      _lastPausedTime = null;
    }
  }

  /// Checks and updates native background service running state.
  Future<void> refreshServiceStatus() async {
    await _repo.refreshServiceStatus();
    isServiceRunning.value = _repo.isServiceRunning.value;
  }
}
