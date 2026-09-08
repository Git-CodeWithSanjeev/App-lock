import 'package:get/get.dart';
import '../features/app_lock/controllers/app_lock_controller.dart';
import '../features/app_lock/services/app_lock_service.dart';
import '../features/applications/controllers/applications_controller.dart';
import '../features/authentication/controllers/authentication_controller.dart';
import '../features/authentication/services/biometric_service.dart';
import '../features/privacy/services/recent_apps_privacy_service.dart';
import '../features/settings/controllers/settings_controller.dart';

/// Global initial bindings for core application services and controllers.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BiometricService>(() => BiometricService(), fenix: true);
    Get.lazyPut<AppLockService>(() => AppLockService(), fenix: true);
    Get.lazyPut<RecentAppsPrivacyService>(() => RecentAppsPrivacyService(),
        fenix: true);

    Get.lazyPut<AuthenticationController>(() => AuthenticationController(),
        fenix: true);
    Get.lazyPut<AppLockController>(() => AppLockController(), fenix: true);
    Get.lazyPut<ApplicationsController>(() => ApplicationsController(),
        fenix: true);
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
  }
}
