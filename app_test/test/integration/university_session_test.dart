import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_test/session/university_session_store.dart';


void main() {
  group('Integration - UniversitySessionStore Persistence', () {
    late UniversitySessionStore sessionStore;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sessionStore = UniversitySessionStore();
    });

    test('SESS-IT2: O método clear() deve limpar fisicamente o disco', () async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up123',
      });

      await sessionStore.clear();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().isEmpty, isTrue, reason: 'O disco deve estar vazio após o clear');
    });
  });
}