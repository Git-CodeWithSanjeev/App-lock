import 'package:get/get.dart';
import '../controllers/authentication_controller.dart';
import '../services/biometric_service.dart';

/// GetX binding injecting dependencies required for authentication.
class AuthenticationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BiometricService>(() => BiometricService());
    Get.lazyPut<AuthenticationController>(
      () => AuthenticationController(biometricService: Get.find<BiometricService>()),
    );
  }
}
