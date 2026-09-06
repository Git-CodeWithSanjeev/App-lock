import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// One UI Settings Section with labeled header and rounded container card.
class SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const SettingsSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.mutedSteel,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: AppTheme.cardDecoration(borderRadius: 24),
          child: child,
        ),
      ],
    );
  }
}
