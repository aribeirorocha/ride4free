// active_ride_flow3_test.dart
// Novos testes para aumentar coverage do active_ride_flow.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:Ride4Free/active_ride_flow.dart';
import 'package:Ride4Free/ride4free_api.dart';

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
    };

void main() {
  late MockRide4FreeApi mockApi;

  setUp(() {
    mockApi = MockRide4FreeApi();
    Ride4FreeAuth.token = 'token';
  });

  tearDown(() {
    Ride4FreeAuth.token = null;
  });

  // =============================================================
  // STATUS CARD
  // =============================================================

  testWidgets(
    'STATUS-U4: Passageiro ainda não confirmou vê mensagem inicial',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(
            initialRide: _passengerRide(
              driverIn: 0,
              passengerIn: 0,
            ),
            api: mockApi,
          ),
        ),
      );

      await tester.pump(Duration.zero);

      expect(
        find.textContaining('Confirmem que estão no carro'),
        findsOneWidget,
      );
    },
  );

  // =============================================================
  // CHAT
  // =============================================================

  /*testWidgets(
    'CHAT-U10: Mensagem vazia não chama sendRideMessage',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(
            initialRide: _passengerRide(),
            api: mockApi,
          ),
        ),
      );

      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '   ');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      verifyNever(mockApi.sendRideMessage(any, any));
    },
  );*/

  testWidgets(
    'CHAT-U11: Erro ao enviar mensagem mostra SnackBar',
    (tester) async {
      when(mockApi.sendRideMessage(1, 'teste'))
          .thenThrow(Exception('network error'));

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(
            initialRide: _passengerRide(),
            api: mockApi,
          ),
        ),
      );

      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'teste');

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro ao enviar mensagem'), findsOneWidget);
    },
  );

  testWidgets(
    'CHAT-U12: Chat vazio mostra mensagem inicial',
    (tester) async {
      when(mockApi.listRideMessages(1))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(
            initialRide: _passengerRide(),
            api: mockApi,
          ),
        ),
      );

      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('Diz olá'), findsOneWidget);
    },
  );

  // =============================================================
  // CONFIRM IN CAR
  // =============================================================

  testWidgets(
    'CONFIRM-U3: Confirmar entrada mostra mensagem de sucesso',
    (tester) async {
      when(mockApi.confirmInCar(1))
          .thenAnswer((_) async => _passengerRide(driverIn: 1));

      when(mockApi.getActiveRideState()).thenAnswer(
        (_) async => (
          ride: _passengerRide(driverIn: 1),
          pendingRating: null,
        ),
      );

      when(mockApi.listRideMessages(1))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(
            initialRide: _passengerRide(),
            api: mockApi,
          ),
        ),
      );

      await tester.pump(Duration.zero);

      await tester.tap(find.text('Iniciar viagem'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Confirmado'), findsOneWidget);
    },
  );

  // =============================================================
  // COMPLETE RIDE
  // =============================================================

  testWidgets(
    'COMPLETE-U2: Terminar viagem mostra sucesso',
    (tester) async {
      when(mockApi.completeRide(1))
          .thenAnswer((_) async => {});

      when(mockApi.getActiveRideState()).thenAnswer(
        (_) async => (
          ride: _passengerRide(
            status: 'in_progress',
            driverIn: 1,
            passengerIn: 1,
          ),
          pendingRating: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(
            initialRide: _passengerRide(
              status: 'in_progress',
              driverIn: 1,
              passengerIn: 1,
            ),
            api: mockApi,
          ),
        ),
      );

      await tester.pump(Duration.zero);

      await tester.tap(find.text('Terminar viagem'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Viagem terminada'), findsOneWidget);
    },
  );

  // =============================================================
  // REFRESH
  // =============================================================

  testWidgets(
    'REFRESH-U4: Sem token não chama API',
    (tester) async {
      Ride4FreeAuth.token = null;

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(
            initialRide: _passengerRide(),
            api: mockApi,
          ),
        ),
      );

      await tester.pump(Duration.zero);

      verifyNever(mockApi.getActiveRideState());
    },
  );

  // =============================================================
  // INFO CARD / ICONS
  // =============================================================

  testWidgets(
    'ICON-U5: Página do passageiro mostra ícones esperados',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(
            initialRide: _passengerRide(),
            api: mockApi,
          ),
        ),
      );

      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.person_pin), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(find.byIcon(Icons.chair_alt), findsOneWidget);
    },
  );
}
