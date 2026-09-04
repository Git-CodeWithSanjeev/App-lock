import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../data/platform/app_lock_channel.dart';
import '../../../data/repositories/app_lock_repository.dart';

/// Controller coordinating overlay window target app detection,
/// session unlock, and home cancellation.
class LockOverlayController extends GetxController {
  final RxString targetPackage = ''.obs;
  final RxString appName = 'Protected App'.obs;
  final Rx<Uint8List?> appIconBytes = Rx<Uint8List?>(null);

  StreamSubscription? _overlaySub;

  @override
  void onInit() {
    super.onInit();
    _loadInitialTargetAndListen();
  }

  @override
  void onClose() {
    _overlaySub?.cancel();
    super.onClose();
  }

  void onResumed() {
    loadInitialTarget();
  }

  Future<void> loadInitialTarget() async {
    try {
      await AppLockRepository.instance.init();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final cachedTarget =
          prefs.getString(StorageKeys.lastLockedPackage) ?? '';
      if (cachedTarget.isNotEmpty && cachedTarget != targetPackage.value) {
        updateTargetApp(cachedTarget);
      }
    } catch (_) {}
  }

  void _loadInitialTargetAndListen() async {
    await loadInitialTarget();

    _overlaySub = FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is String && data.isNotEmpty) {
        updateTargetApp(data);
      }
    });
  }

  Future<void> updateTargetApp(String packageName) async {
    if (packageName.isEmpty) return;
    targetPackage.value = packageName;

    try {
      final appInfo = await InstalledApps.getAppInfo(packageName);
      if (appInfo != null) {
        appName.value = appInfo.name;
        appIconBytes.value = appInfo.icon;
        return;
      }
    } catch (_) {}

    try {
      final repoApps = AppLockRepository.instance.installedApps.value;
      for (final app in repoApps) {
        if (app.packageName == packageName) {
          appName.value = app.name;
          appIconBytes.value = app.iconBytes;
          return;
        }
      }
    } catch (_) {}

    appName.value = _resolveFallbackAppName(packageName);
  }

  String _resolveFallbackAppName(String packageName) {
    if (packageName.contains('whatsapp')) return 'WhatsApp';
    if (packageName.contains('instagram')) return 'Instagram';
    if (packageName.contains('telegram')) return 'Telegram';
    if (packageName.contains('gallery') || packageName.contains('photos')) {
      return 'Photos';
    }
    if (packageName.contains('chrome')) return 'Chrome';
    if (packageName.contains('settings')) return 'Settings';

    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      final raw = parts.last;
      return raw[0].toUpperCase() + raw.substring(1);
    }
    return 'Protected App';
  }

  Future<void> onUnlockSuccess() async {
    final pkg = targetPackage.value;
    try {
      if (pkg.isNotEmpty) {
        await AppLockChannel.unlockPackageSession(pkg);
      } else {
        await AppLockChannel.notifyOverlayClosed();
      }
    } catch (e) {
      debugPrint('unlockPackageSession channel error: $e');
    }

    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('closeOverlay error: $e');
    }

    try {
      await AppLockChannel.notifyOverlayClosed();
    } catch (_) {}
  }

  Future<void> onCancelAndGoHome() async {
    try {
      await AppLockChannel.goHome();
    } catch (e) {
      debugPrint('goHome channel error: $e');
    }

    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}

    try {
      await AppLockChannel.notifyOverlayClosed();
    } catch (_) {}
  }
}
