import 'package:civicpulse_app/app.dart';
import 'package:civicpulse_app/features/issue/application/issue_controller.dart';
import 'package:civicpulse_app/features/issue/domain/issue_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CivicPulseApp renders without errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          issueListProvider.overrideWith((ref) => Future.value(<IssueModel>[])),
          categoriesProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const CivicPulseApp(),
      ),
    );

    // Initial frame renders and routes to splash / home
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CivicPulseApp), findsOneWidget);
  });
}
