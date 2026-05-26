// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:Ride4Free/active_ride_flow.dart';
import 'package:Ride4Free/ride4free_api.dart';

// ---------------------------------------------------------------------------
// Mock manual — sem build_runner
// ---------------------------------------------------------------------------

class MockRide4FreeApi extends Mock implements Ride4FreeApi {
  @override
  Future<({Map<String, dynamic>? ride, Map<String, dynamic>? pendingRating})>
      getActiveRideState() =>
          super.noSuchMethod(
            Invocation.method(#getActiveRideState, []),
            returnValue: Future.value((ride: null, pendingRating: null)),
            returnValueForMissingStub: Future.value((ride: null, pendingRating: null)),
          ) as Future<({Map<String, dynamic>? ride, Map<String, dynamic>? pendingRating})>;

  @override
  Future<List<Map<String, dynamic>>> listRideMessages(int rideId) =>
      super.noSuchMethod(
        Invocation.method(#listRideMessages, [rideId]),
        returnValue: Future.value(<Map<String, dynamic>>[]),
        returnValueForMissingStub: Future.value(<Map<String, dynamic>>[]),
      ) as Future<List<Map<String, dynamic>>>;

  @override
  Future<List<Map<String, dynamic>>> listJoinRequestsForOffer(int offerId) =>
      super.noSuchMethod(
        Invocation.method(#listJoinRequestsForOffer, [offerId]),
        returnValue: Future.value(<Map<String, dynamic>>[]),
        returnValueForMissingStub: Future.value(<Map<String, dynamic>>[]),
      ) as Future<List<Map<String, dynamic>>>;

  @override
  Future<Map<String, dynamic>> respondJoinRequest(int requestId, {required bool accept}) =>
      super.noSuchMethod(
        Invocation.method(#respondJoinRequest, [requestId], {#accept: accept}),
        returnValue: Future.value(<String, dynamic>{}),
        returnValueForMissingStub: Future.value(<String, dynamic>{}),
      ) as Future<Map<String, dynamic>>;

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
        returnValue: Future.value(Ride4FreeUser(id: 0, email: '', name: '')),
        returnValueForMissingStub: Future.value(Ride4FreeUser(id: 0, email: '', name: '')),
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

Map<String, dynamic> _driverRide({
  int id = 2,
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
      'destination_display': 'Braga → Porto',
      'passenger_name': 'Maria Santos',
      'passenger_rating_display': '4.5',
    };

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Testes originais
  // -------------------------------------------------------------------------

  group('ActiveRidePage - Lógica e UI', () {
    testWidgets('AR-U2: Botão de chat abre BottomSheet', (tester) async {
      final ride = {'id': 1, 'status': 'matched'};
      await tester.pumpWidget(MaterialApp(home: ActiveRidePage(initialRide: ride)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.text('Chat da Viagem'), findsOneWidget);
    });
  });

  group('ActiveRideCoordinator - Polling Logic', () {
    testWidgets('ARC-U1: Coordinator inicializa e dispara polling', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ActiveRideCoordinator(child: Scaffold(body: Text('Child'))),
      ));
      expect(find.text('Child'), findsOneWidget);
    });
  });

  group('DriverRideRequestsPage - Lista de Pedidos', () {
    testWidgets('DRR-U1: Exibe indicador de loading durante a carga', (tester) async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 1));
        return http.Response('{"requests": []}', 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(home: DriverRideRequestsPage(offerId: 1)));
        await tester.pump(Duration.zero);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);
    });
  });

  // -------------------------------------------------------------------------
  // Novos testes — ActiveRidePage UI
  // -------------------------------------------------------------------------

  group('ActiveRidePage - Passageiro UI', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets('AR-U3: Passageiro vê info do condutor e veículo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.textContaining('João Silva'), findsOneWidget);
      expect(find.textContaining('Toyota Yaris'), findsOneWidget);
    });

    testWidgets('AR-U4: Condutor vê info do passageiro', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _driverRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.textContaining('Maria Santos'), findsOneWidget);
      expect(find.textContaining('Toyota Yaris'), findsNothing);
    });

    testWidgets('AR-U5: Status card mostra "Confirmem que estão no carro"', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.textContaining('Confirmem que estão no carro'), findsOneWidget);
    });

    testWidgets('AR-U6: Status card mostra "Aguardar confirmação"', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(passengerIn: 1), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.textContaining('Aguardar confirmação'), findsOneWidget);
    });

    testWidgets('AR-U7: Status card mostra "Viagem em curso"', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(
          initialRide: _passengerRide(status: 'in_progress', driverIn: 1, passengerIn: 1),
          api: mockApi,
        ),
      ));
      await tester.pump(Duration.zero);

      expect(find.textContaining('Viagem em curso'), findsOneWidget);
    });

    testWidgets('AR-U8: Botão "Iniciar viagem" aparece para passageiro', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.text('Iniciar viagem'), findsOneWidget);
    });

    testWidgets('AR-U9: Botão "Passageiro no carro" aparece para condutor', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _driverRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.text('Passageiro no carro'), findsOneWidget);
    });

    testWidgets('AR-U10: Botão "Terminar viagem" aparece em in_progress', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(
          initialRide: _passengerRide(status: 'in_progress', driverIn: 1, passengerIn: 1),
          api: mockApi,
        ),
      ));
      await tester.pump(Duration.zero);

      expect(find.text('Terminar viagem'), findsOneWidget);
      expect(find.text('Iniciar viagem'), findsNothing);
    });

    testWidgets('AR-U11: FAB de chat ausente quando viagem concluída', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(status: 'completed'), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    });

    testWidgets('AR-U12: Confirmar no carro chama API', (tester) async {
      when(mockApi.confirmInCar(1)).thenAnswer((_) async => _passengerRide(passengerIn: 1));

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.text('Iniciar viagem'));
      await tester.pumpAndSettle();

      verify(mockApi.confirmInCar(1)).called(1);
    });

    testWidgets('AR-U13: Terminar viagem chama API', (tester) async {
      when(mockApi.completeRide(1)).thenAnswer((_) async => {});

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(
          initialRide: _passengerRide(status: 'in_progress', driverIn: 1, passengerIn: 1),
          api: mockApi,
        ),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.text('Terminar viagem'));
      await tester.pump();

      verify(mockApi.completeRide(1)).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // Novos testes — DriverRideRequestsPage
  // -------------------------------------------------------------------------

  group('DriverRideRequestsPage - Estados da Lista', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets('DRR-U2: Lista vazia exibe mensagem de estado vazio', (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sem pedidos pendentes.'), findsOneWidget);
    });

    testWidgets('DRR-U3: Lista com pedidos exibe nome do passageiro', (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => [
            {'id': 10, 'passenger_name': 'Ana Costa', 'rating_display': '4.7', 'passenger_count': 2}
          ]);

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ana Costa'), findsOneWidget);
      expect(find.textContaining('4.7'), findsOneWidget);
    });

    testWidgets('DRR-U4: Aceitar pedido chama API com accept=true', (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => [
            {'id': 10, 'passenger_name': 'Ana Costa', 'rating_display': '5.0', 'passenger_count': 1}
          ]);
      when(mockApi.respondJoinRequest(10, accept: true)).thenAnswer((_) async => {});

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aceitar'));
      await tester.pump();

      verify(mockApi.respondJoinRequest(10, accept: true)).called(1);
    });

    testWidgets('DRR-U5: Recusar pedido chama API com accept=false', (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => [
            {'id': 10, 'passenger_name': 'Ana Costa', 'rating_display': '5.0', 'passenger_count': 1}
          ]);
      when(mockApi.respondJoinRequest(10, accept: false)).thenAnswer((_) async => {});

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Recusar'));
      await tester.pump();

      verify(mockApi.respondJoinRequest(10, accept: false)).called(1);
    });

    testWidgets('DRR-U6: Exibe destino quando fornecido', (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, destination: 'Porto → Lisboa', api: mockApi),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Porto → Lisboa'), findsOneWidget);
    });

    testWidgets('DRR-U7: Erro na API não crasha a página', (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenThrow(Exception('Network error'));

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DriverRideRequestsPage), findsOneWidget);
    });

    testWidgets('DRR-U8: Ride4FreeApiException mostra detail do body', (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => [
            {'id': 10, 'passenger_name': 'Ana Costa', 'rating_display': '4.0', 'passenger_count': 1}
          ]);
      when(mockApi.respondJoinRequest(10, accept: true))
          .thenThrow(Ride4FreeApiException(400, '{"detail": "Boleia cheia"}'));

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aceitar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Boleia cheia'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Novos testes — Chat UI
  // -------------------------------------------------------------------------

  group('ActiveRideChatSheet - Chat UI', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets('CHAT-U1: Chat vazio exibe mensagem de início', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('Diz olá!'), findsOneWidget);
    });

    testWidgets('CHAT-U2: Chat com mensagens exibe o conteúdo', (tester) async {
      when(mockApi.listRideMessages(1)).thenAnswer((_) async => [
            {'sender_user_id': 99, 'sender_name': 'João', 'body': 'Olá tudo bem?'},
            {'sender_user_id': 42, 'sender_name': 'Eu', 'body': 'Sim, obrigado!'},
          ]);

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.text('Olá tudo bem?'), findsOneWidget);
      expect(find.text('Sim, obrigado!'), findsOneWidget);
    });

    testWidgets('CHAT-U3: Envio de mensagem vazia é ignorado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      verifyNever(mockApi.sendRideMessage(1, 'Estou a caminho!'));
    });

    testWidgets('CHAT-U4: Envio de mensagem chama sendRideMessage', (tester) async {
      when(mockApi.sendRideMessage(1, 'Estou a caminho!')).thenAnswer((_) async {});

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Estou a caminho!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      verify(mockApi.sendRideMessage(1, 'Estou a caminho!')).called(1);
      expect(find.text('Estou a caminho!'), findsNothing);
    });

    testWidgets('CHAT-U5: Erro ao enviar mensagem mostra snackbar', (tester) async {
      when(mockApi.sendRideMessage(1, 'Olá')).thenThrow(Exception('fail'));

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Olá');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro ao enviar'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // showRideMessage
  // -------------------------------------------------------------------------

  group('showRideMessage - Utilitário', () {
    testWidgets('UTIL-U1: showRideMessage exibe SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showRideMessage(ctx, 'Mensagem de teste'),
                child: const Text('Mostrar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mostrar'));
      await tester.pumpAndSettle();

      expect(find.text('Mensagem de teste'), findsOneWidget);
    });
  });
}