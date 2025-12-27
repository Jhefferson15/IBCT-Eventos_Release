# Professional Testing System - IBCT-Eventos

This directory contains the automated test suite for the IBCT-Eventos application. We follow a Clean Architecture approach to testing, ensuring reliability, scalability, and ease of maintenance.

## 🏗️ Structure

- `test/unit/`:
  - `core/`: Tests for application-wide utilities, validators, and shared logic.
  - `features/`: Tests for specific features, mirrored from `lib/features/`.
    - `[feature_name]/domain/`: Unit tests for Use Cases.
    - `[feature_name]/data/`: Unit tests for Repositories and Data Sources (using fakes).
    - `[feature_name]/presentation/`: Unit tests for Notifiers/Controllers (using `riverpod_test`).
- `test/widget/`: UI-level tests for individual widgets and complex screens.
- `test/integration/`: End-to-end tests for critical user flows.
- `test/mocks/`: Shared mock classes and fakes (Firebase, User, etc.).
- `test/utils/`: Testing helpers and reusable Provider overrides.

## 🚀 How to Run Tests

### Run all tests
```bash
flutter test
```

### Run tests with coverage
```bash
flutter test --coverage
# To view coverage (requires lcov):
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run a specific test file
```bash
flutter test test/unit/features/survey/domain/usecases/submit_survey_usecase_test.dart
```

## 🛠️ Key Libraries & Tools

- **[mocktail](https://pub.dev/packages/mocktail)**: For creating mocks without boilerplate.
- **[mocktail](https://pub.dev/packages/mocktail)**: For creating mocks without boilerplate.
- **[fake_cloud_firestore](https://pub.dev/packages/fake_cloud_firestore)**: In-memory Firestore for reliable data layer testing.
- **[firebase_auth_mocks](https://pub.dev/packages/firebase_auth_mocks)**: Simulating authentication states.

## 📝 Best Practices

1. **AAA Pattern**: Always follow *Arrange, Act, Assert*.
2. **Standard Provider Container**: Use `createContainer` from `test/utils/test_utils.dart` to isolate provider tests.
   > [!IMPORTANT]
   > **DO NOT USE `riverpod_test`**. For compatibility and better lifecycle control, we use a manual `ProviderContainer` approach via `createContainer()`.
3. **Fakes over Mocks**: Use `fake_cloud_firestore` instead of mocking complex Firestore interactions.
4. **Descriptive Names**: Use `group()` and `test()` with clear, human-readable descriptions.
5. **No Network**: Tests should never reach out to real external services.


