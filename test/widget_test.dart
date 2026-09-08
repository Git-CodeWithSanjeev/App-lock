import 'package:flutter_test/flutter_test.dart';
import 'package:screen_lock/main.dart';

void main() {
  testWidgets('ScreenLockApp loads initial route smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with a predefined route
    await tester.pumpWidget(const ScreenLockApp(initialRoute: '/home'));
    expect(find.byType(ScreenLockApp), findsOneWidget);
  });
}
