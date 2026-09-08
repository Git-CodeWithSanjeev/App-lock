import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:screen_lock/core/constants/app_constants.dart';
import 'package:screen_lock/data/repositories/app_lock_repository.dart';
import 'package:screen_lock/features/app_lock/controllers/app_lock_controller.dart';
import 'package:screen_lock/features/applications/controllers/applications_controller.dart';
import 'package:screen_lock/features/applications/views/applications_screen.dart';
import 'package:screen_lock/features/authentication/controllers/authentication_controller.dart';
import 'package:screen_lock/features/authentication/views/authentication_gate.dart';
import 'package:screen_lock/features/authentication/views/create_pin_screen.dart';
import 'package:screen_lock/features/authentication/views/lock_screen.dart';
import 'package:screen_lock/features/lock_overlay/views/lock_overlay.dart';
import 'package:screen_lock/features/settings/controllers/settings_controller.dart';
import 'package:screen_lock/features/settings/views/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLock PIN Validation & Security Tests', () {
    final repo = AppLockRepository.instance;

    test('Initial PIN verification validates against default PIN', () {
      expect(repo.verifyPin(AppConstants.defaultPin), isTrue);
      expect(repo.verifyPin('000000'), isFalse);
      expect(repo.verifyPin('111111'), isFalse);
      expect(repo.verifyPin('999999'), isFalse);
      expect(repo.verifyPin('12345'), isFalse);
    });

    test('Configured user PIN strictly validates and rejects invalid codes', () {
      repo.settings.value = repo.settings.value.copyWith(pinHash: '849201');

      // Only the user's configured PIN must be accepted
      expect(repo.verifyPin('849201'), isTrue);

      // Any other code must be rejected
      expect(repo.verifyPin('123456'), isFalse);
      expect(repo.verifyPin('849200'), isFalse);
      expect(repo.verifyPin('849202'), isFalse);
      expect(repo.verifyPin('000000'), isFalse);
    });

    test('Lock and unlock package sets work predictably', () {
      repo.lockedPackages.value = {'com.whatsapp', 'com.instagram.android'};

      expect(repo.lockedPackages.value.contains('com.whatsapp'), isTrue);
      expect(repo.lockedPackages.value.contains('com.instagram.android'), isTrue);
      expect(repo.lockedPackages.value.contains('com.android.chrome'), isFalse);
    });
  });

  group('Home Screen Responsiveness Tests', () {
    testWidgets('HomeScreen renders without RenderFlex overflow on 360x640 screen with high font scale',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Get.reset();
      });

      Get.put(AppLockController());
      Get.put(SettingsController());
      Get.put(AppListController());
      Get.put(PinController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('App Lock'), findsOneWidget);
    });
  });

  group('Recent Apps Privacy & Settings Tests', () {
    final repo = AppLockRepository.instance;

    test('Recent apps privacy defaults to enabled and updates correctly', () {
      expect(repo.settings.value.recentAppsPrivacy, isTrue);

      repo.settings.value = repo.settings.value.copyWith(recentAppsPrivacy: false);
      expect(repo.settings.value.recentAppsPrivacy, isFalse);

      repo.settings.value = repo.settings.value.copyWith(recentAppsPrivacy: true);
      expect(repo.settings.value.recentAppsPrivacy, isTrue);
    });

    test('Uninstall protection defaults to false and updates correctly', () {
      expect(repo.settings.value.uninstallProtection, isFalse);

      repo.settings.value = repo.settings.value.copyWith(uninstallProtection: true);
      expect(repo.settings.value.uninstallProtection, isTrue);

      repo.settings.value = repo.settings.value.copyWith(uninstallProtection: false);
      expect(repo.settings.value.uninstallProtection, isFalse);
    });

    testWidgets('SettingsScreen renders without RenderFlex overflow and contains Recent Apps Privacy toggle',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Get.reset();
      });

      Get.put(AppLockController());
      Get.put(SettingsController());
      Get.put(AppListController());
      Get.put(PinController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Recent Apps Privacy'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Recent Apps Privacy'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Uninstall Protection'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Uninstall Protection'), findsOneWidget);
    });
  });

  group('AppAuthGateScreen Self-Lock Tests', () {
    setUp(() {
      Get.put(AppLockController());
      Get.put(SettingsController());
      Get.put(AppListController());
      Get.put(PinController());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('AppAuthGateScreen renders lock screen initially and does not reveal MainNavScreen without authentication',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const GetMaterialApp(
          home: AppAuthGateScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('App Lock'), findsOneWidget);
      expect(find.text('Enter Master PIN to continue'), findsOneWidget);
      expect(find.text('Forgot PIN?'), findsOneWidget);

      // MainNavScreen tabs should NOT be visible yet
      expect(find.text('Apps'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('AppAuthGateScreen unlocks and reveals MainNavScreen upon entering correct default PIN',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Ensure default PIN is active
      AppLockRepository.instance.settings.value = AppLockRepository.instance.settings.value.copyWith(
        pinHash: '123456',
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: AppAuthGateScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter digits 1-2-3-4-5-6
      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(d));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();

      // Now MainNavScreen tabs should be revealed!
      expect(find.text('Apps'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('SharedLockScreen & Overlay Consistency Tests', () {
    testWidgets('SharedLockScreen renders third-party app title, subtitle, and keypad properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SharedLockScreen(
              targetPackage: 'com.whatsapp',
              appName: 'WhatsApp',
              onAuthenticated: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unlock WhatsApp'), findsOneWidget);
      expect(find.text('Forgot PIN?'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('SharedLockScreen incorrect PIN displays error and does not authenticate',
        (WidgetTester tester) async {
      bool authenticated = false;

      AppLockRepository.instance.settings.value = AppLockRepository.instance.settings.value.copyWith(
        pinHash: '123456',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SharedLockScreen(
              targetPackage: 'com.whatsapp',
              appName: 'WhatsApp',
              onAuthenticated: () {
                authenticated = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter wrong PIN: 9-9-9-9-9-9
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('9'));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pump();
      expect(authenticated, isFalse);
      expect(find.text('Incorrect PIN. Try again'), findsOneWidget);

      // Settle timer
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    });

    testWidgets('SharedLockScreen correct PIN triggers onAuthenticated exactly once',
        (WidgetTester tester) async {
      int authCount = 0;

      AppLockRepository.instance.settings.value = AppLockRepository.instance.settings.value.copyWith(
        pinHash: '123456',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SharedLockScreen(
              targetPackage: 'com.whatsapp',
              appName: 'WhatsApp',
              onAuthenticated: () {
                authCount++;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(d));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      expect(authCount, equals(1));
    });

    testWidgets('SharedLockScreen reset PIN mode enters and cancels cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SharedLockScreen(
              targetPackage: 'com.whatsapp',
              appName: 'WhatsApp',
              onAuthenticated: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Forgot PIN?
      await tester.tap(find.text('Forgot PIN?'));
      await tester.pumpAndSettle();

      // Should be in Step 1 of PIN reset
      expect(find.text('Step 1/3'), findsOneWidget);
      expect(find.text('Verify Current PIN'), findsOneWidget);
      expect(find.text('Cancel PIN Reset'), findsOneWidget);

      // Tap back arrow to cancel PIN reset
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Should return to normal lock screen
      expect(find.text('Unlock WhatsApp'), findsOneWidget);
      expect(find.text('Forgot PIN?'), findsOneWidget);
    });

    testWidgets('SharedLockScreen OK button validates incomplete PIN and triggers error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SharedLockScreen(
              targetPackage: 'com.whatsapp',
              appName: 'WhatsApp',
              onAuthenticated: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap OK with 0 digits entered
      await tester.tap(find.text('OK'));
      await tester.pump();
      expect(find.text('Enter your 6-digit PIN'), findsOneWidget);

      // Enter 3 digits: 1-2-3
      for (final d in ['1', '2', '3']) {
        await tester.tap(find.text(d));
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Tap OK with 3 digits
      await tester.tap(find.text('OK'));
      await tester.pump();
      expect(find.text('PIN must be 6 digits'), findsOneWidget);

      // Tap backspace to delete '3'
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      // Tap remaining digits to complete 6 digits
      for (final d in ['3', '4', '5', '6']) {
        await tester.tap(find.text(d));
        await tester.pump(const Duration(milliseconds: 50));
      }
    });

    testWidgets('LockOverlayScreen renders on 360x640 screen without RenderFlex overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: LockOverlayScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SharedLockScreen), findsOneWidget);
    });

    testWidgets('CreatePinScreen renders circular numpad and advances step upon 6 digits',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CreatePinScreen(isInitialSetup: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Your PIN'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Tap OK with 0 digits
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter all 6 digits.'), findsOneWidget);

      // Enter digits 1 through 6
      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(d));
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpAndSettle();

      // Should now be on Step 2
      expect(find.text('Confirm Your PIN'), findsOneWidget);
      expect(find.text('Step 2 of 2'), findsOneWidget);
    });
  });
}

