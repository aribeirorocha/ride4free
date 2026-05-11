import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

// Imports do teu projeto
import 'package:app_test/ride4free_api.dart';

void main() {
  group('Integration - Ride4FreeApi', () {
    late Ride4FreeApi api;

    setUp(() {
      // Limpar o token global antes de cada teste
      Ride4FreeAuth.token = null;
    });

    test('API-IT1: Deve incluir o token JWT nos headers após o login', () async {
      // Usamos o MockClient para verificar o comportamento dos headers
      final mockClient = MockClient((request) async {
        // Se for o login, devolvemos um token
        if (request.url.path.endsWith('/users/login')) {
          return http.Response(
            jsonEncode({
              'token': 'jwt_token_123',
              'user': {'id': 1, 'email': 't@f.up.pt', 'name': 'Teste'}
            }),
            200,
          );
        }
        
        // Se for outro pedido, verificamos se o header Authorization está lá
        if (request.url.path.endsWith('/users/me')) {
          if (request.headers['Authorization'] == 'Bearer jwt_token_123') {
            return http.Response(jsonEncode({'id': 1, 'email': 't@f.up.pt', 'name': 'Teste'}), 200);
          } else {
            return http.Response('Unauthorized', 401);
          }
        }
        return http.Response('Not Found', 404);
      });

      api = Ride4FreeApi(client: mockClient);

      // 1. Fazer Login
      final loginResult = await api.login(email: 't@f.up.pt', password: '123');
      Ride4FreeAuth.token = loginResult.token; // Simulamos o que o Bootstrapper faz

      // 2. Tentar chamar um método protegido
      final user = await api.me();

      expect(user.id, 1);
      expect(Ride4FreeAuth.token, 'jwt_token_123');
    });

    test('API-IT2: Deve formatar corretamente os Query Parameters para filtros', () async {
      final mockClient = MockClient((request) async {
        // Verificamos se a URL final contém os parâmetros esperados
        // Ex: ?destination=FEUP&lat=41.1&lng=-8.5&radius_m=500
        expect(request.url.queryParameters['destination'], 'FEUP');
        expect(request.url.queryParameters['lat'], '41.1');
        expect(request.url.queryParameters['radius_m'], '1000');

        return http.Response(jsonEncode({'drivers': []}), 200);
      });

      api = Ride4FreeApi(client: mockClient);

      await api.listDriversForDestination(
        'FEUP',
        lat: 41.1,
        lng: -8.5,
        radiusM: 1000,
      );
    });

    test('API-IT3: Deve converter Ride4FreeApiException em caso de erro do servidor', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Email already registered'}), 400);
      });

      api = Ride4FreeApi(client: mockClient);

      expect(
        () => api.register(email: 'a@b.com', password: '123', name: 'A'),
        throwsA(isA<Ride4FreeApiException>().having((e) => e.statusCode, 'status', 400)),
      );
    });
  });
  group('Integration - Ride4FreeApi (Fluxos Avançados)', () {
    late Ride4FreeApi api;

    test('API-IT4: listAvailableDrivers deve mapear corretamente a lista de JSON para Mapas', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          "drivers": [
            {"id": 1, "name": "Ricardo", "destination": "FEUP", "origin": "Trindade"},
            {"id": 2, "name": "Sara", "destination": "FEUP", "origin": "Aliados"}
          ]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });

      api = Ride4FreeApi(client: mockClient);
      final drivers = await api.listAvailableDrivers(destination: 'FEUP');

      expect(drivers, isA<List<Map<String, dynamic>>>());
      expect(drivers.length, 2);
      expect(drivers[0]['name'], 'Ricardo');
      expect(drivers[1]['origin'], 'Aliados');
    });

    test('API-IT5: getDatabaseSchema deve processar respostas complexas do SQLite', () async {
      final mockClient = MockClient((request) async {
        final schemaResponse = {
          "tables": ["users", "offers", "bookings"],
          "version": "1.0.2",
          "healthy": true
        };
        return http.Response(jsonEncode(schemaResponse), 200);
      });

      api = Ride4FreeApi(client: mockClient);
      final schema = await api.getDatabaseSchema();

      expect(schema['tables'], contains('offers'));
      expect(schema['healthy'], isTrue);
    });

    test('API-IT6: bookDriverOffer deve enviar o ID no formato JSON correto', () async {
      int capturedOfferId = -1;

      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        capturedOfferId = body['offer_id'];
        return http.Response('', 200); // 200 OK para sucesso
      });

      api = Ride4FreeApi(client: mockClient);
      
      await api.bookDriverOffer(500);

      expect(capturedOfferId, 500, reason: 'O ID da oferta não foi enviado corretamente no body');
    });

    test('API-IT7: Deve lançar erro quando o JSON do servidor é inválido', () async {
      final mockClient = MockClient((request) async {
        // Envia um HTML ou texto em vez de JSON para simular erro de parsing
        return http.Response('Internal Server Error (Not JSON)', 500);
      });

      api = Ride4FreeApi(client: mockClient);

      expect(
        () async => await api.getDatabaseSchema(),
        throwsA(isA<Ride4FreeApiException>()),
        reason: 'A API deveria converter o erro 500 numa Ride4FreeApiException'
      );
    });

    test('API-IT8: me() deve converter os dados para o objeto Ride4FreeUser', () async {
      final mockClient = MockClient((request) async {
        final userResponse = {
          "id": 99,
          "email": "up2024@fe.up.pt",
          "name": "Utilizador Teste"
        };
        return http.Response(jsonEncode(userResponse), 200);
      });

      api = Ride4FreeApi(client: mockClient);
      final user = await api.me();

      expect(user, isA<Ride4FreeUser>());
      expect(user.id, 99);
      expect(user.email, 'up2024@fe.up.pt');
    });
  });
}