import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civicpulse_app/features/auth/application/auth_controller.dart';
import 'package:civicpulse_app/features/auth/domain/user_model.dart';
import 'package:civicpulse_app/features/auth/presentation/login_screen.dart';
import 'package:civicpulse_app/l10n/app_localizations.dart';

class MockAuthController extends AuthController {
  @override
  FutureOr<UserModel?> build() => null;
}

void main() {
  testWidgets('LoginScreen renders Google Sign-In and toggleable municipal credentials', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => MockAuthController()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify Google Sign-In button exists prominently
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(GoogleLogoWidget), findsOneWidget);

    // Expand email fallback
    final toggleButton = find.text('Sign In with Email / Staff Credentials');
    expect(toggleButton, findsOneWidget);
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Verify email, password fields and sign in button appear
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign In with Email'), findsOneWidget);
  });
}
