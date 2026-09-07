import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/platform/samsung_channel.dart';
import '../../../data/repositories/app_lock_repository.dart';

/// Dedicated onboarding / device setup screen for Samsung One UI devices in Porcelain Guardian theme.
///
/// Explains how One UI's "Sleeping Apps" and "Deep Sleeping Apps" features
/// aggressively terminate background services, and guides users through setting
/// the app battery usage to "Unrestricted".
class DeviceSetupScreen extends StatefulWidget {
  final bool isModal;
  const DeviceSetupScreen({super.key, this.isModal = false});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen>
    with WidgetsBindingObserver {
  bool _isOptimizedIgnored = false;
  String? _oneUiVersion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final ignored = await SamsungChannel.isBatteryOptimizationIgnored();
    final version = await SamsungChannel.getOneUiVersion();
    if (mounted) {
      setState(() {
        _isOptimizedIgnored = ignored;
        _oneUiVersion = version;
        _isLoading = false;
      });
    }
  }

  Future<void> _finishGuide() async {
    await AppLockRepository.instance.setSeenSamsungGuide(true);
    if (mounted) {
      if (widget.isModal) {
        Navigator.pop(context);
      } else {
        Get.offNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'One UI Optimization',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.cardDecoration(
                        backgroundColor: AppTheme.surfaceContainerLowest,
                        borderColor: AppTheme.outlineVariant,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.emeraldBorder),
                            ),
                            child: const Icon(
                              Icons.phone_android_rounded,
                              color: AppTheme.primaryContainer,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Samsung Galaxy Detected',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _oneUiVersion ?? 'Galaxy One UI Environment',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: AppTheme.primaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.cardDecoration(
                        backgroundColor: _isOptimizedIgnored
                            ? AppTheme.emeraldBg
                            : AppTheme.surfaceContainerLowest,
                        borderColor: _isOptimizedIgnored
                            ? AppTheme.emeraldBorder
                            : AppTheme.outlineVariant,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isOptimizedIgnored
                                    ? Icons.verified_rounded
                                    : Icons.warning_amber_rounded,
                                color: _isOptimizedIgnored
                                    ? AppTheme.primaryContainer
                                    : AppTheme.warningAmber,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _isOptimizedIgnored
                                      ? 'Protection Active'
                                      : 'Action Required for One UI',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _isOptimizedIgnored
                                        ? AppTheme.primaryContainer
                                        : AppTheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Samsung One UI includes aggressive "Sleeping Apps" management. Without setting this app to "Unrestricted", Samsung may terminate the background lock monitor.',
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              color: AppTheme.mutedSteel,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isOptimizedIgnored
                                  ? AppTheme.surfaceContainerLowest
                                  : AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isOptimizedIgnored
                                    ? AppTheme.emeraldBorder
                                    : AppTheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isOptimizedIgnored
                                      ? Icons.check_circle_rounded
                                      : Icons.info_outline_rounded,
                                  size: 18,
                                  color: _isOptimizedIgnored
                                      ? AppTheme.primaryContainer
                                      : AppTheme.mutedSteel,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _isOptimizedIgnored
                                        ? 'Battery: Unrestricted (Configured)'
                                        : 'Battery: Restricted / Optimized (Needs Setup)',
                                    style: GoogleFonts.manrope(
                                      color: _isOptimizedIgnored
                                          ? AppTheme.primaryContainer
                                          : AppTheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      '3-Step Configuration',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildStepCard(
                      step: '1',
                      title: 'Open Battery Settings',
                      description:
                          'Tap the button below to open Samsung App Info Battery settings.',
                    ),
                    _buildStepCard(
                      step: '2',
                      title: 'Select "Unrestricted"',
                      description:
                          'Switch battery profile from "Optimized" to "Unrestricted".',
                    ),
                    _buildStepCard(
                      step: '3',
                      title: 'Add to "Never Sleeping Apps"',
                      description:
                          'In Device Care > Background usage limits, ensure App Lock is exempt.',
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          await SamsungChannel
                              .requestIgnoreBatteryOptimization();
                        },
                        icon: const Icon(Icons.battery_charging_full_rounded,
                            size: 22),
                        label: Text(
                          'Open Samsung Battery Settings',
                          style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: AppTheme.outlineVariant),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          await SamsungChannel.openSamsungAutoRunSettings();
                        },
                        icon: const Icon(Icons.settings_suggest_outlined,
                            size: 20, color: AppTheme.onSurface),
                        label: Text(
                          'Open Auto-Run / Device Care',
                          style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOptimizedIgnored
                              ? AppTheme.primary
                              : AppTheme.surfaceContainerHigh,
                          foregroundColor: _isOptimizedIgnored
                              ? Colors.white
                              : AppTheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _finishGuide,
                        child: Text(
                          _isOptimizedIgnored
                              ? 'Done • Return to Dashboard'
                              : 'I Have Configured This • Continue',
                          style:
                              GoogleFonts.manrope(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepCard(
      {required String step,
      required String title,
      required String description}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.emeraldBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.emeraldBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: GoogleFonts.manrope(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    color: AppTheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    color: AppTheme.mutedSteel,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias
typedef SamsungGuideScreen = DeviceSetupScreen;
