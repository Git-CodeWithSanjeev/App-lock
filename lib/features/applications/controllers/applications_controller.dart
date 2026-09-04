import 'package:get/get.dart';
import '../../../data/repositories/app_lock_repository.dart';
import '../models/application_filter.dart';

/// GetX Controller managing installed applications list, search,
/// category/filter state, and app loading state.
class ApplicationsController extends GetxController {
  static ApplicationsController get to => Get.find<ApplicationsController>();

  final AppLockRepository _repo = AppLockRepository.instance;

  final RxList<ApplicationInfo> installedApps = <ApplicationInfo>[].obs;
  final RxString searchQuery = ''.obs;
  final Rx<ApplicationFilter> currentFilter = ApplicationFilter.all.obs;
  final RxBool isLoadingApps = false.obs;

  RxBool get isLoading => isLoadingApps;

  /// Reactive locked packages set, synced from repository
  final RxSet<String> _lockedPackages = <String>{}.obs;
  Set<String> get lockedPackages => _lockedPackages;

  @override
  void onInit() {
    super.onInit();
    _syncFromRepo();
    if (installedApps.isEmpty) {
      loadApps();
    }
  }

  /// Syncs initial state from repository and subscribes to listeners
  void _syncFromRepo() {
    installedApps.assignAll(_repo.installedApps.value);
    isLoadingApps.value = _repo.isLoadingApps.value;
    _lockedPackages.assignAll(_repo.lockedPackages.value);

    _repo.installedApps.addListener(() {
      installedApps.assignAll(_repo.installedApps.value);
    });
    _repo.isLoadingApps.addListener(() {
      isLoadingApps.value = _repo.isLoadingApps.value;
    });
    _repo.lockedPackages.addListener(() {
      _lockedPackages.assignAll(_repo.lockedPackages.value);
    });
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setFilter(ApplicationFilter filter) {
    currentFilter.value = filter;
  }

  /// Filtered list of applications matching search query and active filter
  List<ApplicationInfo> get filteredApps {
    final query = searchQuery.value.trim().toLowerCase();
    return installedApps.where((app) {
      if (currentFilter.value == ApplicationFilter.locked) {
        if (!_lockedPackages.contains(app.packageName)) return false;
      }
      if (query.isNotEmpty) {
        final matchesName = app.name.toLowerCase().contains(query);
        final matchesPackage = app.packageName.toLowerCase().contains(query);
        return matchesName || matchesPackage;
      }
      return true;
    }).toList();
  }

  /// Loads installed applications and refreshes native service status.
  Future<void> loadApps() async {
    isLoadingApps.value = true;
    try {
      await _repo.loadInstalledApplications();
    } catch (_) {}
    try {
      await _repo.refreshServiceStatus();
    } catch (_) {}
    installedApps.assignAll(_repo.installedApps.value);
    _lockedPackages.assignAll(_repo.lockedPackages.value);
    isLoadingApps.value = false;
  }

  /// Pull-to-refresh trigger
  Future<void> reloadApps() => loadApps();
}

/// Backward compatibility alias
typedef AppListController = ApplicationsController;
