import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pin_keypad.dart';
import '../../../data/repositories/app_lock_repository.dart';
import '../controllers/authentication_controller.dart';

/// "Create Your PIN" Screen matching Porcelain Guardian design.
///
/// Implements the clean 2-step PIN setup:
/// - Step 1: User creates a 6-digit master PIN.
/// - Step 2: User confirms the 6-digit master PIN.
/// Once confirmed, saves and synchronizes the PIN, then proceeds directly to home/Lock App screen.
/// In Change/Reset PIN flow:
/// - Step 1: Verify current PIN
/// - Step 2: Enter new PIN
/// - Step 3: Confirm new PIN
class CreatePinScreen extends StatefulWidget {
  final bool isInitialSetup;
  const CreatePinScreen({super.key, this.isInitialSetup = true});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  int _step = 1;
  String _firstPin = '';
  String? _errorMessage;
  bool _isSubmitting = false;

  int get _totalSteps => widget.isInitialSetup ? 2 : 3;
  double get _progressValue => _step / _totalSteps;

  String get _headline {
    if (widget.isInitialSetup) {
      return _step == 1 ? 'Create Your PIN' : 'Confirm Your PIN';
    } else {
      if (_step == 1) return 'Enter Current PIN';
      if (_step == 2) return 'Create New PIN';
      return 'Confirm New PIN';
    }
  }

  String get _subtitle {
    if (widget.isInitialSetup) {
      return _step == 1
          ? 'Set a 6-digit master PIN to safeguard your apps.'
          : 'Re-enter your 6-digit master PIN to confirm.';
    } else {
      if (_step == 1) {
        return 'Enter your current 6-digit master PIN to continue.';
      }
      if (_step == 2) {
        return 'Set a new 6-digit master PIN to safeguard your apps.';
      }
      return 'Re-enter your new 6-digit master PIN to confirm.';
    }
  }

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _pin = '';
    _firstPin = '';
    _isSubmitting = false;
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_isSubmitting || _pin.length >= 6) return;

    setState(() {
      _errorMessage = null;
      _pin += digit;
    });

    if (_pin.length == 6) {
      _handleCompletePin();
    }
  }

  void _onClear() {
    if (_isSubmitting) return;
    setState(() {
      _pin = '';
      _errorMessage = null;
    });
  }

  void _onBackspace() {
    if (_isSubmitting || _pin.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onOkPressed() {
    if (_isSubmitting) return;
    if (_pin.length == 6) {
      _handleCompletePin();
    } else {
      _shakeController.forward(from: 0.0);
      setState(() {
        _errorMessage = 'Please enter all 6 digits.';
      });
    }
  }

  void _handleBack() {
    if (widget.isInitialSetup) {
      if (_step == 2) {
        setState(() {
          _step = 1;
          _pin = '';
          _firstPin = '';
          _errorMessage = null;
        });
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      if (_step == 3) {
        setState(() {
          _step = 2;
          _pin = '';
          _errorMessage = null;
        });
      } else if (_step == 2) {
        setState(() {
          _step = 1;
          _pin = '';
          _firstPin = '';
          _errorMessage = null;
        });
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleCompletePin() async {
    if (_isSubmitting) return;

    if (widget.isInitialSetup) {
      if (_step == 1) {
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _step = 2;
          _errorMessage = null;
        });
      } else {
        if (_pin == _firstPin) {
          _isSubmitting = true;
          final completedPin = _pin;
          _pin = '';
          _firstPin = '';
          await AppLockRepository.instance.updatePin(completedPin);
          await AppLockRepository.instance.setHasSetPin(true);
          await AppLockRepository.instance.syncToNative();

          if (Get.isRegistered<AuthenticationController>()) {
            Get.find<AuthenticationController>().reloadState();
          }

          if (!mounted) return;
          Get.offAllNamed('/home');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.primaryContainer,
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Master PIN configured! Select apps to lock.'),
                  ),
                ],
              ),
            ),
          );
        } else {
          _shakeController.forward(from: 0.0);
          setState(() {
            _errorMessage = 'PINs do not match. Please re-enter.';
            _pin = '';
          });
        }
      }
    } else {
      // Strict PIN change/reset flow: Step 1 verifies old PIN first
      if (_step == 1) {
        final isOldValid = AppLockRepository.instance.verifyPin(_pin);
        if (isOldValid) {
          setState(() {
            _pin = '';
            _step = 2;
            _errorMessage = null;
          });
        } else {
          _shakeController.forward(from: 0.0);
          setState(() {
            _errorMessage = 'Incorrect current PIN. Please try again.';
            _pin = '';
          });
        }
      } else if (_step == 2) {
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _step = 3;
          _errorMessage = null;
        });
      } else {
        if (_pin == _firstPin) {
          _isSubmitting = true;
          final completedPin = _pin;
          _pin = '';
          _firstPin = '';
          await AppLockRepository.instance.updatePin(completedPin);
          await AppLockRepository.instance.setHasSetPin(true);
          await AppLockRepository.instance.syncToNative();

          if (Get.isRegistered<AuthenticationController>()) {
            Get.find<AuthenticationController>().reloadState();
          }

          if (!mounted) return;
          Get.back();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.primaryContainer,
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Master PIN successfully updated!')),
                ],
              ),
            ),
          );
        } else {
          _shakeController.forward(from: 0.0);
          setState(() {
            _errorMessage = 'PINs do not match. Please re-enter.';
            _pin = '';
            _step = 2;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.onSurface,
            size: 24,
          ),
          onPressed: _handleBack,
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Text(
            'Step $_step of $_totalSteps',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: AppTheme.onSurface,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: AppTheme.primaryContainer,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Security Safeguard',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'This 6-digit master PIN secures all locked applications. '
                    'Only entering this exact PIN will unlock your protected apps.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.secondary,
                      height: 1.45,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Understood',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _progressValue,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryContainer,
            ),
            minHeight: 4,
          ),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleBack();
        },
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
                        const Spacer(flex: 1),

                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppTheme.blueBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: AppTheme.primary,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          _headline,
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
                            _subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mutedSteel,
                            ),
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                color: AppTheme.error,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        PinDotsIndicator(
                          enteredLength: _pin.length,
                          hasError: _errorMessage != null,
                          shakeAnimation: _shakeAnimation,
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: PinKeypad(
                            onDigitPressed: _onDigit,
                            onBackspacePressed: _onBackspace,
                            onClearPressed: _onClear,
                            onOkPressed: _onOkPressed,
                            hasDigitsEntered: _pin.isNotEmpty,
                            okActiveColor: AppTheme.primary,
                          ),
                        ),

                        const Spacer(flex: 1),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: AppTheme.mutedSteel,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.isInitialSetup
                                      ? '6-digit code protects all locked apps'
                                      : (_step == 1
                                            ? 'Current PIN verification required to proceed'
                                            : 'Enter and confirm your new 6-digit PIN'),
                                  style: GoogleFonts.manrope(
                                    color: AppTheme.mutedSteel,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
