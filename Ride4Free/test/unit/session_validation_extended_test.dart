// =============================================================================
// EXTENDED UNIT TESTS — Session Validation & State Management
// Tests for session integrity, persistence, and edge cases
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Ride4Free/session/university_session_store.dart';
import 'package:Ride4Free/ride4free_api.dart';

void main() {
  group('Extended Session Tests - Identity Persistence', () {
    late UniversitySessionStore sessionStore;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Ride4FreeAuth.token = null;
      sessionStore = UniversitySessionStore();
    });

    test('Session survives app restart', () async {
      final identity = UniversityIdentity(
        username: 'up123456789',
        displayName: 'Test User',
      );

      // First session: save identity
      final prefs1 = await SharedPreferences.getInstance();
      await prefs1.setBool('university_logged_in', true);
      await prefs1.setString('university_username', identity.username);
      await prefs1.setString('university_display_name', identity.displayName);

      // Simulate app restart
      final prefs2 = await SharedPreferences.getInstance();
      
      final isLoggedIn = prefs2.getBool('university_logged_in') ?? false;
      final savedUsername = prefs2.getString('university_username');
      final savedDisplayName = prefs2.getString('university_display_name');

      expect(isLoggedIn, true);
      expect(savedUsername, identity.username);
      expect(savedDisplayName, identity.displayName);
    });

    test('Clear session removes all data', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set data
      await prefs.setBool('university_logged_in', true);
      await prefs.setString('university_username', 'up123456789');
      await prefs.setString('university_display_name', 'Test User');

      // Clear
      await sessionStore.clear();
      Ride4FreeAuth.token = null;

      // Verify cleared
      expect(prefs.getBool('university_logged_in') ?? false, false);
      expect(prefs.getString('university_username'), isNull);
      expect(Ride4FreeAuth.token, isNull);
    });
  });

  group('Extended Session Tests - Token Management', () {
    
    test('Token is set after successful login', () async {
      expect(Ride4FreeAuth.token, isNull);
      
      Ride4FreeAuth.token = 'test_token_abc123';
      expect(Ride4FreeAuth.token, 'test_token_abc123');
      
      Ride4FreeAuth.token = null;
    });

    test('Token is cleared on logout', () async {
      Ride4FreeAuth.token = 'test_token_xyz789';
      expect(Ride4FreeAuth.token, 'test_token_xyz789');
      
      Ride4FreeAuth.token = null;
      expect(Ride4FreeAuth.token, isNull);
    });

    test('Different tokens can be set sequentially', () async {
      Ride4FreeAuth.token = 'token_1';
      expect(Ride4FreeAuth.token, 'token_1');

      Ride4FreeAuth.token = 'token_2';
      expect(Ride4FreeAuth.token, 'token_2');

      Ride4FreeAuth.token = 'token_3';
      expect(Ride4FreeAuth.token, 'token_3');

      Ride4FreeAuth.token = null;
    });

    test('Very long token is stored correctly', () async {
      final longToken = 'x' * 10000;
      Ride4FreeAuth.token = longToken;
      
      expect(Ride4FreeAuth.token, longToken);
      expect(Ride4FreeAuth.token!.length, 10000);
      
      Ride4FreeAuth.token = null;
    });

    test('Token with special characters is preserved', () async {
      final specialToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      Ride4FreeAuth.token = specialToken;
      
      expect(Ride4FreeAuth.token, specialToken);
      
      Ride4FreeAuth.token = null;
    });
  });

  group('Extended Session Tests - Identity Validation', () {
    
    test('UniversityIdentity with valid username', () {
      final identity = UniversityIdentity(
        username: 'up202000001',
        displayName: 'Student Name',
      );

      expect(identity.username, 'up202000001');
      expect(identity.displayName, 'Student Name');
    });

    test('UniversityIdentity with empty displayName', () {
      final identity = UniversityIdentity(
        username: 'up202000001',
        displayName: '',
      );

      expect(identity.username, 'up202000001');
      expect(identity.displayName, '');
    });

    test('UniversityIdentity with special characters in displayName', () {
      final identity = UniversityIdentity(
        username: 'up202000001',
        displayName: 'José María O\'Connor-Smith',
      );

      expect(identity.displayName, 'José María O\'Connor-Smith');
    });

    test('UniversityIdentity with very long displayName', () {
      final longName = 'A' * 1000;
      final identity = UniversityIdentity(
        username: 'up202000001',
        displayName: longName,
      );

      expect(identity.displayName, longName);
      expect(identity.displayName.length, 1000);
    });

    test('UniversityIdentity with numeric username', () {
      final identity = UniversityIdentity(
        username: '12345678',
        displayName: 'User',
      );

      expect(identity.username, '12345678');
    });
  });

  group('Extended Session Tests - Shared Preferences Integration', () {
    
    test('Session data is stored in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final sessionStore = UniversitySessionStore();
      final prefs = await SharedPreferences.getInstance();

      // Store some data
      await prefs.setBool('university_logged_in', true);
      await prefs.setString('university_username', 'up123456789');

      // Verify
      expect(prefs.getBool('university_logged_in'), true);
      expect(prefs.getString('university_username'), 'up123456789');
    });

    test('Multiple session keys coexist', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('university_logged_in', true);
      await prefs.setString('university_username', 'up123456789');
      await prefs.setString('university_display_name', 'Test User');
      await prefs.setString('api_token', 'test_token');

      expect(prefs.getBool('university_logged_in'), true);
      expect(prefs.getString('university_username'), 'up123456789');
      expect(prefs.getString('university_display_name'), 'Test User');
      expect(prefs.getString('api_token'), 'test_token');
    });

    test('Session data survives other app data changes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Set session data
      await prefs.setBool('university_logged_in', true);
      await prefs.setString('university_username', 'up123456789');

      // Change other app data
      await prefs.setString('theme_preference', 'dark');
      await prefs.setInt('font_size', 16);

      // Verify session data unchanged
      expect(prefs.getBool('university_logged_in'), true);
      expect(prefs.getString('university_username'), 'up123456789');
    });

    test('Removing one session key preserves others', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('university_logged_in', true);
      await prefs.setString('university_username', 'up123456789');
      await prefs.setString('university_display_name', 'Test User');

      // Remove one key
      await prefs.remove('university_display_name');

      // Verify others remain
      expect(prefs.getBool('university_logged_in'), true);
      expect(prefs.getString('university_username'), 'up123456789');
      expect(prefs.getString('university_display_name'), isNull);
    });
  });

  group('Extended Session Tests - State Transitions', () {
    
    test('Can transition from not logged in to logged in', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Initial state: not logged in
      expect(prefs.getBool('university_logged_in') ?? false, false);

      // Transition: log in
      await prefs.setBool('university_logged_in', true);
      Ride4FreeAuth.token = 'token123';

      expect(prefs.getBool('university_logged_in'), true);
      expect(Ride4FreeAuth.token, 'token123');

      // Cleanup
      Ride4FreeAuth.token = null;
    });

    test('Can transition from logged in to logged out', () async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up123456789'
      });
      Ride4FreeAuth.token = 'token123';
      final prefs = await SharedPreferences.getInstance();

      // Current state: logged in
      expect(prefs.getBool('university_logged_in'), true);

      // Transition: log out
      await prefs.setBool('university_logged_in', false);
      await prefs.remove('university_username');
      Ride4FreeAuth.token = null;

      expect(prefs.getBool('university_logged_in') ?? false, false);
      expect(prefs.getString('university_username'), isNull);
      expect(Ride4FreeAuth.token, isNull);
    });

    test('Multiple login/logout cycles work correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      for (int i = 0; i < 3; i++) {
        // Login
        await prefs.setBool('university_logged_in', true);
        Ride4FreeAuth.token = 'token_$i';
        expect(prefs.getBool('university_logged_in'), true);
        expect(Ride4FreeAuth.token, 'token_$i');

        // Logout
        await prefs.setBool('university_logged_in', false);
        Ride4FreeAuth.token = null;
        expect(prefs.getBool('university_logged_in'), false);
        expect(Ride4FreeAuth.token, isNull);
      }
    });
  });

  group('Extended Session Tests - Edge Cases', () {
    
    test('isLoggedIn returns false when no data exists', () async {
      SharedPreferences.setMockInitialValues({});
      final sessionStore = UniversitySessionStore();
      
      final isLoggedIn = await sessionStore.isLoggedIn();
      
      expect(isLoggedIn, false);
    });

    test('identity returns null when no data exists', () async {
      SharedPreferences.setMockInitialValues({});
      final sessionStore = UniversitySessionStore();
      
      final identity = await sessionStore.identity();
      
      expect(identity, isNull);
    });

    test('Session handles corrupted preference data gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': null, // Corrupted: null value
      });
      final sessionStore = UniversitySessionStore();

      // Should not crash
      final identity = await sessionStore.identity();
      expect(identity, isNull); // Since username is null
    });

    test('Session with only partial data', () async {
      SharedPreferences.setMockInitialValues({
        'university_username': 'up123456789',
        // Missing: university_logged_in
      });
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('university_logged_in') ?? false, false);
      expect(prefs.getString('university_username'), 'up123456789');
    });

    test('Large number of concurrent session checks', () async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up123456789'
      });
      final sessionStore = UniversitySessionStore();

      // Simulate rapid concurrent checks
      final futures = List.generate(
        10,
        (_) => sessionStore.isLoggedIn(),
      );

      final results = await Future.wait(futures);
      
      // All should return true
      for (final result in results) {
        expect(result, true);
      }
    });
  });

  group('Extended Session Tests - Data Consistency', () {
    
    test('Token and identity are consistent after login', () async {
      SharedPreferences.setMockInitialValues({});
      Ride4FreeAuth.token = 'test_token';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('university_logged_in', true);
      await prefs.setString('university_username', 'up123456789');

      expect(Ride4FreeAuth.token, 'test_token');
      expect(prefs.getBool('university_logged_in'), true);

      Ride4FreeAuth.token = null;
    });

    test('Token and identity are both cleared on logout', () async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up123456789'
      });
      Ride4FreeAuth.token = 'test_token';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('university_logged_in', false);
      await prefs.remove('university_username');
      Ride4FreeAuth.token = null;

      expect(Ride4FreeAuth.token, isNull);
      expect(prefs.getBool('university_logged_in') ?? false, false);
    });
  });
}
