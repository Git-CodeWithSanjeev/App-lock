import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_lock_switch.dart';
import '../../../../data/models/application_info.dart';

/// Clean Samsung One UI–inspired application list tile.
class ApplicationTile extends StatelessWidget {
  final ApplicationInfo app;
  final ValueChanged<bool> onToggle;

  const ApplicationTile({
    super.key,
    required this.app,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: app.isLocked
              ? AppTheme.primary.withAlpha(50)
              : AppTheme.outlineVariant,
          width: 1.0,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 44,
              height: 44,
              child: app.iconBytes != null
                  ? Image.memory(
                      app.iconBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackIcon(),
                    )
                  : _buildFallbackIcon(),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        app.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (app.isKnoxProtected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.blueBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'KNOX',
                          style: GoogleFonts.manrope(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  app.packageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.mutedSteel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          AppLockSwitch(
            value: app.isLocked,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: AppTheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: const Icon(Icons.android_rounded,
          color: AppTheme.mutedSteel, size: 24),
    );
  }
}

/// Backward compatibility alias
typedef AppListTile = ApplicationTile;
