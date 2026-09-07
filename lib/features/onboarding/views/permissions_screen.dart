import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/platform/app_lock_channel.dart';
import '../../../data/repositories/app_lock_repository.dart';

/// Pre-permission rationale checklist screen designed in the Porcelain Guardian style.
///
/// Android requires special system settings permissions (Usage Access, Display Overlay,
/// and Accessibility) that cannot be granted via standard runtime dialogs.
/// This screen provides clear rationales for each permission before sending the user to settings.
class PermissionsScreen extends StatefulWidget {
  final bool isModal;
  const PermissionsScreen({super.key, this.isModal = false});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _hasUsageStats = false;
  bool _hasOverlay = false;
  bool _hasAccessibility = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    final usage = await AppLockChannel.hasUsageStatsPermission();
    final overlay = await AppLockChannel.hasOverlayPermission();
    final accessibility = await AppLockChannel.isAccessibilityEnabled();

    if (mounted) {
      setState(() {
        _hasUsageStats = usage;
        _hasOverlay = overlay;
        _hasAccessibility = accessibility;
        _isChecking = false;
      });
    }
  }

  bool get _allRequiredGranted => _hasUsageStats && _hasOverlay;

  Future<void> _onProceed() async {
    await AppLockRepository.instance.setCompletedPermissions(true);

    await AppLockChannel.startService();
    await AppLockRepository.instance.refreshServiceStatus();

    if (!mounted) return;

    if (widget.isModal) {
      Navigator.pop(context);
      return;
    }

    final hasPin = AppLockRepository.instance.hasSetPin();

    if (!hasPin && mounted) {
      Get.offNamed('/create-pin');
    } else if (mounted) {
      Get.offNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'System Permissions',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        automaticallyImplyLeading: widget.isModal,
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: _isChecking
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required Safeguards',
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'To protect applications and draw the secure lock screen before private contents appear, enable the following Android permissions:',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppTheme.mutedSteel,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildPermissionCard(
                            title: 'Usage Access (Required)',
                            description:
                                'Allows the native Android background engine to detect when a protected application enters the foreground.',
                            icon: Icons.query_stats_rounded,
                            isGranted: _hasUsageStats,
                            onRequest: () async {
                              await AppLockChannel.requestUsageStatsPermission();
                            },
                          ),

                          _buildPermissionCard(
                            title: 'Display Over Apps (Required)',
                            description:
                                'Enables drawing the native security shield instantly over protected apps before their contents appear.',
                            icon: Icons.layers_rounded,
                            isGranted: _hasOverlay,
                            onRequest: () async {
                              await AppLockChannel.requestOverlayPermission();
                            },
                          ),

                          _buildPermissionCard(
                            title: 'Accessibility Service (Recommended)',
                            description:
                                'Enables zero-millisecond window transition detection. Intercepts app switches immediately with zero lag.',
                            icon: Icons.accessibility_new_rounded,
                            isGranted: _hasAccessibility,
                            onRequest: () async {
                              await AppLockChannel.requestAccessibilityPermission();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      border: Border(
                          top: BorderSide(
                              color: AppTheme.outlineVariant, width: 1)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _allRequiredGranted
                              ? AppTheme.primary
                              : AppTheme.surfaceContainerHigh,
                          foregroundColor: _allRequiredGranted
                              ? Colors.white
                              : AppTheme.mutedSteel,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _allRequiredGranted ? _onProceed : null,
                        child: Text(
                          _allRequiredGranted
                              ? 'Continue to App Lock'
                              : 'Enable Required Permissions Above',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(
        borderColor:
            isGranted ? AppTheme.emeraldBorder : AppTheme.outlineVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGranted
                      ? AppTheme.emeraldBg
                      : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isGranted
                      ? AppTheme.primaryContainer
                      : AppTheme.mutedSteel,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (isGranted)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.primaryContainer, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              color: AppTheme.mutedSteel,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: isGranted
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.emeraldBorder),
                    ),
                    child: Text(
                      'Enabled',
                      style: GoogleFonts.manrope(
                        color: AppTheme.primaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.outlineVariant),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onRequest,
                    child: Text(
                      'Enable in Settings',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
