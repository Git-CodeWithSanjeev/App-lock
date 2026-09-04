import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_lock_switch.dart';
import '../../../data/repositories/app_lock_repository.dart';
import '../../app_lock/controllers/app_lock_controller.dart';
import '../../authentication/views/create_pin_screen.dart';
import '../controllers/applications_controller.dart';
import '../models/application_filter.dart';
import 'widgets/application_filter_bar.dart';
import 'widgets/application_search.dart';
import 'widgets/application_tile.dart';

/// Minimal Samsung One UI–inspired primary screen ("Apps" Tab).
/// Flow: Select App -> Enable Lock -> Authenticate with PIN/Biometric -> Unlock.
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  late final ApplicationsController _appsCtrl;
  late final AppLockController _lockCtrl;

  @override
  void initState() {
    super.initState();
    _appsCtrl = Get.find<ApplicationsController>();
    _lockCtrl = Get.isRegistered<AppLockController>()
        ? Get.find<AppLockController>()
        : Get.put(AppLockController());

    _searchController.addListener(() {
      _appsCtrl.setSearchQuery(_searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleToggle(ApplicationInfo app, bool lock) async {
    final repo = AppLockRepository.instance;

    // If enabling lock and PIN is not yet set, guide user to create PIN first
    if (lock && !repo.hasSetPin()) {
      final pinCreated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const CreatePinScreen(isInitialSetup: false),
        ),
      );

      if (pinCreated == true || repo.hasSetPin()) {
        await _lockCtrl.toggleAppLock(app.packageName, true);
      }
      return;
    }

    await _lockCtrl.toggleAppLock(app.packageName, lock);
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppLockRepository.instance;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            await _appsCtrl.reloadApps();
          },
          child: Obx(() {
            final apps = _appsCtrl.installedApps;
            final lockedPackages = _appsCtrl.lockedPackages;
            final isProtectionActive = _lockCtrl.isProtectionEnabled.value;
            final isLoading = _appsCtrl.isLoading.value;
            final hasPin = repo.hasSetPin();
            final currentFilter = _appsCtrl.currentFilter.value;

            final filteredApps = _appsCtrl.filteredApps;
            final lockedCount =
                apps.where((a) => lockedPackages.contains(a.packageName)).length;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppTheme.blueBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'App Lock',
                                style: GoogleFonts.manrope(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isProtectionActive
                                    ? AppTheme.blueBg
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isProtectionActive
                                          ? AppTheme.primary
                                          : AppTheme.warningAmber,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isProtectionActive ? 'Active' : 'Paused',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isProtectionActive
                                          ? AppTheme.primary
                                          : AppTheme.warningAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          decoration:
                              AppTheme.cardDecoration(borderRadius: 24),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isProtectionActive
                                      ? AppTheme.blueBg
                                      : AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isProtectionActive
                                      ? Icons.lock_rounded
                                      : Icons.lock_open_rounded,
                                  color: isProtectionActive
                                      ? AppTheme.primary
                                      : AppTheme.mutedSteel,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isProtectionActive
                                          ? 'App Protection'
                                          : 'Protection Paused',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isProtectionActive
                                          ? '$lockedCount of ${apps.length} apps locked'
                                          : 'Apps will not prompt for authentication',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12.5,
                                        color: AppTheme.mutedSteel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppLockSwitch(
                                value: isProtectionActive,
                                onChanged: (val) =>
                                    _lockCtrl.toggleMasterProtection(val),
                              ),
                            ],
                          ),
                        ),

                        if (!hasPin) ...[
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreatePinScreen(
                                      isInitialSetup: false),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.vpn_key_rounded,
                                      color: Color(0xFFD97706),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Create Master PIN',
                                          style: GoogleFonts.manrope(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF92400E),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Set up your 6-digit PIN to secure your locked apps.',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: const Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFFD97706),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        ApplicationSearch(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {});
                          },
                          onClear: () {
                            _searchController.clear();
                            _appsCtrl.setSearchQuery('');
                            setState(() {});
                          },
                        ),

                        const SizedBox(height: 12),

                        ApplicationFilterBar(
                          currentFilter: currentFilter,
                          allCount: apps.length,
                          lockedCount: lockedCount,
                          onFilterChanged: (newFilter) {
                            _appsCtrl.setFilter(newFilter);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                if (filteredApps.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                isLoading
                                    ? Icons.hourglass_top_rounded
                                    : (currentFilter == ApplicationFilter.locked
                                        ? Icons.lock_open_rounded
                                        : Icons.search_off_rounded),
                                color: AppTheme.mutedSteel,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isLoading
                                  ? 'Scanning applications...'
                                  : (currentFilter == ApplicationFilter.locked
                                      ? 'No locked applications'
                                      : (apps.isEmpty
                                          ? 'No applications loaded'
                                          : 'No matching applications')),
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isLoading
                                  ? 'Please wait while installed apps are detected.'
                                  : (currentFilter == ApplicationFilter.locked
                                      ? 'Toggle the switch beside any app to lock it.'
                                      : (apps.isEmpty
                                          ? 'Pull down to refresh installed applications.'
                                          : 'Check your search query or clear the filter.')),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppTheme.mutedSteel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final app = filteredApps[index];
                          final isLocked =
                              lockedPackages.contains(app.packageName);
                          final displayApp = app.isLocked == isLocked
                              ? app
                              : app.copyWith(isLocked: isLocked);

                          return ApplicationTile(
                            key: ValueKey(app.packageName),
                            app: displayApp,
                            onToggle: (bool val) =>
                                _handleToggle(app, val),
                          );
                        },
                        childCount: filteredApps.length,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef HomeScreen = ApplicationsScreen;
