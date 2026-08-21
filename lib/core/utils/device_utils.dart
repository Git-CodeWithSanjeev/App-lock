import 'package:flutter/material.dart';

/// Utility functions for device screen handling, keyboard dismissal, etc.
class DeviceUtils {
  /// Unfocuses active text input to dismiss the software keyboard.
  static void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  /// Returns true if device is in landscape mode.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}
