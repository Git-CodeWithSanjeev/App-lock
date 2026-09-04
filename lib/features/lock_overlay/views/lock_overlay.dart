import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../authentication/views/lock_screen.dart';
import '../controllers/lock_overlay_controller.dart';

/// Thin overlay host view that coordinates target app lifecycle and
/// delegates all authentication UI to the single authoritative [LockScreen].
class LockOverlay extends StatefulWidget {
  const LockOverlay({super.key});

  @override
  State<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay> with WidgetsBindingObserver {
  late final LockOverlayController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.put(LockOverlayController());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final targetPkg = controller.targetPackage.value;
        return LockScreen(
          key: ValueKey(targetPkg),
          isSelfLock: false,
          targetPackage: targetPkg,
          appName: controller.appName.value,
          appIconBytes: controller.appIconBytes.value,
          onAuthenticated: controller.onUnlockSuccess,
          onDismiss: controller.onCancelAndGoHome,
        );
      }),
    );
  }
}

/// Backward compatibility alias
typedef LockOverlayScreen = LockOverlay;
