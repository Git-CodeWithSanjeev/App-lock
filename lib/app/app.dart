import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import 'app_bindings.dart';
import 'app_pages.dart';
import 'app_routes.dart';

/// Root Application Widget for the Porcelain Guardian UI.
class ScreenLockApp extends StatelessWidget {
  final String initialRoute;

  const ScreenLockApp({super.key, this.initialRoute = AppRoutes.home});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Porcelain Guardian - App Lock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: AppBindings(),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
    );
  }
}
