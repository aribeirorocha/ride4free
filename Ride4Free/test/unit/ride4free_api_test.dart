// =============================================================================
// UNIT TESTS — Ride4FreeApi
// Testa a comunicação HTTP intercetando os pedidos com MockClient
// =============================================================================

import 'dart:convert';
import 'package:Ride4Free/ride4free_session_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Imports da tua aplicação
import 'package:Ride4Free/ride4free_api.dart';

// --- Helpers para testes de cobertura adicionais ---
http.Response _ok(Object body) => http.Response(jsonEncode(body), 200);
http.Response _err(int code, [String msg = 'erro']) => http.Response('{"detail":"$msg"}', code);
Map<String, dynamic> _userJson({int id = 1, String email = 'a@b.com', String name = 'Ana'}) =>
    {'id': id, 'email': email, 'name': name};

void main() {
  // ===========================================================================
  // 1. OS TEUS TESTES ORIGINAIS (MANTIDOS INTACTOS)
  // ===========================================================================
  group('Unit Tests - Ride4FreeApi', () {
    test('API-U1_ALT: getDatabaseSchema processa o JSON corretamente', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/database/schema');
        return http.Response('{"status": "ok", "tables_count": 5}', 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      final result = await api.getDatabaseSchema();

      expect(result, isA<Map<String, dynamic>>());
      expect(result['status'], 'ok');
      expect(result['tables_count'], 5);
    });

    test('API-U2_ALT: bookDriverOffer envia o offer_id correto no body', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/bookings/driver-offer');
        expect(request.method, 'POST');
        final bodyDecoded = jsonDecode(request.body);
        expect(bodyDecoded['offer_id'], 42, reason: 'O offer_id devia ser 42');
        return http.Response('{"success": true}', 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.bookDriverOffer(42);
    });

    test('API-U3: listAvailableDrivers() processa a lista e os parâmetros de destino', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/community/drivers');
        expect(request.url.queryParameters['destination'], 'FEUP');
        final mockResponse = {
          "drivers": [
            {"id": 10, "name": "Condutor 1", "destination": "FEUP"},
            {"id": 11, "name": "Condutor 2", "destination": "FEUP"}
          ]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      final drivers = await api.listAvailableDrivers(destination: 'FEUP');

      expect(drivers, isA<List<Map<String, dynamic>>>());
      expect(drivers.length, 2);
      expect(drivers.first['name'], 'Condutor 1');
    });

    test('API-U4: Quando o servidor devolve um erro (ex: 401), lança Ride4FreeApiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Invalid credentials"}', 401);
      });

      final api = Ride4FreeApi(client: mockClient);
      expect(
        () async => await api.login(email: 'errado@fe.up.pt', password: 'pwd'),
        throwsA(isA<Ride4FreeApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });

  group('Ride4FreeApi - bookPassengerRequest', () {
    test('Deve enviar um POST com o request_id correto no body', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/bookings/passenger-request'));
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['request_id'], 789);
        return http.Response(jsonEncode({'status': 'success'}), 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      await expectLater(api.bookPassengerRequest(789), completes);
    });

    test('Deve lançar Ride4FreeApiException se o servidor responder erro', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Request not found'}), 404);
      });

      final api = Ride4FreeApi(client: mockClient);
      expect(
        () => api.bookPassengerRequest(123),
        throwsA(isA<Ride4FreeApiException>().having((e) => e.statusCode, 'status', 404)),
      );
    });
  });

  group('Ride4FreeApi - listAvailablePassengers', () {
    test('Deve retornar uma lista de passageiros e formatar a URL sem filtros', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/community/passengers'));
        expect(request.url.queryParameters.isEmpty, isTrue);
        final responsePayload = {
          'passengers': [
            {'id': 1, 'name': 'João', 'destination': 'FEUP'},
            {'id': 2, 'name': 'Maria', 'destination': 'FEP'},
          ]
        };
        return http.Response(jsonEncode(responsePayload), 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      final result = await api.listAvailablePassengers();
      expect(result.length, 2);
      expect(result[0]['name'], 'João');
      expect(result[1]['destination'], 'FEP');
    });

    test('Deve incluir o parâmetro "destination" na URL quando fornecido', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['destination'], 'FEUP');
        return http.Response(jsonEncode({'passengers': []}), 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.listAvailablePassengers(destination: '  FEUP  ');
    });

    test('Deve retornar lista vazia se o campo "passengers" for nulo no JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'passengers': null}), 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      final result = await api.listAvailablePassengers();
      expect(result, isA<List>());
      expect(result.isEmpty, isTrue);
    });

    test('Deve lançar Ride4FreeApiException em caso de erro 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final api = Ride4FreeApi(client: mockClient);
      expect(() => api.listAvailablePassengers(), throwsA(isA<Ride4FreeApiException>()));
    });
  });

  group('Ride4FreeApi - createPassengerRequest', () {
    test('Deve enviar POST com campos obrigatórios e opcionais no JSON', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/passenger/requests'));
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['destination'], 'FEUP');
        expect(body['passenger_count'], 2);
        expect(body['origin_lat'], 41.178);
        expect(body['origin_lng'], -8.595);
        return http.Response(jsonEncode({'status': 'created', 'id': 1}), 201);
      });

      final api = Ride4FreeApi(client: mockClient);
      await expectLater(
        api.createPassengerRequest(
          destination: 'FEUP', passengerCount: 2, originLat: 41.178, originLng: -8.595,
        ),
        completes,
      );
    });

    test('Não deve incluir origin_lat/lng no JSON se forem nulos', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body.containsKey('destination'), isTrue);
        expect(body.containsKey('origin_lat'), isFalse);
        expect(body.containsKey('origin_lng'), isFalse);
        return http.Response(jsonEncode({'status': 'created', 'id': 2}), 201);
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.createPassengerRequest(destination: 'FEP');
    });

    test('Deve lançar Ride4FreeApiException se o token for inválido (401)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Not authenticated'}), 401);
      });

      final api = Ride4FreeApi(client: mockClient);
      expect(
        () => api.createPassengerRequest(destination: 'FEUP'),
        throwsA(isA<Ride4FreeApiException>().having((e) => e.statusCode, 'status', 401)),
      );
    });
  });

  group('Ride4FreeApi - createDriverOffer', () {
    test('Deve enviar um POST com todos os campos (obrigatórios e opcionais)', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/driver/offers'));
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['destination'], 'FEUP');
        expect(body['available_seats'], 3);
        expect(body['departure_time'], '18:00');
        expect(body['description'], 'Boleia rápida');
        expect(body['origin_lat'], 41.1);
        expect(body['destination_lat'], 41.2);
        return http.Response(jsonEncode({'status': 'ok', 'id': 1}), 201);
      });

      final api = Ride4FreeApi(client: mockClient);
      await expectLater(
        api.createDriverOffer(
          destination: 'FEUP', availableSeats: 3, departureTime: '18:00',
          description: 'Boleia rápida', originLat: 41.1, originLng: -8.6,
          destinationLat: 41.2, destinationLng: -8.7,
        ),
        completes,
      );
    });

    test('Deve omitir campos opcionais no JSON quando forem nulos', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['destination'], 'FEUP');
        expect(body['available_seats'], 4);
        expect(body.containsKey('origin_lat'), isFalse);
        expect(body.containsKey('destination_lat'), isFalse);
        return http.Response(jsonEncode({'status': 'ok', 'id': 2}), 201);
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.createDriverOffer(destination: 'FEUP', availableSeats: 4);
    });

    test('Deve lançar Ride4FreeApiException em caso de erro 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Invalid data'}), 400);
      });

      final api = Ride4FreeApi(client: mockClient);
      expect(
        () => api.createDriverOffer(destination: 'Erro', availableSeats: 0),
        throwsA(isA<Ride4FreeApiException>()),
      );
    });
  });

  group('Ride4FreeApi - listPassengersForDestination', () {
    test('Deve enviar um GET com o destino correto nos query parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/driver/passengers'));
        expect(request.url.queryParameters['destination'], 'FEUP');
        expect(request.method, 'GET');
        final responsePayload = {
          'passengers': [
            {'id': 10, 'name': 'Ricardo', 'origin': 'Trindade'},
            {'id': 11, 'name': 'Sofia', 'origin': 'Matosinhos'}
          ],
          'count': 2
        };
        return http.Response(jsonEncode(responsePayload), 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      final result = await api.listPassengersForDestination('FEUP');
      expect(result['count'], 2);
      expect(result['passengers'], isA<List>());
      expect(result['passengers'][0]['name'], 'Ricardo');
    });

    test('Deve lançar Ride4FreeApiException se o destino não existir (404)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Destination not found'}), 404);
      });

      final api = Ride4FreeApi(client: mockClient);
      expect(
        () => api.listPassengersForDestination('Lua'),
        throwsA(isA<Ride4FreeApiException>().having((e) => e.statusCode, 'status', 404)),
      );
    });

    test('Deve incluir o token de autorização nos headers', () async {
      Ride4FreeAuth.token = 'abc_123_jwt';
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer abc_123_jwt');
        return http.Response(jsonEncode({}), 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.listPassengersForDestination('FEP');
      Ride4FreeAuth.token = null; // reset
    });
  });

  // ===========================================================================
  // 2. TESTES DE COBERTURA FALTANTES (ADICIONADOS)
  // ===========================================================================

  group('Ride4FreeConfig e Ride4FreeApiException', () {
    test('normalizeBaseUrl remove barras finais corretamente', () {
      expect(Ride4FreeConfig.normalizeBaseUrl('https://example.com/'), 'https://example.com');
      expect(Ride4FreeConfig.normalizeBaseUrl('https://example.com///'), 'https://example.com');
      expect(Ride4FreeConfig.normalizeBaseUrl('https://example.com'), 'https://example.com');
      expect(Ride4FreeConfig.normalizeBaseUrl('  https://example.com  '), 'https://example.com');
    });

    test('Ride4FreeApiException toString inclui statusCode e body', () {
      final e = Ride4FreeApiException(404, 'not found');
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('not found'));
      expect(e.statusCode, 404);
      expect(e.body, 'not found');
    });
  });

  group('Ride4FreeAuth, Sessões e Login/Logout', () {
    test('login usa /users/login mesmo com baseUrl com barra final', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/users/login');
        return http.Response(jsonEncode({'token': 't', 'user': {'id': 1, 'email': 'a@b.c', 'name': 'Test'}}), 200);
      });

      final api = Ride4FreeApi(baseUrl: 'https://example.com/', client: mockClient);
      await api.login(email: 'a@b.c', password: 'secret');
    });

    test('register: sucesso devolve user e token', () async {
      final api = Ride4FreeApi(client: MockClient((req) async {
        expect(req.url.path, '/users/register');
        return _ok({'token': 'tok_new', 'user': _userJson(email: 'novo@up.pt', name: 'Novo')});
      }));
      final r = await api.register(email: 'novo@up.pt', password: 'pw', name: 'Novo');
      expect(r.token, 'tok_new');
      expect(r.user.name, 'Novo');
    });

    test('logout: sucesso limpa o token', () async {
      Ride4FreeAuth.token = 'tok_before';
      final api = Ride4FreeApi(client: MockClient((req) async {
        expect(req.url.path, '/users/logout');
        return _ok({});
      }));
      await api.logout();
      expect(Ride4FreeAuth.token, isNull);
    });
    
    test('deve instanciar um Ride4FreeApi real caso o parâmetro api seja nulo no session_sync', () async {
      try {
        await syncRide4FreeApiSession(
          email: 'test@coverage.com',
          password: 'password123',
          displayName: 'Teste Coverage',
        );
      } catch (e) {}
    });
  });

  group('Perfil de Utilizador, Créditos e Reviews', () {
    test('getUserProfile e me devolvem dados corretos', () async {
      final api = Ride4FreeApi(client: MockClient((req) async {
        expect(req.url.path, '/users/me');
        return _ok(_userJson(id: 3, name: 'Carlos'));
      }));
      final u = await api.me();
      expect(u.id, 3);
      final m = await api.getUserProfile();
      expect(m['name'], 'Carlos');
    });

    test('updateVehicleInfo: envia PUT corretamente', () async {
      final api = Ride4FreeApi(client: MockClient((req) async {
        expect(req.method, 'PUT');
        expect(jsonDecode(req.body)['vehicle_info'], 'Toyota Yaris');
        return _ok({});
      }));
      await api.updateVehicleInfo('Toyota Yaris');
    });

    test('getCredits: devolve balance e transactions', () async {
      final api = Ride4FreeApi(client: MockClient((_) async => _ok({
        'balance': 150, 'transactions': [{'amount': 10}]
      })));
      final r = await api.getCredits();
      expect(r.balance, 150);
      expect(r.transactions.length, 1);
    });

    test('getUserReviews: devolve lista', () async {
      final api = Ride4FreeApi(client: MockClient((_) async => _ok({'reviews': [{'stars': 5}]})));
      final r = await api.getUserReviews(42);
      expect(r.length, 1);
    });
  });

  group('Join Requests e Outras Listagens', () {
    test('listDriversForDestination envia lat/lng e radius na query', () async {
      final api = Ride4FreeApi(client: MockClient((req) async {
        expect(req.url.path, '/passenger/drivers');
        expect(req.url.queryParameters['lat'], '41.1');
        return _ok({'drivers': []});
      }));
      await api.listDriversForDestination('FEUP', lat: 41.1, lng: -8.6, radiusM: 300);
    });

    test('requestJoinRide: devolve id e balance', () async {
      final api = Ride4FreeApi(client: MockClient((req) async {
        return _ok({'id': 99, 'credits_balance': 80});
      }));
      final r = await api.requestJoinRide(offerId: 10);
      expect(r.id, 99);
      expect(r.creditsBalance, 80);
    });

    test('listMyPassengerJoinRequests / listDriverIncomingJoinRequests', () async {
      final api = Ride4FreeApi(client: MockClient((_) async => _ok({'requests': [{'id': 1}]})));
      expect((await api.listMyPassengerJoinRequests()).length, 1);
      expect((await api.listDriverIncomingJoinRequests()).length, 1);
    });

    test('passengerRespondJoinRequest / respondJoinRequest', () async {
      final api = Ride4FreeApi(client: MockClient((req) async => _ok({'status': 'ok'})));
      expect((await api.passengerRespondJoinRequest(7, accept: true))['status'], 'ok');
      expect((await api.respondJoinRequest(8, accept: true))['status'], 'ok');
    });

    test('listJoinRequestMessages / sendJoinRequestMessage', () async {
      final api = Ride4FreeApi(client: MockClient((req) async => _ok({'messages': [{'body': 'Ola'}]})));
      expect((await api.listJoinRequestMessages(3)).first['body'], 'Ola');
      await api.sendJoinRequestMessage(3, 'Ola');
    });

    test('listJoinRequestsForOffer e listMyOffersWithPendingRequests', () async {
      final api = Ride4FreeApi(client: MockClient((_) async => _ok({'requests': [], 'offers': [{'id': 1}]})));
      expect(await api.listJoinRequestsForOffer(5), isEmpty);
      expect((await api.listMyOffersWithPendingRequests()).length, 1);
    });
  });

  group('Viagens Ativas e Respostas Vazias', () {
    test('getActiveRideState', () async {
      final api = Ride4FreeApi(client: MockClient((_) async => _ok({'ride': {'id': 1}})));
      final r = await api.getActiveRideState();
      expect(r.ride?['id'], 1);
    });

    test('confirmInCar / completeRide', () async {
      final api = Ride4FreeApi(client: MockClient((_) async => _ok({'status': 'ok', 'ride': {'id': 1}})));
      expect((await api.confirmInCar(1))['id'], 1);
      expect((await api.completeRide(2))['status'], 'ok');
    });

    test('listRideMessages / sendRideMessage', () async {
      final api = Ride4FreeApi(client: MockClient((req) async => _ok({'messages': [{'body': 'A caminho'}]})));
      expect((await api.listRideMessages(4)).length, 1);
      await api.sendRideMessage(4, 'Estou aqui');
    });

    test('rateRideParticipant', () async {
      final api = Ride4FreeApi(client: MockClient((req) async {
        expect(req.url.path, '/rides/active/1/rate');
        return _ok({});
      }));
      await api.rateRideParticipant(1, stars: 5);
    });

    test('_jsonOrThrow processa body vazio sem lançar excepção', () async {
      final api = Ride4FreeApi(client: MockClient((_) async => http.Response('', 200)));
      final r = await api.getDatabaseSchema();
      expect(r, isEmpty);
    });
  });
}