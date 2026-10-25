import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/platform/app_lock_channel.dart';
import '../../../data/repositories/app_lock_repository.dart';
import '../../navigation/main_navigation.dart';
import '../controllers/authentication_controller.dart';
import 'lock_screen.dart';

/// One UI–inspired Authentication Gate protecting the App Lock application.
///
/// Ensures App Lock requires Master PIN or biometric authentication before
/// allowing access to protected app configurations and settings.
/// Strictly enforces re-lock behavior upon returning from background/recents.
class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({super.key});

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate>
    with WidgetsBindingObserver {
  late final AuthenticationController _authCtrl;

  @override
  void initState() {
    super.initState();
    _authCtrl = Get.find<AuthenticationController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final relockTimeoutMs =
        AppLockRepository.instance.settings.value.relockTimeoutMs;
    _authCtrl.handleAppLifecycleState(state, relockTimeoutMs);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_authCtrl.isSelfAuthenticated.value) {
        return const MainNavigation();
      }

      return Scaffold(
        body: LockScreen(
          isSelfLock: true,
          targetPackage: 'com.example.screen_lock',
          appName: 'App Lock',
          onAuthenticated: () {
            _authCtrl.authenticateSelf();
          },
          onDismiss: () {
            AppLockChannel.goHome();
          },
        ),
      );
    });
  }
}

/// Backward compatibility alias
typedef AppAuthGateScreen = AuthenticationGate;
