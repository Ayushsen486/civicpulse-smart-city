# CivicPulse — Citizen & Field Officer Mobile App

CivicPulse App is the mobile application for citizens and municipal field officers, built with Flutter, Riverpod, and Clean Architecture.

---

## 1. Architecture & Tech Stack

- **Flutter SDK**: 3.36+ / Dart 3.10+
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod` 3.x with `AsyncNotifier` & `FutureProvider`)
- **Routing**: [go_router](https://pub.dev/packages/go_router) (declarative deep-linkable routing)
- **HTTP Client**: [Dio](https://pub.dev/packages/dio) with auto token refresh interceptor (`JwtInterceptor`)
- **Secure Storage**: `flutter_secure_storage` for JWT access and refresh token persistence
- **Architecture**: Feature-first Clean Architecture (`presentation` → `application` → `domain` → `data`)
- **Localization**: Native Flutter ARB (`app_en.arb` and `app_hi.arb`) supporting English and Hindi
- **Design Tokens**: Material 3 theme with Inter & Outfit typography via Google Fonts

---

## 2. Directory Structure

```
civicpulse-app/
├── lib/
│   ├── app.dart                       # Main app widget with Theme and GoRouter config
│   ├── main.dart                      # App entry point with ProviderScope
│   ├── core/
│   │   ├── constants/api_endpoints.dart # Backend REST paths
│   │   ├── network/                   # DioClient, JwtInterceptor
│   │   ├── router/app_router.dart     # GoRouter configuration
│   │   ├── storage/token_storage.dart # Secure token persistence
│   │   └── theme/                     # AppColors, AppTypography, AppTheme
│   ├── features/
│   │   ├── auth/                      # Login, Register, AuthController, UserModel
│   │   ├── home/                      # HomeScreen with bottom navigation bar
│   │   └── issue/                     # Feed, Report with AI suggestions, Detail, My Reports
│   └── l10n/                          # app_en.arb, app_hi.arb, AppLocalizations
└── test/
    ├── domain_model_test.dart         # Unit tests for JSON serialization
    ├── login_screen_test.dart         # Widget test for login screen
    └── widget_test.dart               # App smoke test
```

---

## 3. Key Features

1. **Authentication Flow**:
   - Secure login and registration with validation.
   - Dual JWT tokens (Access + Refresh).
   - Silent token rotation on HTTP 401 via `JwtInterceptor`.

2. **Civic Feed**:
   - Live stream of issues reported by citizens.
   - Upvote / endorse functionality with real-time counters.
   - Filtering by category and search query.

3. **Issue Reporting with AI Copilot**:
   - Interactive issue creation with GPS geotagging.
   - Real-time debounced AI draft analysis calling `/api/v1/intelligence/draft-suggestion`.
   - 1-click adoption of AI suggested categories, departments, and urgency levels.

4. **Issue Detail & Tracking**:
   - Full timeline audit (Reported, Assigned, In Progress, Resolved).
   - SLA tracking and status badges.
   - Real-time upvoting and comments.

5. **Internationalization (i18n)**:
   - Full support for English and Hindi (हिंदी).

---

## 4. Running Locally

Ensure backend is running on `http://localhost:8080`:

```bash
# Get dependencies
flutter pub get

# Generate localizations
flutter gen-l10n

# Run static analysis (zero warnings target)
flutter analyze

# Run automated tests
flutter test

# Run app
flutter run
```
