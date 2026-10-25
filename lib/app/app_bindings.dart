import 'package:get/get.dart';
import '../features/app_lock/controllers/app_lock_controller.dart';
import '../features/applications/controllers/applications_controller.dart';
import '../features/authentication/controllers/authentication_controller.dart';
import '../features/settings/controllers/settings_controller.dart';

/// Global initial bindings for core application controllers.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthenticationController>(
      () => AuthenticationController(),
      fenix: true,
    );
    Get.lazyPut<AppLockController>(() => AppLockController(), fenix: true);
    Get.lazyPut<ApplicationsController>(
      () => ApplicationsController(),
      fenix: true,
    );
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
  }
}
