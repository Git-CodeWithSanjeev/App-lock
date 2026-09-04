import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/application_filter.dart';

/// One UI Filter Bar containing selection pills with counts.
class ApplicationFilterBar extends StatelessWidget {
  final ApplicationFilter currentFilter;
  final int allCount;
  final int lockedCount;
  final ValueChanged<ApplicationFilter> onFilterChanged;

  const ApplicationFilterBar({
    super.key,
    required this.currentFilter,
    required this.allCount,
    required this.lockedCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildFilterPill(
          label: 'All',
          count: allCount,
          isSelected: currentFilter == ApplicationFilter.all,
          onTap: () => onFilterChanged(ApplicationFilter.all),
        ),
        const SizedBox(width: 8),
        _buildFilterPill(
          label: 'Locked',
          count: lockedCount,
          isSelected: currentFilter == ApplicationFilter.locked,
          onTap: () => onFilterChanged(ApplicationFilter.locked),
        ),
      ],
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primary : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(50)
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.mutedSteel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
