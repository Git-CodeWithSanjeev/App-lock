import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Data model representing a numeric keypad digit and its secondary alphabetic subtext.
class KeyData {
  final String digit;
  final String subtext;

  const KeyData(this.digit, this.subtext);
}

/// Standard layout of keypad rows for numeric PIN entry.
const List<List<KeyData>> standardKeypadRows = [
  [KeyData('1', ''), KeyData('2', 'ABC'), KeyData('3', 'DEF')],
  [KeyData('4', 'GHI'), KeyData('5', 'JKL'), KeyData('6', 'MNO')],
  [KeyData('7', 'PQRS'), KeyData('8', 'TUV'), KeyData('9', 'WXYZ')],
];

/// Reusable Samsung One UI circular numeric keypad.
///
/// Features 66x66 tactile circular buttons with elevation shadows,
/// subtext labels, backspace with long-press clear, and animated OK confirmation.
class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback? onClearPressed;
  final VoidCallback onOkPressed;
  final bool hasDigitsEntered;
  final Color? okActiveColor;

  const PinKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.onClearPressed,
    required this.onOkPressed,
    this.hasDigitsEntered = false,
    this.okActiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in standardKeypadRows) ...[
          _buildRow(row),
          const SizedBox(height: 10),
        ],
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<KeyData> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildCircleDigitButton(k)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleActionButton(
          icon: Icons.backspace_outlined,
          iconColor: AppTheme.onSurface,
          onTap: onBackspacePressed,
          onLongPress: onClearPressed,
        ),
        _buildCircleDigitButton(const KeyData('0', '+')),
        _buildCircleOkButton(),
      ],
    );
  }

  Widget _buildCircleDigitButton(KeyData keyData) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDigitPressed(keyData.digit),
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
    final activeColor = okActiveColor ?? AppTheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOkPressed,
        borderRadius: BorderRadius.circular(33),
        splashColor: activeColor.withAlpha(40),
        highlightColor: activeColor.withAlpha(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasDigitsEntered ? activeColor : Colors.white,
            border: Border.all(
              color: hasDigitsEntered ? activeColor : AppTheme.outlineVariant,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: hasDigitsEntered
                    ? activeColor.withAlpha(70)
                    : const Color(0xFF0F172A).withAlpha(10),
                blurRadius: hasDigitsEntered ? 6 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'OK',
            style: GoogleFonts.manrope(
              color: hasDigitsEntered ? Colors.white : AppTheme.onSurface,
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

/// 6-dot (or N-dot) animated PIN indicator.
class PinDotsIndicator extends StatelessWidget {
  final int totalDots;
  final int enteredLength;
  final bool hasError;
  final Animation<double>? shakeAnimation;

  const PinDotsIndicator({
    super.key,
    this.totalDots = 6,
    required this.enteredLength,
    this.hasError = false,
    this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isFilled = index < enteredLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (hasError ? AppTheme.error : AppTheme.primary)
                : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppTheme.error
                  : (isFilled ? AppTheme.primary : AppTheme.outlineLight),
              width: 2.2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: (hasError ? AppTheme.error : AppTheme.primary)
                          .withAlpha(80),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );

    if (shakeAnimation != null) {
      return AnimatedBuilder(
        animation: shakeAnimation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(shakeAnimation!.value, 0),
            child: child,
          );
        },
        child: content,
      );
    }

    return content;
  }
}
