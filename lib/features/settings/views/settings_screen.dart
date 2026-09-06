import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_lock_switch.dart';
import '../../../data/repositories/app_lock_repository.dart';
import '../../authentication/views/create_pin_screen.dart';
import '../controllers/settings_controller.dart';
import 'widgets/permission_tile.dart';
import 'widgets/settings_section.dart';

/// Minimal Samsung One UI–inspired Settings Screen.
/// All options are functional and linked directly to repository/system channels.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  late final SettingsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());
    WidgetsBinding.instance.addObserver(this);
    _ctrl.checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ctrl.checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppLockRepository.instance;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Obx(() {
          final settings = _ctrl.settings.value;
          final hasPin = repo.hasSetPin();
          final hasUsageAccess = _ctrl.hasUsageAccess.value;
          final hasOverlay = _ctrl.hasOverlay.value;
          final isAccessibility = _ctrl.isAccessibility.value;
          final isServiceRunning = _ctrl.isServiceRunning.value;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              // One UI Spacious Header
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Security, lock behavior, and system permissions',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppTheme.mutedSteel,
                      ),
                    ),
                  ],
                ),
              ),

              SettingsSection(
                title: 'AUTHENTICATION',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      leading: _buildIconCircle(Icons.dialpad_rounded),
                      title: Text(
                        'Master PIN',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        hasPin
                            ? '6-digit PIN configured'
                            : 'PIN not configured',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: hasPin
                              ? AppTheme.mutedSteel
                              : AppTheme.warningAmber,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasPin ? 'Change' : 'Set up',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CreatePinScreen(isInitialSetup: false),
                          ),
                        );
                      },
                    ),
                    const Divider(
                        height: 1,
                        color: AppTheme.outlineVariant,
                        indent: 70),

                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      leading: _buildIconCircle(Icons.fingerprint_rounded),
                      title: Text(
                        'Biometric Unlock',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Use fingerprint or face to quickly unlock',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.mutedSteel,
                        ),
                      ),
                      trailing: AppLockSwitch(
                        value: settings.biometricEnabled,
                        onChanged: (val) => _ctrl.updateBiometric(val),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SettingsSection(
                title: 'LOCK BEHAVIOR',
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildIconCircle(Icons.timer_outlined),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Re-lock Timeout',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Require authentication after switching apps',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppTheme.mutedSteel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _buildSegmentItem(
                              'Immediately',
                              settings.relockTimeoutMs == 0,
                              () => _ctrl.updateRelockTimeout(0),
                            ),
                            _buildSegmentItem(
                              '1 min',
                              settings.relockTimeoutMs == 60 * 1000,
                              () => _ctrl.updateRelockTimeout(60 * 1000),
                            ),
                            _buildSegmentItem(
                              '5 min',
                              settings.relockTimeoutMs == 5 * 60 * 1000,
                              () => _ctrl.updateRelockTimeout(5 * 60 * 1000),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SettingsSection(
                title: 'PRIVACY & SECURITY',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      leading: _buildIconCircle(Icons.visibility_off_rounded),
                      title: Text(
                        'Recent Apps Privacy',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Obscure App Lock & lock screen previews in Recent Apps (FLAG_SECURE)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.mutedSteel,
                          height: 1.3,
                        ),
                      ),
                      trailing: AppLockSwitch(
                        value: settings.recentAppsPrivacy,
                        onChanged: (val) => _ctrl.updateRecentAppsPrivacy(val),
                      ),
                    ),
                    const Divider(
                        height: 1,
                        color: AppTheme.outlineVariant,
                        indent: 70),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.blueBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.blueBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppTheme.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How Recent Apps Privacy Works',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'App Lock & lock screens are fully obscured in Recent Apps via FLAG_SECURE. '
                                    'Android OS restricts third-party apps from altering external apps\' thumbnails (like Gallery). '
                                    'App Lock protects them by instantly blocking access (0ms) whenever they are resumed.',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: AppTheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(
                        height: 1,
                        color: AppTheme.outlineVariant,
                        indent: 70),

                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      leading: _buildIconCircle(Icons.shield_outlined),
                      title: Text(
                        'Uninstall Protection',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Requires Master PIN when accessing App Lock details or uninstall dialogs (best-effort)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.mutedSteel,
                          height: 1.3,
                        ),
                      ),
                      trailing: AppLockSwitch(
                        value: settings.uninstallProtection,
                        onChanged: (val) =>
                            _handleUninstallProtectionToggle(val, repo),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SettingsSection(
                title: 'SYSTEM PERMISSIONS',
                child: Column(
                  children: [
                    PermissionTile(
                      icon: Icons.data_usage_rounded,
                      title: 'Usage Access',
                      subtitle: 'Detects when protected apps open',
                      isGranted: hasUsageAccess,
                      onRequest: _ctrl.requestUsageAccess,
                    ),
                    const Divider(
                        height: 1,
                        color: AppTheme.outlineVariant,
                        indent: 70),
                    PermissionTile(
                      icon: Icons.layers_outlined,
                      title: 'Display Over Other Apps',
                      subtitle: 'Displays lock screen over locked apps',
                      isGranted: hasOverlay,
                      onRequest: _ctrl.requestOverlay,
                    ),
                    const Divider(
                        height: 1,
                        color: AppTheme.outlineVariant,
                        indent: 70),
                    PermissionTile(
                      icon: Icons.accessibility_new_rounded,
                      title: 'Instant Lock (Accessibility)',
                      subtitle: 'Zero-delay app detection',
                      isGranted: isAccessibility,
                      onRequest: _ctrl.openAccessibilitySettings,
                    ),
                    const Divider(
                        height: 1,
                        color: AppTheme.outlineVariant,
                        indent: 70),

                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      leading:
                          _buildIconCircle(Icons.running_with_errors_rounded),
                      title: Text(
                        'Background Service',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        isServiceRunning
                            ? 'Monitoring active'
                            : 'Service stopped',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: isServiceRunning
                              ? AppTheme.primary
                              : AppTheme.error,
                        ),
                      ),
                      trailing: isServiceRunning
                          ? _buildStatusChip('Active', true)
                          : TextButton(
                              onPressed: () async {
                                await AppLockRepository.instance
                                    .refreshServiceStatus();
                                await _ctrl.checkPermissions();
                              },
                              child: Text(
                                'Restart',
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
              ),

              const SizedBox(height: 24),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildIconCircle(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppTheme.blueBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppTheme.primary, size: 20),
    );
  }

  Widget _buildSegmentItem(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.onSurface : AppTheme.mutedSteel,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isGood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: isGood ? AppTheme.blueBg : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGood
              ? AppTheme.blueBorder
              : const Color(0xFFEF4444).withAlpha(60),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isGood ? AppTheme.primary : const Color(0xFFDC2626),
        ),
      ),
    );
  }

  Future<void> _handleUninstallProtectionToggle(
      bool enable, AppLockRepository repo) async {
    if (enable) {
      if (!_ctrl.isAccessibility.value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please grant Accessibility permission below to enable uninstall interception.',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: AppTheme.onSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _ctrl.updateUninstallProtection(true);
    } else {
      // Must prompt for PIN verification before disabling!
      final authenticated =
          await _promptPinVerification('Disable Uninstall Protection');
      if (authenticated) {
        await _ctrl.updateUninstallProtection(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Uninstall Protection disabled',
                style: GoogleFonts.manrope(),
              ),
              backgroundColor: AppTheme.onSurface,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<bool> _promptPinVerification(String title) async {
    final repo = AppLockRepository.instance;
    String pin = '';
    String? error;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void onDigit(String d) {
              if (pin.length >= 6) return;
              setModalState(() {
                pin += d;
                error = null;
              });
              if (pin.length == 6) {
                if (repo.verifyPin(pin)) {
                  Navigator.of(context).pop(true);
                } else {
                  setModalState(() {
                    error = 'Incorrect PIN';
                    pin = '';
                  });
                }
              }
            }

            void onBackspace() {
              if (pin.isNotEmpty) {
                setModalState(() {
                  pin = pin.substring(0, pin.length - 1);
                  error = null;
                });
              }
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error ?? 'Enter Master PIN to confirm',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight:
                          error != null ? FontWeight.w700 : FontWeight.w500,
                      color:
                          error != null ? AppTheme.error : AppTheme.mutedSteel,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isFilled ? AppTheme.primary : Colors.transparent,
                          border: Border.all(
                            color: isFilled
                                ? AppTheme.primary
                                : AppTheme.outlineLight,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  ...[
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9']
                  ].map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: row.map((d) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: InkWell(
                                onTap: () => onDigit(d),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    d,
                                    style: GoogleFonts.manrope(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                  Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: InkWell(
                            onTap: () => onDigit('0'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '0',
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: InkWell(
                            onTap: onBackspace,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.backspace_outlined,
                                color: AppTheme.onSurface,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result == true;
  }
}
