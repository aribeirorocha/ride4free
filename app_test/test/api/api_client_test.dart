import 'package:app_test/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_test/ride4free_api.dart';

void main() {
  group('Ride4FreeApi - Configuration Tests', () {
    setUp(() {
      Ride4FreeAuth.token = null;
    });

    tearDown(() {
      Ride4FreeAuth.token = null;
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Configuration Tests
    // ─────────────────────────────────────────────────────────────────────────

    group('API Configuration', () {
      test('API-CFG-1: baseUrl construction includes port', () {
        expect(Ride4FreeConfig.baseUrl, contains(':'));
        // Should be localhost:8000 or 10.0.2.2:8000 or similar
      });

      test('API-CFG-2: baseUrl handles different platforms', () {
        final baseUrl = Ride4FreeConfig.baseUrl;
        expect(baseUrl, startsWith('http'));
      });

      test('API-CFG-3: baseUrl is not empty', () {
        expect(Ride4FreeConfig.baseUrl, isNotEmpty);
      });
    });
  });

  group('Ride4FreeUser Model', () {
    test('API-USER-1: fromJson creates user from JSON', () {
      final json = {'id': 42, 'email': 'test@example.com', 'name': 'Test User'};
      final user = Ride4FreeUser.fromJson(json);

      expect(user.id, 42);
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
    });

    test('API-USER-2: user properties are accessible', () {
      final user = Ride4FreeUser(id: 1, email: 'test@example.com', name: 'Test');
      
      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test');
    });

    test('API-USER-3: two users with same data have same properties', () {
      final user1 = Ride4FreeUser(id: 1, email: 'test@example.com', name: 'Test');
      final user2 = Ride4FreeUser(id: 1, email: 'test@example.com', name: 'Test');

      expect(user1.id, user2.id);
      expect(user1.email, user2.email);
      expect(user1.name, user2.name);
    });
  });

  group('Ride4FreeAuth Token Management', () {
    test('API-AUTH-1: token initially can be null', () {
      Ride4FreeAuth.token = null;
      expect(Ride4FreeAuth.token, isNull);
    });

    test('API-AUTH-2: token can be set and retrieved', () {
      Ride4FreeAuth.token = 'test_token_123';
      expect(Ride4FreeAuth.token, 'test_token_123');
    });

    test('API-AUTH-3: token can be cleared', () {
      Ride4FreeAuth.token = 'test_token_123';
      Ride4FreeAuth.token = null;
      expect(Ride4FreeAuth.token, isNull);
    });
  });

  group('Ride4FreeApiException', () {
    test('API-EXC-1: exception stores status code and body', () {
      final exc = Ride4FreeApiException(404, 'Not found');
      expect(exc.statusCode, 404);
      expect(exc.body, 'Not found');
    });

    test('API-EXC-2: exception toString includes details', () {
      final exc = Ride4FreeApiException(401, 'Unauthorized');
      final str = exc.toString();
      expect(str, contains('401'));
      expect(str, contains('Unauthorized'));
    });

    test('API-EXC-3: exception for different status codes', () {
      final exc500 = Ride4FreeApiException(500, 'Server error');
      final exc403 = Ride4FreeApiException(403, 'Forbidden');

      expect(exc500.statusCode, 500);
      expect(exc403.statusCode, 403);
    });

    test('API-EXC-4: exception implements Exception interface', () {
      final exc = Ride4FreeApiException(400, 'Bad request');
      expect(exc, isA<Exception>());
    });
  });

  group('Ride4FreeApi Instance Creation', () {
    test('API-INST-1: can create api with default baseUrl', () {
      final api = Ride4FreeApi();
      expect(api, isNotNull);
    });

    test('API-INST-2: can create api with custom baseUrl', () {
      final api1 = Ride4FreeApi(baseUrl: 'http://localhost:8000');
      final api2 = Ride4FreeApi(baseUrl: 'https://api.example.com');
      
      expect(api1, isNotNull);
      expect(api2, isNotNull);
    });

    test('API-INST-3: api instance is properly initialized', () {
      final api = Ride4FreeApi(baseUrl: 'http://localhost:9000');
      expect(api, isNotNull);
      // All methods should be available
      expect(api.register, isA<Function>());
      expect(api.login, isA<Function>());
      expect(api.logout, isA<Function>());
    });
  });

  test('Configuração: apiBaseUrl deve estar configurado corretamente', () {
    // Verifica se a URL não está vazia (importante para não ir para localhost por erro)
    expect(Ride4FreeAppConfig.apiBaseUrl, isNotEmpty);
    expect(Ride4FreeAppConfig.apiBaseUrl, contains('trycloudflare.com'));
  });

  test('Configuração: useRemoteApi deve ser verdadeiro se a URL estiver presente', () {
    expect(Ride4FreeAppConfig.useRemoteApi, isTrue);
  });
}


