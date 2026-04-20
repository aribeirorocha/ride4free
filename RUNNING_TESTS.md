# Running Tests - Quick Guide

## Setup

### Backend (Python)
```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Run all backend tests
pytest -v

# Run specific test file
pytest test_database.py -v
pytest test_main.py -v

# Run with coverage
pytest --cov=database --cov=main --cov-report=term-missing
```

### Frontend (Flutter)
```bash
cd app_test

# Run all tests
flutter test

# Run specific test file
flutter test test/widget_tests.dart
flutter test test/api_client_test.dart
flutter test test/unit_test.dart

# Run with coverage
flutter test --coverage
```

## Test Files Overview

### Python Backend
- **`test_database.py`** (142 tests)
  - Password hashing and verification
  - User management (registration, login, sessions)
  - Passenger requests (CRUD operations)
  - Driver offers (CRUD operations)
  - Ride bookings (validation and constraints)
  - Community board listings
  - Database schema exposure

- **`test_main.py`** (60+ tests)
  - Health check endpoint
  - User authentication endpoints
  - Profile endpoints
  - Passenger request endpoints
  - Driver offer endpoints
  - Community board endpoints
  - Booking endpoints
  - Database schema endpoint

### Dart/Flutter Frontend
- **`test/api_client_test.dart`** (20+ tests)
  - API client configuration
  - User model serialization
  - Authentication token management
  - Exception handling
  - URL construction

- **`test/widget_tests.dart`** (50+ tests)
  - SearchRidePage UI and interactions
  - ProfilePage UI and forms
  - CommunityBoardPage tab switching
  - OfferRidePage seat picker and rewards
  - Navigation flow between tabs

- **`test/unit_test.dart`** (existing)
  - Profile model tests
  - Reward calculation logic
  - Seat validation
  - Initials calculation
  - API configuration

- **`test/home_shell_unit_test.dart`** (existing)
  - Navigation tests
  - Seat picker tests

- **`test/integration_test.dart`** (existing)
  - Full search page flows
  - Rating system flows

- **`test/*_acceptance_test.dart`** (existing)
  - US1: Publish Ride
  - US2: Booking Ride
  - US3: Rating System
  - US4: Search Ride

## Test Categories

### Unit Tests (70+)
Focus on individual functions and classes:
- Profile model functionality
- Password hashing and verification
- Destination normalization
- Reward calculations
- API configuration

### Integration Tests (200+)
Focus on component interactions:
- User registration and authentication flow
- Complete booking workflows
- Database transactions
- API endpoint integrations
- Widget interactions

## Running Tests by Category

### Run only unit tests
```bash
# Backend
cd backend && pytest -k "test_hash" -v

# Frontend
cd app_test && flutter test --plain-name "Unit" -v
```

### Run only integration tests
```bash
# Backend
cd backend && pytest test_main.py -v

# Frontend
cd app_test && flutter test test/integration_test.dart -v
```

## Checking Test Coverage

### Backend
```bash
cd backend
pytest --cov=database --cov=main --cov-report=html --cov-report=term-missing

# View HTML report
# open htmlcov/index.html
```

### Frontend
```bash
cd app_test
flutter test --coverage
lcov --list coverage/lcov.info  # View coverage summary
```

## Troubleshooting

### Backend Tests Fail
1. Ensure Python 3.8+ is installed: `python --version`
2. Install dependencies: `pip install -r requirements.txt`
3. Check for port conflicts (8000 should be free)
4. Verify test database cleanup: `rm -f ride4free.db*`

### Frontend Tests Fail
1. Ensure Flutter is properly installed: `flutter doctor`
2. Get dependencies: `flutter pub get`
3. Run clean build: `flutter clean && flutter pub get`
4. Check for emulator/device connection (not needed for widget tests)

## Test Results Interpretation

### Backend
- ✅ All tests pass: System is ready for deployment
- ⚠️ Some warnings: Non-blocking issues
- ❌ Failed tests: Must be fixed before deployment

### Frontend
- ✅ Green checks: Widget tests passing
- ⚠️ Skipped tests: Tests that don't apply to current setup
- ❌ Red X: Tests must be fixed

## Example Output

```
backend tests:
===== test session starts =====
collected 202 tests

test_database.py::TestPasswordHashingAndVerification::test_hash_password_creates_salted_hash PASSED
test_database.py::TestPasswordHashingAndVerification::test_verify_password_correct PASSED
...
test_main.py::TestUserRegistration::test_register_success PASSED
...

===== 202 passed in 12.34s =====

frontend tests:
$ flutter test
Running "flutter test" in T4/app_test...
test/unit_test.dart: +28 -0                                                    [✓]
test/api_client_test.dart: +20 -0                                              [✓]
test/widget_tests.dart: +50 -0                                                 [✓]
...
All tests passed!
```

## Adding New Tests

### Backend (pytest)
```python
def test_new_feature(client):
    """Test description in plain English."""
    response = client.post("/endpoint", json={"key": "value"})
    assert response.status_code == 200
    assert response.json()["field"] == "expected"
```

### Frontend (Flutter)
```dart
testWidgets('WX-1: Description of test', (tester) async {
  await tester.pumpWidget(const TestWidget());
  expect(find.text('Expected text'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.example));
  await tester.pumpAndSettle();
  expect(find.text('After tap'), findsOneWidget);
});
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Run Backend Tests
  run: cd backend && pip install -r requirements.txt && pytest -v

- name: Run Frontend Tests
  run: cd app_test && flutter test
```

### GitLab CI
```yaml
test_backend:
  script:
    - cd backend
    - pip install -r requirements.txt
    - pytest -v

test_frontend:
  script:
    - cd app_test
    - flutter test
```

## Performance

Expected test execution times:
- Backend tests: ~15-30 seconds
- Frontend widget tests: ~30-45 seconds
- Full suite: ~1-2 minutes

## Visual Testing

View test coverage reports:
```bash
# Backend
cd backend && pytest --cov=database --cov=main --cov-report=html
# Then open htmlcov/index.html in browser

# Frontend
cd app_test && flutter test --coverage
# Check coverage/lcov.info file
```

## Test Data

Tests use isolated, temporary environments:
- **Backend**: New SQLite database per test session
- **Frontend**: Widget tests with mock data

No test data persists after tests complete.

---

For detailed test information, see [TEST_SUITE_SUMMARY.md](TEST_SUITE_SUMMARY.md)
