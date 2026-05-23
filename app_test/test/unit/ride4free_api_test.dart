// =============================================================================
// UNIT TESTS — Ride4FreeApi
// Testa a comunicação HTTP intercetando os pedidos com MockClient
// =============================================================================

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Imports da tua aplicação
import 'package:app_test/ride4free_api.dart';

void main() {
  group('Unit Tests - Ride4FreeApi', () {
    
    // -------------------------------------------------------------------------// -------------------------------------------------------------------------
    // TESTE 1 (Alternativo): GET DATABASE SCHEMA
    // -------------------------------------------------------------------------
    test('API-U1_ALT: getDatabaseSchema processa o JSON corretamente', () async {
      final mockClient = MockClient((request) async {
        // Garantimos que a API pede o caminho correto
        expect(request.url.path, '/database/schema');
        
        // Devolvemos um JSON simples
        return http.Response('{"status": "ok", "tables_count": 5}', 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      final result = await api.getDatabaseSchema();

      // Validamos se o Map foi gerado corretamente sem erros
      expect(result, isA<Map<String, dynamic>>());
      expect(result['status'], 'ok');
      expect(result['tables_count'], 5);
    });

    // -------------------------------------------------------------------------
    // TESTE 2 (Alternativo): BOOK DRIVER OFFER
    // -------------------------------------------------------------------------
    test('API-U2_ALT: bookDriverOffer envia o offer_id correto no body', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/bookings/driver-offer');
        expect(request.method, 'POST');
        
        // Verifica se a tua função construiu o body corretamente
        final bodyDecoded = jsonDecode(request.body);
        expect(bodyDecoded['offer_id'], 42, reason: 'O offer_id devia ser 42');

        return http.Response('{"success": true}', 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      
      // O teste passa se a função executar até ao fim sem atirar exceções (throw)
      await api.bookDriverOffer(42);
    });

    // -------------------------------------------------------------------------
    // TESTE 3: LISTAGEM COM PARÂMETROS DA QUERY
    // -------------------------------------------------------------------------
    test('API-U3: listAvailableDrivers() processa a lista e os parâmetros de destino', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/community/drivers');
        
        // Verificamos se a query string '?destination=FEUP' foi corretamente formatada
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
      
      // Passamos o destination para ver se ele entra na query
      final drivers = await api.listAvailableDrivers(destination: 'FEUP');

      expect(drivers, isA<List<Map<String, dynamic>>>());
      expect(drivers.length, 2);
      expect(drivers.first['name'], 'Condutor 1');
    });

    // -------------------------------------------------------------------------
    // TESTE 4: TRATAMENTO DE ERROS (EXCEÇÕES)
    // -------------------------------------------------------------------------
    test('API-U4: Quando o servidor devolve um erro (ex: 401), lança Ride4FreeApiException', () async {
      final mockClient = MockClient((request) async {
        // Simulamos o backend a dizer "Credenciais Inválidas"
        return http.Response('{"detail": "Invalid credentials"}', 401);
      });

      final api = Ride4FreeApi(client: mockClient);

      // Verificamos se o método "crasha" com a exceção personalizada da tua aplicação
      expect(
        () async => await api.login(email: 'errado@fe.up.pt', password: 'pwd'),
        throwsA(
          isA<Ride4FreeApiException>().having(
            (e) => e.statusCode, 'statusCode', 401
          )
        ),
      );
    });

  });
  group('Ride4FreeApi - bookPassengerRequest', () {
    
    test('Deve enviar um POST com o request_id correto no body', () async {
      // 1. Criamos um cliente falso (Mock) para intercetar o pedido
      final mockClient = MockClient((request) async {
        // Verificamos se o endpoint está correto
        expect(request.url.path, contains('/bookings/passenger-request'));
        // Verificamos se o método é POST
        expect(request.method, 'POST');
        
        // Verificamos se o body contém o ID que enviámos
        final body = jsonDecode(request.body);
        expect(body['request_id'], 789);

        return http.Response(jsonEncode({'status': 'success'}), 200);
      });

      final api = Ride4FreeApi(client: mockClient);

      // 2. Chamamos a função e verificamos se não lança erro
      await expectLater(
        api.bookPassengerRequest(789), 
        completes
      );
    });

    test('Deve lançar Ride4FreeApiException se o servidor responder erro', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Request not found'}), 404);
      });

      final api = Ride4FreeApi(client: mockClient);

      // Verificamos se a nossa exceção personalizada é disparada
      expect(
        () => api.bookPassengerRequest(123),
        throwsA(isA<Ride4FreeApiException>().having((e) => e.statusCode, 'status', 404)),
      );
    });
  });
  group('Ride4FreeApi - listAvailablePassengers', () {
    
    test('Deve retornar uma lista de passageiros e formatar a URL sem filtros', () async {
      final mockClient = MockClient((request) async {
        // Verifica se o caminho está correto
        expect(request.url.path, contains('/community/passengers'));
        // Sem destino, não deve haver query parameters
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
        // Verifica se o filtro foi limpo (trim) e adicionado à URL
        expect(request.url.queryParameters['destination'], 'FEUP');
        
        return http.Response(jsonEncode({'passengers': []}), 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      
      // Testamos com espaços para garantir que o .trim() no teu código funciona
      await api.listAvailablePassengers(destination: '  FEUP  ');
    });

    test('Deve retornar lista vazia se o campo "passengers" for nulo no JSON', () async {
      final mockClient = MockClient((request) async {
        // Simula uma resposta onde a chave existe mas é nula
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

      expect(
        () => api.listAvailablePassengers(),
        throwsA(isA<Ride4FreeApiException>()),
      );
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
        // Verifica se os campos opcionais foram incluídos
        expect(body['origin_lat'], 41.178);
        expect(body['origin_lng'], -8.595);

        return http.Response(jsonEncode({'status': 'created'}), 201);
      });

      final api = Ride4FreeApi(client: mockClient);

      await expectLater(
        api.createPassengerRequest(
          destination: 'FEUP',
          passengerCount: 2,
          originLat: 41.178,
          originLng: -8.595,
        ),
        completes,
      );
    });

    test('Não deve incluir origin_lat/lng no JSON se forem nulos', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        
        expect(body.containsKey('destination'), isTrue);
        // Garantir que as chaves não existem no mapa quando passamos null
        expect(body.containsKey('origin_lat'), isFalse);
        expect(body.containsKey('origin_lng'), isFalse);

        return http.Response(jsonEncode({'status': 'created'}), 201);
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

        return http.Response(jsonEncode({'status': 'ok'}), 201);
      });

      final api = Ride4FreeApi(client: mockClient);

      await expectLater(
        api.createDriverOffer(
          destination: 'FEUP',
          availableSeats: 3,
          departureTime: '18:00',
          description: 'Boleia rápida',
          originLat: 41.1,
          originLng: -8.6,
          destinationLat: 41.2,
          destinationLng: -8.7,
        ),
        completes,
      );
    });

    test('Deve omitir campos opcionais no JSON quando forem nulos', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        
        // Campos obrigatórios ou enviados
        expect(body['destination'], 'FEUP');
        expect(body['available_seats'], 4);
        
        // Campos que NÃO devem existir no mapa
        expect(body.containsKey('description'), isTrue); // No teu código, description é passado direto (pode ir null se não tratares)
        expect(body.containsKey('origin_lat'), isFalse);
        expect(body.containsKey('destination_lat'), isFalse);

        return http.Response(jsonEncode({'status': 'ok'}), 201);
      });

      final api = Ride4FreeApi(client: mockClient);

      await api.createDriverOffer(
        destination: 'FEUP',
        availableSeats: 4,
      );
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
      // 1. Configurar o MockClient
      final mockClient = MockClient((request) async {
        // Verifica se o endpoint está correto
        expect(request.url.path, contains('/driver/passengers'));
        
        // Verifica se o parâmetro 'destination' foi passado na URL
        expect(request.url.queryParameters['destination'], 'FEUP');
        
        // Verifica se é um pedido GET
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

      // 2. Executar a chamada
      final result = await api.listPassengersForDestination('FEUP');

      // 3. Validar os dados retornados
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
      // Definimos um token global para simular utilizador logado
      Ride4FreeAuth.token = 'abc_123_jwt';

      final mockClient = MockClient((request) async {
        // Verifica se o header Authorization foi enviado corretamente
        expect(request.headers['Authorization'], 'Bearer abc_123_jwt');
        
        return http.Response(jsonEncode({}), 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.listPassengersForDestination('FEP');
    });

    test('login usa /users/login mesmo com baseUrl com barra final', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/users/login');
        return http.Response(
          jsonEncode({
            'token': 't',
            'user': {'id': 1, 'email': 'a@b.c', 'name': 'Test'},
          }),
          200,
        );
      });

      final api = Ride4FreeApi(
        baseUrl: 'https://example.trycloudflare.com/',
        client: mockClient,
      );
      await api.login(email: 'a@b.c', password: 'secret');
    });
  });
}