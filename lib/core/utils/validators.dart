/// Utility functions for validating user inputs (PIN codes, etc.).
class Validators {
  /// Validates that a PIN is exactly 6 numeric digits.
  static bool isValidPin(String pin) {
    if (pin.length != 6) return false;
    return RegExp(r'^[0-9]{6}$').hasMatch(pin);
  }

  /// Verifies two PIN codes match.
  static bool doPinsMatch(String pin1, String pin2) {
    return pin1.isNotEmpty && pin1 == pin2;
  }
}
