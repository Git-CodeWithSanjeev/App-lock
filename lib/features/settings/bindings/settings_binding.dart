import 'package:get/get.dart';
import '../../privacy/services/recent_apps_privacy_service.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecentAppsPrivacyService>(() => RecentAppsPrivacyService());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
