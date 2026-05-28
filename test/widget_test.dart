import 'package:flutter_test/flutter_test.dart';
import 'package:kaakiscan/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KaakiScanApp());

    // Verify that the splash screen shows KaakiScan text
    expect(find.text('KaakiScan'), findsOneWidget);

    // Let the timer finish and transition to login screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
