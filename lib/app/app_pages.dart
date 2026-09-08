import 'package:get/get.dart';
import '../features/applications/bindings/applications_binding.dart';
import '../features/authentication/bindings/authentication_binding.dart';
import '../features/authentication/views/authentication_gate.dart';
import '../features/authentication/views/create_pin_screen.dart';
import '../features/authentication/views/lock_screen.dart';
import '../features/lock_overlay/views/lock_overlay.dart';
import '../features/navigation/main_navigation.dart';
import '../features/onboarding/views/device_setup_screen.dart';
import '../features/onboarding/views/permissions_screen.dart';
import '../features/settings/bindings/settings_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.initial,
      page: () => const AuthenticationGate(),
      binding: AuthenticationBinding(),
    ),
    GetPage(
      name: AppRoutes.gate,
      page: () => const AuthenticationGate(),
      binding: AuthenticationBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainNavigation(),
      bindings: [
        ApplicationsBinding(),
        SettingsBinding(),
      ],
    ),
    GetPage(
      name: AppRoutes.createPin,
      page: () => const CreatePinScreen(isInitialSetup: true),
      binding: AuthenticationBinding(),
    ),
    GetPage(
      name: AppRoutes.lock,
      page: () => LockScreen(
        isSelfLock: true,
        onAuthenticated: () => Get.back(),
      ),
      binding: AuthenticationBinding(),
    ),
    GetPage(
      name: AppRoutes.overlay,
      page: () => const LockOverlay(),
    ),
    GetPage(
      name: AppRoutes.permissions,
      page: () => const PermissionsScreen(),
    ),
    GetPage(
      name: AppRoutes.deviceSetup,
      page: () => const DeviceSetupScreen(),
    ),
  ];
}
