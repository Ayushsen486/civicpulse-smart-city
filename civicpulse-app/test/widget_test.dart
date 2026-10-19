import 'package:civicpulse_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CivicPulseApp renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CivicPulseApp(),
      ),
    );

    // Initial frame renders and routes to splash / home
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(seconds: 6));

    expect(find.byType(CivicPulseApp), findsOneWidget);
  });
}
