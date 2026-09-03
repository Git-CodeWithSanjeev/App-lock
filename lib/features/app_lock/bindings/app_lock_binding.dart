import 'package:get/get.dart';
import '../controllers/app_lock_controller.dart';
import '../services/app_lock_service.dart';

class AppLockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppLockService>(() => AppLockService());
    Get.lazyPut<AppLockController>(() => AppLockController());
  }
}
