import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_test/session/university_session_store.dart';
import 'package:app_test/sigarra/sigarra_auth_service.dart';
import 'package:app_test/ride4free_api.dart';

void main() {
  group('Integration - UniversitySessionStore Persistence', () {
    late UniversitySessionStore sessionStore;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sessionStore = UniversitySessionStore();
    });

    test('SESS-IT1: Deve persistir e recuperar a identidade completa', () async {
      final identity = UniversityIdentity(
        username: 'up2024001',
        displayName: 'João Silva',
        photoUrl: 'https://sigarra.up.pt/foto.jpg',
      );

      // Simulamos que o backend respondeu OK (precisamos de token para não crashar)
      Ride4FreeAuth.token = 'mock_token';

      // Guardar
      await sessionStore.markLoggedIn(identity);

      // Recuperar noutra instância (simulando restart da app)
      final newStore = UniversitySessionStore();
      final savedIdentity = await newStore.identity();

      expect(savedIdentity?.username, 'up2024001');
      expect(savedIdentity?.displayName, 'João Silva');
      expect(savedIdentity?.photoUrl, 'https://sigarra.up.pt/foto.jpg');
      expect(await newStore.isLoggedIn(), isTrue);
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