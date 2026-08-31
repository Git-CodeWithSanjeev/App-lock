import '../../../data/platform/app_lock_channel.dart';

/// Service dedicated to biometric (fingerprint/face) authentication operations.
class BiometricService {
  /// Checks whether physical biometric hardware is available and enrolled.
  Future<bool> isBiometricAvailable() async {
    return await AppLockChannel.isBiometricAvailable();
  }

  /// Triggers native Android BiometricPrompt for unlocking an application session.
  Future<bool> triggerBiometricUnlock({
    required String packageName,
    required String appName,
  }) async {
    return await AppLockChannel.triggerBiometricUnlock(
      packageName: packageName,
      appName: appName,
    );
  }

  /// Triggers native biometric verification with device credential fallback for PIN reset.
  Future<bool> triggerForgotPinVerification({
    required String packageName,
    required String appName,
  }) async {
    return await AppLockChannel.triggerForgotPinVerification(
      packageName: packageName,
      appName: appName,
    );
  }
}
