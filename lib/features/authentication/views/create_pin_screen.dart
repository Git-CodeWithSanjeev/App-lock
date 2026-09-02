import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
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
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 6) return;

    setState(() {
      _errorMessage = null;
      _pin += digit;
    });

    if (_pin.length == 6) {
      _handleCompletePin();
    }
  }

  void _onClear() {
    setState(() {
      _pin = '';
      _errorMessage = null;
    });
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onOkPressed() {
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
          await AppLockRepository.instance.updatePin(_pin);
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
          await AppLockRepository.instance.updatePin(_pin);
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
                  Expanded(
                    child: Text('Master PIN successfully updated!'),
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
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.onSurface, size: 24),
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
            icon: const Icon(Icons.lock_outline_rounded,
                size: 20, color: AppTheme.onSurface),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Row(
                    children: [
                      Icon(Icons.shield_rounded,
                          color: AppTheme.primaryContainer),
                      SizedBox(width: 8),
                      Text('Security Safeguard',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  content: const Text(
                    'This 6-digit master PIN secures all locked applications. '
                    'Only entering this exact PIN will unlock your protected apps.',
                    style: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.secondary,
                        height: 1.45),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Understood',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryContainer)),
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
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryContainer),
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
                              final isFilled = index < _pin.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled
                                      ? (_errorMessage != null
                                          ? AppTheme.error
                                          : AppTheme.primary)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _errorMessage != null
                                        ? AppTheme.error
                                        : (isFilled
                                            ? AppTheme.primary
                                            : AppTheme.outlineLight),
                                    width: 2.2,
                                  ),
                                  boxShadow: isFilled
                                      ? [
                                          BoxShadow(
                                            color: (_errorMessage != null
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
                                  _buildCircleActionButton(
                                    icon: Icons.backspace_outlined,
                                    iconColor: AppTheme.onSurface,
                                    onTap: _onBackspace,
                                    onLongPress: _onClear,
                                  ),
                                  _buildCircleDigitButton(
                                      const _KeyData('0', '+')),
                                  _buildCircleOkButton(),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 1),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shield_outlined,
                                  color: AppTheme.mutedSteel, size: 16),
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
        onTap: () => _onDigit(keyData.digit),
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
    final hasDigits = _pin.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onOkPressed,
        borderRadius: BorderRadius.circular(33),
        splashColor: AppTheme.primary.withAlpha(40),
        highlightColor: AppTheme.primary.withAlpha(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasDigits ? AppTheme.primary : Colors.white,
            border: Border.all(
              color: hasDigits ? AppTheme.primary : AppTheme.outlineVariant,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: hasDigits
                    ? AppTheme.primary.withAlpha(70)
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
