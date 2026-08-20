import 'package:flutter/material.dart';
import 'app_lock_switch.dart';

/// General toggle switch widget for preferences.
class ToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppLockSwitch(
      value: value,
      onChanged: onChanged,
    );
  }
}
