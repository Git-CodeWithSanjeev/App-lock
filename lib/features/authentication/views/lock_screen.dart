import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/platform/app_lock_channel.dart';
import '../../../data/repositories/app_lock_repository.dart';

/// Single authoritative LockScreen component.
///
/// Used identically across:
/// 1. App Lock self-authentication gate (protecting the app itself)
/// 2. Protected third-party applications (via TYPE_APPLICATION_OVERLAY window)
/// 3. Re-lock after timeout / backgrounding
///
/// Guarantees exact 1:1 visual styling, layout, typography, keypad spacing,
/// and authentication state management.
class LockScreen extends StatefulWidget {
  final String? targetPackage;
  final String? appName;
  final Uint8List? appIconBytes;
  final bool isSelfLock;
  final VoidCallback onAuthenticated;
  final VoidCallback? onDismiss;

  const LockScreen({
    super.key,
    this.targetPackage,
    this.appName,
    this.appIconBytes,
    this.isSelfLock = false,
    required this.onAuthenticated,
    this.onDismiss,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _hasError = false;
  String? _errorMessage;
  bool _canUseBiometrics = false;
  bool _isAuthenticatingBiometric = false;
  bool _hasAutoPrompted = false;

  // 3-step PIN reset state
  bool _isResetPinMode = false;
  int _resetStep = 1; // 1 = Old PIN, 2 = New PIN, 3 = Confirm New PIN
  String _newPin = '';
  String? _resetMessage;

  // Cached saved PIN for overlay isolate if AppLockRepository isn't initialized
  String _savedPinHash = AppConstants.defaultPin;

  Timer? _clearPinTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _initSecurityData();
  }

  @override
  void dispose() {
    _clearPinTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _initSecurityData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final pin = prefs.getString(StorageKeys.pinHash);
      if (pin != null && pin.isNotEmpty) {
        _savedPinHash = pin;
        try {
          if (AppLockRepository.instance.settings.value.pinHash != pin) {
            AppLockRepository.instance.settings.value =
                AppLockRepository.instance.settings.value.copyWith(pinHash: pin);
          }
        } catch (_) {}
      }
      final biometricEnabled = prefs.getBool(StorageKeys.biometricEnabled) ?? true;

      // Check physical hardware availability natively via BiometricPromptActivity
      final hwAvailable = await AppLockChannel.isBiometricAvailable();

      if (mounted) {
        setState(() {
          _canUseBiometrics = hwAvailable && biometricEnabled;
        });

        // Offer biometric prompt automatically once on mount if enabled
        if (_canUseBiometrics && !_isResetPinMode && !_hasAutoPrompted) {
          _hasAutoPrompted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerBiometricAuth();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _triggerBiometricAuth() async {
    if (!_canUseBiometrics || _isAuthenticatingBiometric || _isResetPinMode) return;
    _isAuthenticatingBiometric = true;

    try {
      final targetPkg = widget.targetPackage ?? (widget.isSelfLock ? 'com.example.screen_lock' : '');
      final appLabel = widget.appName ?? (widget.isSelfLock ? 'App Lock' : 'Protected App');

      final bool success = await AppLockChannel.triggerBiometricUnlock(
        packageName: targetPkg,
        appName: appLabel,
      );

      if (success && mounted) {
        widget.onAuthenticated();
      }
    } catch (_) {
    } finally {
      _isAuthenticatingBiometric = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 6) return;

    setState(() {
      _enteredPin += digit;
      _hasError = false;
      _errorMessage = null;
    });

    if (_enteredPin.length == 6) {
      if (_isResetPinMode) {
        _handleResetPinInput();
      } else {
        _verifyEnteredPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  void _onClearPressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = '';
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  void _onOkPressed() {
    if (_enteredPin.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Enter your 6-digit PIN';
      });
      _shakeController.forward(from: 0.0);
      return;
    }

    if (_isResetPinMode) {
      _handleResetPinInput();
    } else {
      if (_enteredPin.length == 6) {
        _verifyEnteredPin();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'PIN must be 6 digits';
        });
        _shakeController.forward(from: 0.0);
      }
    }
  }

  void _verifyEnteredPin() {
    bool isValid = false;
    try {
      isValid = AppLockRepository.instance.verifyPin(_enteredPin);
    } catch (_) {
      isValid = (_enteredPin == _savedPinHash);
    }
    if (!isValid && _savedPinHash.isNotEmpty) {
      isValid = (_enteredPin == _savedPinHash);
    }

    if (isValid) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
      widget.onAuthenticated();
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Incorrect PIN. Try again';
      });
      _shakeController.forward(from: 0.0);
      _clearPinTimer?.cancel();
      _clearPinTimer = Timer(const Duration(milliseconds: 320), () {
        if (mounted) {
          setState(() {
            _enteredPin = '';
          });
        }
      });
    }
  }

  void _enterResetPinMode() {
    setState(() {
      _isResetPinMode = true;
      _resetStep = 1;
      _enteredPin = '';
      _newPin = '';
      _hasError = false;
      _resetMessage = null;
    });
  }

  void _cancelResetPinMode() {
    setState(() {
      _isResetPinMode = false;
      _resetStep = 1;
      _enteredPin = '';
      _newPin = '';
      _hasError = false;
      _resetMessage = null;
    });
  }

  void _handleResetPinInput() {
    if (_resetStep == 1) {
      bool isOldValid = false;
      try {
        isOldValid = AppLockRepository.instance.verifyPin(_enteredPin);
      } catch (_) {
        isOldValid = (_enteredPin == _savedPinHash);
      }
      if (!isOldValid && _savedPinHash.isNotEmpty) {
        isOldValid = (_enteredPin == _savedPinHash);
      }

      if (isOldValid) {
        setState(() {
          _resetStep = 2;
          _enteredPin = '';
          _hasError = false;
          _resetMessage = null;
        });
      } else {
        setState(() {
          _hasError = true;
          _resetMessage = 'Incorrect current PIN. Try again';
          _enteredPin = '';
        });
        _shakeController.forward(from: 0.0);
      }
    } else if (_resetStep == 2) {
      setState(() {
        _newPin = _enteredPin;
        _enteredPin = '';
        _resetStep = 3;
        _hasError = false;
        _resetMessage = null;
      });
    } else {
      if (_enteredPin == _newPin) {
        _finalizePinReset(_newPin);
      } else {
        setState(() {
          _hasError = true;
          _enteredPin = '';
          _resetStep = 2;
          _newPin = '';
          _resetMessage = 'PINs did not match. Enter new PIN again';
        });
        _shakeController.forward(from: 0.0);
      }
    }
  }

  Future<void> _finalizePinReset(String newPin) async {
    _savedPinHash = newPin;

    try {
      await AppLockRepository.instance.updatePin(newPin);
      await AppLockRepository.instance.setHasSetPin(true);
      await AppLockRepository.instance.syncToNative();
    } catch (_) {}

    try {
      await AppLockChannel.syncPin(newPin);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.pinHash, newPin);
      await prefs.setBool(StorageKeys.hasSetPin, true);
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _isResetPinMode = false;
      _resetStep = 1;
      _enteredPin = '';
      _newPin = '';
      _hasError = false;
      _resetMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.primaryContainer,
        content: Text('PIN successfully updated! Enter new PIN to unlock.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String get _displayTitle {
    if (_isResetPinMode) {
      if (_resetStep == 1) return 'Verify Current PIN';
      if (_resetStep == 2) return 'Create New PIN';
      return 'Confirm New PIN';
    }
    if (!widget.isSelfLock && widget.appName != null && widget.appName!.isNotEmpty) {
      return 'Unlock ${widget.appName}';
    }
    return 'App Lock';
  }

  String get _displaySubtitle {
    if (_hasError) {
      return _resetMessage ?? _errorMessage ?? 'Incorrect PIN. Try again';
    }
    if (_isResetPinMode) {
      if (_resetStep == 1) return 'Enter your current 6-digit PIN';
      if (_resetStep == 2) return 'Enter a new 6-digit PIN';
      return 'Re-enter your new 6-digit PIN to confirm';
    }
    if (_canUseBiometrics) {
      return 'Enter PIN or fingerprint to continue';
    }
    return 'Enter Master PIN to continue';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isResetPinMode) {
          _cancelResetPinMode();
        } else if (widget.onDismiss != null) {
          widget.onDismiss!();
        } else {
          AppLockChannel.goHome();
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.surface,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        if (_isResetPinMode)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                   icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: AppTheme.mutedSteel,
                                    size: 24,
                                  ),
                                  onPressed: _cancelResetPinMode,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.blueBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppTheme.blueBorder),
                                  ),
                                  child: Text(
                                    'Step $_resetStep/3',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),

                        const Spacer(flex: 1),

                        _buildAppBadge(),
                        const SizedBox(height: 14),

                        // Title & Subtitle
                        Text(
                          _displayTitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _displaySubtitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              fontWeight: _hasError
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _hasError
                                  ? AppTheme.error
                                  : AppTheme.mutedSteel,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 6 PIN Dots (Animated Shake on error)
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: child,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (index) {
                              final isFilled = index < _enteredPin.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled
                                      ? (_hasError
                                          ? AppTheme.error
                                          : AppTheme.primary)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _hasError
                                        ? AppTheme.error
                                        : (isFilled
                                            ? AppTheme.primary
                                            : AppTheme.outlineLight),
                                    width: 2.2,
                                  ),
                                  boxShadow: isFilled
                                      ? [
                                          BoxShadow(
                                            color: (_hasError
                                                    ? AppTheme.error
                                                    : AppTheme.primary)
                                                .withAlpha(80),
                                            blurRadius: 6,
                                          ),
                                        ]
                                      : null,
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            children: [
                              _buildKeypadRow([
                                const _KeyData('1', ''),
                                const _KeyData('2', 'ABC'),
                                const _KeyData('3', 'DEF'),
                              ]),
                              const SizedBox(height: 10),
                              _buildKeypadRow([
                                const _KeyData('4', 'GHI'),
                                const _KeyData('5', 'JKL'),
                                const _KeyData('6', 'MNO'),
                              ]),
                              const SizedBox(height: 10),
                              _buildKeypadRow([
                                const _KeyData('7', 'PQRS'),
                                const _KeyData('8', 'TUV'),
                                const _KeyData('9', 'WXYZ'),
                              ]),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Backspace Button
                                  _buildCircleActionButton(
                                    icon: Icons.backspace_outlined,
                                    iconColor: AppTheme.onSurface,
                                    onTap: _onBackspacePressed,
                                    onLongPress: _onClearPressed,
                                  ),
                                  // 0 Digit Key
                                  _buildCircleDigitButton(
                                      const _KeyData('0', '+')),
                                  // Tactile OK Confirmation Button
                                  _buildCircleOkButton(),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Fingerprint Quick Tap (Positioned Below Numpad)
                        if (_canUseBiometrics && !_isResetPinMode) ...[
                          const SizedBox(height: 12),
                          _buildBiometricButton(),
                        ],

                        const SizedBox(height: 8),

                        // Forgot PIN / Cancel Option
                        TextButton(
                          onPressed: _isResetPinMode
                              ? _cancelResetPinMode
                              : _enterResetPinMode,
                          child: Text(
                            _isResetPinMode
                                ? 'Cancel PIN Reset'
                                : 'Forgot PIN?',
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _isResetPinMode
                                  ? AppTheme.error
                                  : AppTheme.primary,
                            ),
                          ),
                        ),

                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBadge() {
    return SizedBox(
      width: 72,
      height: 72,
      child: Center(
        child: _buildBadgeContent(),
      ),
    );
  }

  Widget _buildBadgeContent() {
    if (_isResetPinMode) {
      return Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.blueBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.lock_reset_rounded,
          color: AppTheme.primary,
          size: 36,
        ),
      );
    }
    if (!widget.isSelfLock && widget.appIconBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.memory(
          widget.appIconBytes!,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
        ),
      );
    }
    if (widget.isSelfLock) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/images/app_icon.png',
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppTheme.blueBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: AppTheme.primary,
              size: 38,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: AppTheme.blueBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.apps_rounded,
        color: AppTheme.primary,
        size: 36,
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0xFF0F172A).withAlpha(25),
      child: InkWell(
        onTap: _triggerBiometricAuth,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 66,
          height: 66,
          child: Center(
            child: Icon(
              Icons.fingerprint_rounded,
              color: AppTheme.primary,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<_KeyData> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildCircleDigitButton(k)).toList(),
    );
  }

  Widget _buildCircleDigitButton(_KeyData keyData) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(keyData.digit),
        borderRadius: BorderRadius.circular(33),
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppTheme.outlineVariant, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                keyData.digit,
                style: GoogleFonts.manrope(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  height: 1.1,
                ),
              ),
              if (keyData.subtext.isNotEmpty)
                Text(
                  keyData.subtext,
                  style: GoogleFonts.manrope(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedSteel,
                    letterSpacing: 0.8,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(33),
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppTheme.outlineVariant, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }

  Widget _buildCircleOkButton() {
    final hasDigits = _enteredPin.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onOkPressed,
        borderRadius: BorderRadius.circular(33),
        splashColor: AppTheme.primaryContainer.withAlpha(40),
        highlightColor: AppTheme.primaryContainer.withAlpha(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasDigits ? AppTheme.primaryContainer : Colors.white,
            border: Border.all(
              color: hasDigits
                  ? AppTheme.primaryContainer
                  : AppTheme.outlineVariant,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: hasDigits
                    ? AppTheme.primaryContainer.withAlpha(70)
                    : const Color(0xFF0F172A).withAlpha(10),
                blurRadius: hasDigits ? 6 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'OK',
            style: GoogleFonts.manrope(
              color: hasDigits ? Colors.white : AppTheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyData {
  final String digit;
  final String subtext;
  const _KeyData(this.digit, this.subtext);
}

/// Backward compatibility alias
typedef SharedLockScreen = LockScreen;
