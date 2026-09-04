import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// One UI Capsule Search Bar for filtering applications.
class ApplicationSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ApplicationSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.manrope(
          fontSize: 14,
          color: AppTheme.onSurface,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search apps...',
          hintStyle: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.mutedSteel,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.mutedSteel,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
