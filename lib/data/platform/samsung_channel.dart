import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

/// Platform channel bridge dedicated to Samsung One UI specific hardware and OS behaviors.
class SamsungChannel {
  static const MethodChannel _channel = MethodChannel(AppConstants.samsungChannel);

  /// Checks if the physical device hardware manufacturer is Samsung.
  static Future<bool> isSamsungDevice() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isSamsungDevice');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Detects the One UI / SEP (Samsung Experience Platform) version string.
  static Future<String?> getOneUiVersion() async {
    try {
      final String? result = await _channel.invokeMethod<String>('getOneUiVersion');
      return result;
    } on PlatformException catch (_) {
      return null;
    }
  }

  /// Checks if battery optimization has been set to "Unrestricted" for this app.
  static Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Opens Samsung's Device Care Battery activity directly (or falls back to standard settings).
  static Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimization');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Opens Samsung's Auto-Run / Auto-Start management settings.
  static Future<bool> openSamsungAutoRunSettings() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('openSamsungAutoRunSettings');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
