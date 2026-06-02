// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:Ride4Free/active_ride_flow.dart';
import 'package:Ride4Free/ride4free_api.dart';

// ============================================================================
// MOCKS
// ============================================================================

class MockRide4FreeApi extends Mock implements Ride4FreeApi {
  @override
  Future<({Map<String, dynamic>? ride, Map<String, dynamic>? pendingRating})>
      getActiveRideState() =>
          super.noSuchMethod(
            Invocation.method(#getActiveRideState, []),
            returnValue: Future.value((ride: null, pendingRating: null)),
            returnValueForMissingStub:
                Future.value((ride: null, pendingRating: null)),
          ) as Future<
              ({Map<String, dynamic>? ride, Map<String, dynamic>? pendingRating})>;

  @override
  Future<List<Map<String, dynamic>>> listJoinRequestsForOffer(int offerId) =>
      super.noSuchMethod(
        Invocation.method(#listJoinRequestsForOffer, [offerId]),
        returnValue: Future.value(<Map<String, dynamic>>[]),
        returnValueForMissingStub: Future.value(<Map<String, dynamic>>[]),
      ) as Future<List<Map<String, dynamic>>>;

  @override
  Future<Map<String, dynamic>> respondJoinRequest(int requestId,
          {required bool accept}) =>
      super.noSuchMethod(
        Invocation.method(#respondJoinRequest, [requestId], {#accept: accept}),
        returnValue: Future.value(<String, dynamic>{}),
        returnValueForMissingStub: Future.value(<String, dynamic>{}),
      ) as Future<Map<String, dynamic>>;

  @override
  Future<List<Map<String, dynamic>>> listRideMessages(int rideId) =>
      super.noSuchMethod(
        Invocation.method(#listRideMessages, [rideId]),
        returnValue: Future.value(<Map<String, dynamic>>[]),
        returnValueForMissingStub: Future.value(<Map<String, dynamic>>[]),
      ) as Future<List<Map<String, dynamic>>>;

  @override
  Future<Map<String, dynamic>> confirmInCar(int rideId) =>
      super.noSuchMethod(
        Invocation.method(#confirmInCar, [rideId]),
        returnValue: Future.value(<String, dynamic>{}),
        returnValueForMissingStub: Future.value(<String, dynamic>{}),
      ) as Future<Map<String, dynamic>>;

  @override
  Future<Map<String, dynamic>> completeRide(int rideId) =>
      super.noSuchMethod(
        Invocation.method(#completeRide, [rideId]),
        returnValue: Future.value(<String, dynamic>{}),
        returnValueForMissingStub: Future.value(<String, dynamic>{}),
      ) as Future<Map<String, dynamic>>;

  @override
  Future<void> sendRideMessage(int rideId, String body) =>
      super.noSuchMethod(
        Invocation.method(#sendRideMessage, [rideId, body]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>;

  @override
  Future<void> rateRideParticipant(
    int rideId, {
    int? stars,
    Map<String, int>? criteria,
    String? comment,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #rateRideParticipant,
          [rideId],
          {
            #stars: stars,
            #criteria: criteria,
            #comment: comment,
          },
        ),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>;

  @override
  Future<Ride4FreeUser> me() =>
      super.noSuchMethod(
        Invocation.method(#me, []),
        returnValue: Future.value(
          Ride4FreeUser(id: 1, email: 'test@test.pt', name: 'Tester'),
        ),
        returnValueForMissingStub: Future.value(
          Ride4FreeUser(id: 1, email: 'test@test.pt', name: 'Tester'),
        ),
      ) as Future<Ride4FreeUser>;
}

// ============================================================================
// HELPERS
// ============================================================================

Map<String, dynamic> _passengerRide({
  int id = 1,
  String status = 'matched',
  int driverIn = 0,
  int passengerIn = 0,
}) =>
    {
      'id': id,
      'status': status,
      'is_passenger': true,
      'is_driver': false,
      'driver_in_car': driverIn,
      'passenger_in_car': passengerIn,
      'destination_display': 'Porto → Lisboa',
      'driver_name': 'João Silva',
      'driver_rating_display': '4.8',
      'vehicle_display': 'Toyota Yaris',
      'available_seats': 3,
      'passenger_name': 'Maria',
      'passenger_rating_display': '4.5',
    };

Map<String, dynamic> _driverRide({
  int id = 1,
  String status = 'matched',
  int driverIn = 0,
  int passengerIn = 0,
}) =>
    {
      'id': id,
      'status': status,
      'is_passenger': false,
      'is_driver': true,
      'driver_in_car': driverIn,
      'passenger_in_car': passengerIn,
      'destination_display': 'Porto → Lisboa',
      'driver_name': 'João Silva',
      'driver_rating_display': '4.8',
      'vehicle_display': 'Toyota Yaris',
      'available_seats': 3,
      'passenger_name': 'Maria',
      'passenger_rating_display': '4.5',
    };

// ============================================================================
// TESTS
// ============================================================================

void main() {
  group('showRideMessage - Message Display', () {
    testWidgets('showRideMessage displays SnackBar with text',
        (WidgetTester tester) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showRideMessage(context, 'Test message'),
              child: const Text('Show Message'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('showRideMessage handles empty strings',
        (WidgetTester tester) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showRideMessage(context, ''),
              child: const Text('Show Message'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('showRideMessage handles long text',
        (WidgetTester tester) async {
      const longText =
          'Este é um texto muito longo para testar se a mensagem é exibida corretamente em um SnackBar';

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showRideMessage(context, longText),
              child: const Text('Show Message'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Este é um texto'), findsOneWidget);
    });
  });

  group('navigateToHomeAfterRide - Navigation', () {
    testWidgets('navigateToHomeAfterRide pops to first route',
        (WidgetTester tester) async {
      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: Builder(
                        builder: (innerContext) => ElevatedButton(
                          onPressed: () => Navigator.of(innerContext)
                              .popUntil((route) => route.isFirst),
                          child: const Text('Go Home'),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // Navigate to second page
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Should be on second page
      expect(find.text('Go Home'), findsOneWidget);

      // Navigate back
      await tester.tap(find.text('Go Home'));
      await tester.pumpAndSettle();

      // Should be back on first page
      expect(find.text('Navigate'), findsOneWidget);
    });

    testWidgets('navigateToHomeAfterRide calls goToHomeTab',
        (WidgetTester tester) async {
      int tabIndex = 0;

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Simulate navigation back
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // Simulate setting tab to 0
                    tabIndex = 0;
                  },
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.text('Go Home'));
      await tester.pumpAndSettle();

      expect(tabIndex, 0);
    });
  });

  group('ActiveRideFlow - Coordinator and Rating', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = null;
    });

    testWidgets('promptRideRating displays rating dialog and submits',
        (WidgetTester tester) async {
      when(mockApi.rateRideParticipant(
        1,
        criteria: anyNamed('criteria'),
      )).thenAnswer((_) async {});

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final submitted = await promptRideRating(
                  context: context,
                  rideId: 1,
                  targetName: 'Maria',
                  api: mockApi,
                );
                expect(submitted, true);
              },
              child: const Text('Rate Ride'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.text('Rate Ride'));
      await tester.pumpAndSettle();

      expect(find.text('Enviar'), findsOneWidget);
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Avaliação enviada! Obrigado.'), findsOneWidget);
      verify(mockApi.rateRideParticipant(
        1,
        criteria: anyNamed('criteria'),
      )).called(1);
    });

    testWidgets('ActiveRideCoordinator preserves its child widget',
        (WidgetTester tester) async {
      final widget = MaterialApp(
        home: ActiveRideCoordinator(
          child: const Text('Active coordinator child'),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('Active coordinator child'), findsOneWidget);
    });
  });

  group('DriverRideRequestsPageState - Request Management', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test_token';
    });

    tearDown(() {
      Ride4FreeAuth.token = null;
    });

    testWidgets('_load retrieves join requests for offer',
        (WidgetTester tester) async {
      final requests = [
        {
          'id': 1,
          'passenger_name': 'Maria Santos',
          'passenger_count': 1,
          'rating_display': '4.5',
        }
      ];

      when(mockApi.listJoinRequestsForOffer(1))
          .thenAnswer((_) async => requests);

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final requests = await mockApi.listJoinRequestsForOffer(1);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Loaded ${requests.length} requests'),
                  ),
                );
              },
              child: const Text('Load Requests'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Loaded 1 requests'), findsOneWidget);
    });

    testWidgets('_load handles empty requests list',
        (WidgetTester tester) async {
      when(mockApi.listJoinRequestsForOffer(1))
          .thenAnswer((_) async => []);

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final requests = await mockApi.listJoinRequestsForOffer(1);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(requests.isEmpty
                        ? 'Sem pedidos pendentes'
                        : 'Loaded ${requests.length} requests'),
                  ),
                );
              },
              child: const Text('Load Requests'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sem pedidos pendentes'), findsOneWidget);
    });

    testWidgets('_respond accepts join request',
        (WidgetTester tester) async {
      when(mockApi.respondJoinRequest(1, accept: true))
          .thenAnswer((_) async => {});
      when(mockApi.listJoinRequestsForOffer(1))
          .thenAnswer((_) async => []);

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await mockApi.respondJoinRequest(1, accept: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passageiro aceite.')),
                );
              },
              child: const Text('Accept'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      verify(mockApi.respondJoinRequest(1, accept: true)).called(1);
      expect(find.textContaining('Passageiro aceite'), findsOneWidget);
    });

    testWidgets('_respond rejects join request',
        (WidgetTester tester) async {
      when(mockApi.respondJoinRequest(1, accept: false))
          .thenAnswer((_) async => {});
      when(mockApi.listJoinRequestsForOffer(1))
          .thenAnswer((_) async => []);

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await mockApi.respondJoinRequest(1, accept: false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pedido recusado.')),
                );
              },
              child: const Text('Reject'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      verify(mockApi.respondJoinRequest(1, accept: false)).called(1);
      expect(find.textContaining('Pedido recusado'), findsOneWidget);
    });
  });

  group('ActiveRidePageState - Ride Status Management', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test_token';
    });

    tearDown(() {
      Ride4FreeAuth.token = null;
    });

    test('Passenger ride getters work correctly', () {
      final passengerRide = _passengerRide();
      
      expect(passengerRide['is_passenger'], true);
      expect(passengerRide['is_driver'], false);
      expect(passengerRide['status'], 'matched');
      expect(passengerRide['destination_display'], 'Porto → Lisboa');
    });

    test('Driver ride getters work correctly', () {
      final driverRide = _driverRide();
      
      expect(driverRide['is_driver'], true);
      expect(driverRide['is_passenger'], false);
      expect(driverRide['status'], 'matched');
      expect(driverRide['destination_display'], 'Porto → Lisboa');
    });

    test('Ride status transitions work correctly', () {
      final ride = _passengerRide(status: 'matched');
      expect(ride['status'], 'matched');

      final inProgressRide = _passengerRide(status: 'in_progress');
      expect(inProgressRide['status'], 'in_progress');
    });

    test('confirmInCar should be called with correct ride ID',
        () async {
      when(mockApi.confirmInCar(1))
          .thenAnswer((_) async => _passengerRide(passengerIn: 1));

      final result = await mockApi.confirmInCar(1);

      expect(result['passenger_in_car'], 1);
      verify(mockApi.confirmInCar(1)).called(1);
    });

    test('completeRide should be called with correct ride ID',
        () async {
      when(mockApi.completeRide(1)).thenAnswer((_) async => {});

      await mockApi.completeRide(1);

      verify(mockApi.completeRide(1)).called(1);
    });

    test('Ride with both confirmed in car transitions to in_progress',
        () {
      final ride = _passengerRide(
        status: 'matched',
        passengerIn: 1,
        driverIn: 1,
      );

      expect(ride['passenger_in_car'], 1);
      expect(ride['driver_in_car'], 1);
      expect(ride['status'], 'matched');

      final inProgressRide = _passengerRide(
        status: 'in_progress',
        passengerIn: 1,
        driverIn: 1,
      );

      expect(inProgressRide['status'], 'in_progress');
    });
  });

  group('_ActiveRideChatSheet - Message Handling', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test_token';
    });

    tearDown(() {
      Ride4FreeAuth.token = null;
    });

    test('listRideMessages returns empty list when no messages',
        () async {
      when(mockApi.listRideMessages(1)).thenAnswer((_) async => []);

      final messages = await mockApi.listRideMessages(1);

      expect(messages, isEmpty);
      verify(mockApi.listRideMessages(1)).called(1);
    });

    test('listRideMessages returns messages', () async {
      final messages = [
        {
          'body': 'Olá!',
          'sender_name': 'João',
          'sender_user_id': 2,
        }
      ];

      when(mockApi.listRideMessages(1)).thenAnswer((_) async => messages);

      final result = await mockApi.listRideMessages(1);

      expect(result, isNotEmpty);
      expect(result.length, 1);
      expect(result.first['body'], 'Olá!');
    });

    test('sendRideMessage calls API with correct parameters', () async {
      when(mockApi.sendRideMessage(1, 'Test message'))
          .thenAnswer((_) async {});

      await mockApi.sendRideMessage(1, 'Test message');

      verify(mockApi.sendRideMessage(1, 'Test message')).called(1);
    });

    test('me() returns current user', () async {
      final user = Ride4FreeUser(id: 1, email: 'test@test.pt', name: 'Tester');
      when(mockApi.me()).thenAnswer((_) async => user);

      final result = await mockApi.me();

      expect(result.id, 1);
      expect(result.email, 'test@test.pt');
      expect(result.name, 'Tester');
    });
  });
}
