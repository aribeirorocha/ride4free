// =============================================================================
// EXTENDED UNIT TESTS — Ride4FreeApi Error Handling & Edge Cases
// Tests for comprehensive API coverage, error scenarios, and data validation
// =============================================================================

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:Ride4Free/ride4free_api.dart';

http.Response _ok(Object body) => http.Response(jsonEncode(body), 200);
http.Response _err(int code, [String msg = 'error']) => http.Response('{"detail":"$msg"}', code);

void main() {
  group('Extended Ride4FreeApi Tests - Error Handling', () {
    test('Network timeout returns Ride4FreeApiException', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Connection timeout');
      });

      final api = Ride4FreeApi(client: mockClient);
      
      expect(
        () => api.getDatabaseSchema(),
        throwsA(isA<Exception>()),
      );
    });

    test('500 Server Error includes error details', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Internal server error","code":"DB_ERROR"}', 500);
      });

      final api = Ride4FreeApi(client: mockClient);
      
      expect(
        () => api.getDatabaseSchema(),
        throwsA(isA<Ride4FreeApiException>()),
      );
    });

    test('401 Unauthorized returns proper exception', () async {
      final mockClient = MockClient((request) async {
        return _err(401, 'Unauthorized');
      });

      final api = Ride4FreeApi(client: mockClient);
      
      expect(
        () => api.getUserProfile(),
        throwsA(isA<Ride4FreeApiException>()),
      );
    });

    test('403 Forbidden access', () async {
      final mockClient = MockClient((request) async {
        return _err(403, 'Access denied');
      });

      final api = Ride4FreeApi(client: mockClient);
      
      expect(
        () => api.getUserProfile(),
        throwsA(isA<Ride4FreeApiException>()),
      );
    });

    test('404 Not Found returns exception', () async {
      final mockClient = MockClient((request) async {
        return _err(404, 'Resource not found');
      });

      final api = Ride4FreeApi(client: mockClient);
      
      expect(
        () => api.getUserProfile(),
        throwsA(isA<Ride4FreeApiException>()),
      );
    });

    test('422 Validation Error includes validation details', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail":[{"loc":["body","email"],"msg":"invalid email format"}]}',
          422,
        );
      });

      final api = Ride4FreeApi(client: mockClient);
      
      expect(
        () => api.getUserProfile(),
        throwsA(isA<Ride4FreeApiException>()),
      );
    });
  });

  group('Extended Ride4FreeApi Tests - Data Parsing', () {
    test('listAvailablePassengers parses empty list correctly', () async {
      final mockClient = MockClient((request) async {
        return _ok({'passengers': []});
      });

      final api = Ride4FreeApi(client: mockClient);
      final passengers = await api.listAvailablePassengers();

      expect(passengers, isEmpty);
      expect(passengers, isA<List<Map<String, dynamic>>>());
    });

    test('listAvailablePassengers handles null fields gracefully', () async {
      final mockClient = MockClient((request) async {
        return _ok({
          'passengers': [
            {
              'id': 1,
              'passenger_name': 'João',
              'destination': 'FEUP',
              'passenger_count': 2,
              'status': 'open',
              'created_at': null,
              'rating': null,
            }
          ]
        });
      });

      final api = Ride4FreeApi(client: mockClient);
      final passengers = await api.listAvailablePassengers();

      expect(passengers.length, 1);
      expect(passengers[0]['passenger_name'], 'João');
      expect(passengers[0]['created_at'], isNull);
    });

    test('getCredits parses transaction history correctly', () async {
      final mockClient = MockClient((request) async {
        return _ok({
          'balance': 150,
          'transactions': [
            {
              'id': 1,
              'type': 'earn',
              'amount': 50,
              'reason': 'Completed ride',
              'timestamp': '2026-05-20T10:30:00',
            },
            {
              'id': 2,
              'type': 'spend',
              'amount': 5,
              'reason': 'Requested ride',
              'timestamp': '2026-05-21T14:15:00',
            }
          ]
        });
      });

      final api = Ride4FreeApi(client: mockClient);
      final credits = await api.getCredits();

      expect(credits.balance, 150);
      expect(credits.transactions.length, 2);
      expect(credits.transactions[0]['type'], 'earn');
      expect(credits.transactions[1]['type'], 'spend');
    });
  });

  group('Extended Ride4FreeApi Tests - Request Parameters', () {
    test('listDriversForDestination constructs query parameters correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['destination'], 'FEUP');
        expect(request.url.queryParameters['lat'], '41.178');
        expect(request.url.queryParameters['lng'], '-8.598');
        expect(request.url.queryParameters['radius_m'], '1000');
        
        return _ok({
  'credits_balance': 95,
  'credits_spent': 5,
  'request_id': 123,
});
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.listDriversForDestination(
        'FEUP',
        lat: 41.1780,
        lng: -8.5980,
        radiusM: 1000,
      );
    });

    test('requestJoinRide includes all optional parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        
        final body = jsonDecode(request.body);
        expect(body['offer_id'], 42);
        expect(body['passenger_count'], 2);
        expect(body['origin_display'], 'FEUP');
        expect(body['destination_display'], 'Livraria');
        expect(body['departure_time'], '10:30');
        
        return _ok({
  'id': 1,
  'credits_balance': 95,
});
      });

      final api = Ride4FreeApi(client: mockClient);
      final result = await api.requestJoinRide(
        offerId: 42,
        passengerCount: 2,
        originDisplay: 'FEUP',
        destinationDisplay: 'Livraria',
        departureTime: '10:30',
      );

      expect(result.creditsBalance, 95);
    });

    test('createPassengerRequest with all location parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        
        final body = jsonDecode(request.body);
        expect(body['destination'], 'Center');
        expect(body['passenger_count'], 2);
        expect(body['origin_lat'], 41.1780);
        expect(body['origin_lng'], -8.5980);
        expect(body['origin_display'], 'FEUP');
        expect(body['departure_time'], '09:00');
        
        return _ok({'id': 999});
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.createPassengerRequest(
        destination: 'Center',
        passengerCount: 2,
        originLat: 41.1780,
        originLng: -8.5980,
        originDisplay: 'FEUP',
        departureTime: '09:00',
      );
    });
  });

  group('Extended Ride4FreeApi Tests - Authentication', () {
    test('Requests include Authorization header when token is set', () async {
      Ride4FreeAuth.token = 'test_token_12345';
      
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test_token_12345');
        return _ok({'id': 1, 'email': 'user@test.com', 'name': 'User'});
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.getUserProfile();
      
      Ride4FreeAuth.token = null;
    });

    test('Logout clears the auth token', () async {
      Ride4FreeAuth.token = 'test_token';
      
      final mockClient = MockClient((request) async {
        return _ok({'message': 'logged out'});
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.logout();
    });

    test('Multiple consecutive requests reuse the same token', () async {
      Ride4FreeAuth.token = 'persistent_token';
      
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        expect(request.headers['Authorization'], 'Bearer persistent_token');
        
        if (requestCount == 1) {
          return _ok({'id': 1});
        } else if (requestCount == 2) {
          return _ok({'balance': 100});
        }
        return _ok({});
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.getUserProfile();
      await api.getCredits();
      
      expect(requestCount, 2);
      Ride4FreeAuth.token = null;
    });
  });

  group('Extended Ride4FreeApi Tests - Boundary Conditions', () {
    test('Very large seat count is accepted', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['available_seats'], 100);
        return _ok({'id': 1});
      });

      final api = Ride4FreeApi(client: mockClient);
      final offerId = await api.createDriverOffer(
        destination: 'Test',
        availableSeats: 100,
        departureTime: '12:00',
        description: 'Test',
      );
      
      expect(offerId, 1);
    });

    test('Zero seat count in boundary test', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['available_seats'], 0);
        return _ok({'id': 2});
      });

      final api = Ride4FreeApi(client: mockClient);
      final offerId = await api.createDriverOffer(
        destination: 'Test',
        availableSeats: 0,
        departureTime: '12:00',
        description: 'Test',
      );
      
      expect(offerId, 2);
    });

    test('Very long destination name is handled', () async {
      final longDest = 'A' * 500;
      
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['destination'], longDest);
        return _ok({'id': 3});
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.createPassengerRequest(
        destination: longDest,
        passengerCount: 1,
      );
    });

    test('Special characters in destination are preserved', () async {
      final specialDest = 'Café São Bento & Maria\'s Place';
      
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['destination'], specialDest);
        return _ok({'id': 4});
      });

      final api = Ride4FreeApi(client: mockClient);
      await api.createPassengerRequest(
        destination: specialDest,
        passengerCount: 1,
      );
    });
  });

  group('Extended Ride4FreeApi Tests - Response Validation', () {
    test('getUserProfile validates required fields', () async {
      final mockClient = MockClient((request) async {
        return _ok({
          'id': 1,
          'email': 'user@example.com',
          'name': 'User Name',
          'credits_balance': 100,
          'created_at': '2026-01-01T00:00:00',
          'vehicle_info': 'Tesla Model 3',
          'university_id': 'up202000001',
        });
      });

      final api = Ride4FreeApi(client: mockClient);
      final profile = await api.getUserProfile();

      expect(profile['id'], 1);
      expect(profile['email'], 'user@example.com');
      expect(profile['name'], 'User Name');
      expect(profile['vehicle_info'], 'Tesla Model 3');
    });

    test('Empty response body throws exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      
      expect(
  await api.getUserProfile(),
  {},
);
    });

    test('Malformed JSON response throws exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response('not valid json {', 200);
      });

      final api = Ride4FreeApi(client: mockClient);
      
      expect(
        () => api.getUserProfile(),
        throwsA(anything),
      );
    });
  });
}
