import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/platform/app_lock_channel.dart';
import '../../../data/repositories/app_lock_repository.dart';

/// Manages PIN keypad input, verification, reset flows, and biometric authentication.
class AuthenticationController extends GetxController {
  static AuthenticationController get to =>
      Get.find<AuthenticationController>();

  final AppLockRepository _repo = AppLockRepository.instance;

  final RxBool isSelfAuthenticated = false.obs;
  DateTime? _lastPausedTime;

  final RxString enteredPin = ''.obs;
  final RxBool hasError = false.obs;
  final RxnString errorMessage = RxnString();

  final RxInt setupStep = 1.obs;
  final RxString setupFirstPin = ''.obs;

  final RxBool isResetPinMode = false.obs;
  final RxInt resetStep = 1.obs;
  final RxString resetNewPin = ''.obs;
  final RxnString resetMessage = RxnString();

  final RxBool canUseBiometrics = false.obs;
  final RxBool isAuthenticatingBiometric = false.obs;
  bool _hasAutoPrompted = false;

  String _savedPinHash = AppConstants.defaultPin;
  int _lastKeyPressTime = 0;
  Timer? _errorClearTimer;

  @override
  void onInit() {
    super.onInit();
    initSecurityPreferences();
  }

  void reloadState() {
    initSecurityPreferences();
  }

  @override
  void onClose() {
    _errorClearTimer?.cancel();
    super.onClose();
  }

  Future<void> initSecurityPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final pin = prefs.getString(StorageKeys.pinHash);
      if (pin != null && pin.isNotEmpty) {
        _savedPinHash = pin;
        try {
          if (_repo.settings.value.pinHash != pin) {
            _repo.settings.value = _repo.settings.value.copyWith(pinHash: pin);
          }
        } catch (_) {}
      }
      final biometricEnabled =
          prefs.getBool(StorageKeys.biometricEnabled) ?? true;
      final hwAvailable = await AppLockChannel.isBiometricAvailable();

      canUseBiometrics.value = hwAvailable && biometricEnabled;
    } catch (_) {}
  }

  void resetSession() {
    _errorClearTimer?.cancel();
    _errorClearTimer = null;
    enteredPin.value = '';
    hasError.value = false;
    errorMessage.value = null;
    isResetPinMode.value = false;
    resetStep.value = 1;
    resetNewPin.value = '';
    resetMessage.value = null;
  }

  void onDigit(String digit, {VoidCallback? onComplete}) {
    _errorClearTimer?.cancel();
    _errorClearTimer = null;

    if (hasError.value) {
      enteredPin.value = '';
      hasError.value = false;
      errorMessage.value = null;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastKeyPressTime < 100) return;
    _lastKeyPressTime = now;

    if (enteredPin.value.length >= 6) return;

    hasError.value = false;
    errorMessage.value = null;
    enteredPin.value += digit;

    if (enteredPin.value.length == 6) {
      onComplete?.call();
    }
  }

  void onBackspace() {
    _errorClearTimer?.cancel();
    _errorClearTimer = null;

    if (hasError.value) {
      hasError.value = false;
      errorMessage.value = null;
      enteredPin.value = '';
      return;
    }

    if (enteredPin.value.isNotEmpty) {
      hasError.value = false;
      errorMessage.value = null;
      enteredPin.value = enteredPin.value.substring(
        0,
        enteredPin.value.length - 1,
      );
    }
  }

  void onClear() {
    _errorClearTimer?.cancel();
    _errorClearTimer = null;

    if (enteredPin.value.isNotEmpty) {
      hasError.value = false;
      errorMessage.value = null;
      enteredPin.value = '';
    }
  }

  void setError(String message) {
    hasError.value = true;
    errorMessage.value = message;
    _errorClearTimer?.cancel();
    _errorClearTimer = Timer(const Duration(milliseconds: 320), () {
      enteredPin.value = '';
    });
  }

  void clearError() {
    hasError.value = false;
    errorMessage.value = null;
    resetMessage.value = null;
  }

  bool verifyPin(String inputPin, {String? cachedPin}) {
    try {
      if (_repo.verifyPin(inputPin)) return true;
    } catch (_) {}

    final fallback = cachedPin ?? _savedPinHash;
    if (fallback.isNotEmpty && inputPin == fallback) {
      return true;
    }

    return false;
  }

  bool verifyCurrentEnteredPin({String? cachedPin}) {
    final valid = verifyPin(enteredPin.value, cachedPin: cachedPin);
    if (valid) {
      hasError.value = false;
      errorMessage.value = null;
      return true;
    } else {
      setError('Incorrect PIN. Try again');
      return false;
    }
  }

  Future<void> saveMasterPin(String newPin) async {
    _savedPinHash = newPin;
    await _repo.updatePin(newPin);
    await _repo.setHasSetPin(true);
    await _repo.syncToNative();
  }

  void authenticateSelf() {
    _lastPausedTime = null;
    isSelfAuthenticated.value = true;
    resetSession();
  }

  void lockSelf() {
    isSelfAuthenticated.value = false;
    _lastPausedTime = null;
    resetSession();
  }

  void handleAppLifecycleState(AppLifecycleState state, int relockTimeoutMs) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (isSelfAuthenticated.value) {
        _lastPausedTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (isSelfAuthenticated.value && _lastPausedTime != null) {
        final elapsed = DateTime.now()
            .difference(_lastPausedTime!)
            .inMilliseconds;

        if (relockTimeoutMs == 0 || elapsed >= relockTimeoutMs) {
          isSelfAuthenticated.value = false;
          resetSession();
        }
      }
      _lastPausedTime = null;
    }
  }

  Future<bool> triggerBiometricUnlock({
    required String packageName,
    required String appName,
    VoidCallback? onSuccess,
  }) async {
    if (!canUseBiometrics.value ||
        isAuthenticatingBiometric.value ||
        isResetPinMode.value) {
      return false;
    }

    isAuthenticatingBiometric.value = true;
    try {
      final success = await AppLockChannel.triggerBiometricUnlock(
        packageName: packageName,
        appName: appName,
      );

      if (success) {
        onSuccess?.call();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      isAuthenticatingBiometric.value = false;
    }
  }

  void autoPromptBiometricOnce({
    required String packageName,
    required String appName,
    VoidCallback? onSuccess,
  }) {
    if (canUseBiometrics.value && !isResetPinMode.value && !_hasAutoPrompted) {
      _hasAutoPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        triggerBiometricUnlock(
          packageName: packageName,
          appName: appName,
          onSuccess: onSuccess,
        );
      });
    }
  }

  void enterResetPinMode() {
    isResetPinMode.value = true;
    resetStep.value = 1;
    resetNewPin.value = '';
    enteredPin.value = '';
    hasError.value = false;
    errorMessage.value = null;
    resetMessage.value = 'Step 1/3: Enter your current Master PIN';
  }

  void cancelResetPinMode() {
    isResetPinMode.value = false;
    resetStep.value = 1;
    resetNewPin.value = '';
    enteredPin.value = '';
    hasError.value = false;
    errorMessage.value = null;
    resetMessage.value = null;
  }
}

typedef PinController = AuthenticationController;
