import 'package:get/get.dart';
import '../controllers/applications_controller.dart';

class ApplicationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApplicationsController>(() => ApplicationsController());
  }
}
