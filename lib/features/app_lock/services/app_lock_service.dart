import '../../../data/platform/app_lock_channel.dart';
import '../../../data/repositories/app_lock_repository.dart';

/// Service coordinating native background protection, service lifecycle,
/// and session unlock commands.
class AppLockService {
  final AppLockRepository _repo = AppLockRepository.instance;

  Future<void> startProtectionService() async {
    await AppLockChannel.startService();
    await _repo.refreshServiceStatus();
  }

  Future<void> stopProtectionService() async {
    await AppLockChannel.stopService();
    await _repo.refreshServiceStatus();
  }

  Future<void> unlockPackageSession(String packageName) async {
    if (packageName.isNotEmpty) {
      await AppLockChannel.unlockPackageSession(packageName);
    } else {
      await AppLockChannel.notifyOverlayClosed();
    }
  }

  Future<void> toggleAppLock(String packageName, bool lock) async {
    await _repo.toggleAppLock(packageName, lock);
  }

  Future<void> setMultipleAppLock(List<String> packages, bool lock) async {
    await _repo.setMultipleAppLock(packages, lock);
  }

  Future<void> syncSettings() async {
    await _repo.syncToNative();
  }

  Future<bool> isServiceRunning() async {
    await _repo.refreshServiceStatus();
    return _repo.isServiceRunning.value;
  }
}
