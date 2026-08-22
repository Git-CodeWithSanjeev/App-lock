import '../../core/constants/app_constants.dart';

/// Holds the configurable settings for App Lock protection.
class LockSettings {
  final bool protectionEnabled;
  final bool biometricEnabled;
  final int relockTimeoutMs;
  final String pinHash;
  final bool? _recentAppsPrivacy;
  final bool? _uninstallProtection;

  bool get recentAppsPrivacy => _recentAppsPrivacy ?? true;
  bool get uninstallProtection => _uninstallProtection ?? false;

  const LockSettings({
    this.protectionEnabled = true,
    this.biometricEnabled = true,
    this.relockTimeoutMs = 0,
    this.pinHash = AppConstants.defaultPin,
    bool recentAppsPrivacy = true,
    bool uninstallProtection = false,
  })  : _recentAppsPrivacy = recentAppsPrivacy,
        _uninstallProtection = uninstallProtection;

  LockSettings copyWith({
    bool? protectionEnabled,
    bool? biometricEnabled,
    int? relockTimeoutMs,
    String? pinHash,
    bool? recentAppsPrivacy,
    bool? uninstallProtection,
  }) {
    return LockSettings(
      protectionEnabled: protectionEnabled ?? this.protectionEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      relockTimeoutMs: relockTimeoutMs ?? this.relockTimeoutMs,
      pinHash: pinHash ?? this.pinHash,
      recentAppsPrivacy: recentAppsPrivacy ?? this.recentAppsPrivacy,
      uninstallProtection: uninstallProtection ?? this.uninstallProtection,
    );
  }
}
