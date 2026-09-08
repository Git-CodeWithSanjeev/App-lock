import 'package:flutter/material.dart';
import 'app/app.dart';
export 'app/app.dart';
import 'app/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/platform/app_lock_channel.dart';
import 'data/repositories/app_lock_repository.dart';
import 'features/lock_overlay/views/lock_overlay.dart';

/// Primary Application Entrypoint
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline repository and synchronize locked apps with native Android
  final repo = AppLockRepository.instance;
  await repo.init();

  // Asynchronously start loading installed apps
  repo.loadInstalledApplications();

  // Determine initial route based on permissions and PIN setup
  final hasPermissions = await _checkInitialPermissions();
  final hasPin = repo.hasSetPin();

  String initialRoute = AppRoutes.home;
  if (!hasPermissions) {
    initialRoute = AppRoutes.permissions;
  } else if (!hasPin) {
    initialRoute = AppRoutes.createPin;
  }

  runApp(ScreenLockApp(initialRoute: initialRoute));
}

Future<bool> _checkInitialPermissions() async {
  final usage = await AppLockChannel.hasUsageStatsPermission();
  final overlay = await AppLockChannel.hasOverlayPermission();
  return usage && overlay;
}

/// Overlay Window Entrypoint.
///
/// Designated via `@pragma("vm:entry-point")` so the Flutter Engine can execute
/// this top-level function directly inside Android's TYPE_APPLICATION_OVERLAY window.
/// This renders the lock screen directly over third-party applications without
/// routing through the standard Android Activity navigation stack.
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppLockRepository.instance.init();
  } catch (e) {
    debugPrint('overlayMain repo init note: $e');
  }
  runApp(const LockOverlayApp());
}

/// Standalone lightweight app container for the Lock Screen Overlay.
class LockOverlayApp extends StatelessWidget {
  const LockOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LockOverlay(),
    );
  }
}
