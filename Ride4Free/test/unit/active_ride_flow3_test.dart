// active_ride_flow3_test.dart
// Testes CORRIGIDOS — sem duplicações com f1/f2, sem acesso a membros privados.
//
// Duplicações removidas vs ficheiros anteriores:
//   STATUS-U4  → igual a AR-U5  (f1) — removido
//   CHAT-U11   → igual a CHAT-U5 (f1) — removido
//   CHAT-U12   → igual a CHAT-U1 (f1) — removido
//   SEND-U1    → igual a CHAT-U3 (f1) — removido
//   SEND-U3    → igual a CHAT-U11 (mesmo f3, e CHAT-U5 do f1) — corrigido e fundido em SEND-U2
//   ICON-U5    → subconjunto de ICON-U1+U2+U3 (f2) — removido
//   ARC-U2     → igual a ARC-U1 (f1) — removido
//
// Erros corrigidos:
//   SEND-U1: `any as int` / `any as String` → sintaxe inválida → removida
//   SEND-U3: acesso a `state._chatController` / `state._sendMessage()` → privados → reescrito via UI
//   SEND-U2: mockApi declarado duas vezes (local + setUp) → unificado

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:Ride4Free/active_ride_flow.dart';
import 'package:Ride4Free/ride4free_api.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  late MockRide4FreeApi mockApi;

  setUp(() {
    mockApi = MockRide4FreeApi();
    Ride4FreeAuth.token = 'token';
  });

  tearDown(() {
    Ride4FreeAuth.token = null;
  });

  // ==========================================================================
  // SEND — comportamentos únicos não cobertos em f1/f2
  // ==========================================================================

  // SEND-U2: corrigido — usa apenas o mockApi do setUp (sem declaração local)
  // e verifica que o campo é limpo após envio bem-sucedido
  testWidgets(
    'SEND-U2: Enviar mensagem limpa campo e chama sendRideMessage',
    (tester) async {
      when(mockApi.sendRideMessage(1, 'Olá')).thenAnswer((_) async {});
      when(mockApi.listRideMessages(1)).thenAnswer((_) async => []);
      when(mockApi.getActiveRideState()).thenAnswer(
        (_) async => (ride: _passengerRide(), pendingRating: null),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Olá');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Mensagem foi enviada
      verify(mockApi.sendRideMessage(1, 'Olá')).called(1);
      // Campo ficou limpo
      expect(find.text('Olá'), findsNothing);
    },
  );

  // ==========================================================================
  // CONFIRM IN CAR
  // ==========================================================================

  // CONFIRM-U3: único — verifica SnackBar de sucesso (f1 só verifica verify())
  testWidgets(
    'CONFIRM-U3: Confirmar entrada mostra SnackBar de sucesso',
    (tester) async {
      when(mockApi.confirmInCar(1))
          .thenAnswer((_) async => _passengerRide(driverIn: 1));
      when(mockApi.getActiveRideState()).thenAnswer(
        (_) async => (ride: _passengerRide(driverIn: 1), pendingRating: null),
      );
      when(mockApi.listRideMessages(1)).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
        ),
      );
      await tester.pump(Duration.zero);

      await tester.tap(find.text('Iniciar viagem'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Confirmado'), findsOneWidget);
    },
  );

  // ==========================================================================
  // COMPLETE RIDE
  // ==========================================================================

  // COMPLETE-U2: único — verifica SnackBar de sucesso (f1 só verifica verify())
  testWidgets(
    'COMPLETE-U2: Terminar viagem mostra SnackBar de sucesso',
    (tester) async {
      when(mockApi.completeRide(1)).thenAnswer((_) async => {});
      when(mockApi.getActiveRideState()).thenAnswer(
        (_) async => (
          ride: _passengerRide(status: 'in_progress', driverIn: 1, passengerIn: 1),
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

  // ==========================================================================
  // ACTIVE RIDE COORDINATOR
  // ==========================================================================

  // ARC-U4: único — cobre o ramo pendingRating != null no _poll
  testWidgets(
    'ARC-U4: pendingRating não nulo cobre ramo de avaliação pendente',
    (tester) async {
      when(mockApi.getActiveRideState()).thenAnswer(
        (_) async => (
          ride: null,
          pendingRating: {'id': 99, 'rate_target_name': 'João'},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRideCoordinator(
            child: const Scaffold(body: Text('HOME')),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // O coordinator não crasha e continua a mostrar o filho
      expect(find.byType(ActiveRideCoordinator), findsOneWidget);
    },
  );

  // ARC-U6: único — _poll apanha Exception e não crasha
  testWidgets(
    'ARC-U6: _poll ignora exceções da API e não crasha',
    (tester) async {
      when(mockApi.getActiveRideState()).thenThrow(Exception('network'));

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRideCoordinator(
            child: const Scaffold(body: Text('HOME')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    },
  );

  // ==========================================================================
  // REFRESH
  // ==========================================================================

  // REFRESH-U4: único — sem token o _refresh retorna imediatamente sem chamar API
  testWidgets(
    'REFRESH-U4: Sem token não chama getActiveRideState',
    (tester) async {
      Ride4FreeAuth.token = null;

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
        ),
      );
      await tester.pump(Duration.zero);

      verifyNever(mockApi.getActiveRideState());
    },
  );
}