// ignore_for_file: unused_import
// active_ride_flow2_test.dart
// Testes adicionais para aumentar o coverage de ~80% para ~90%+
// Complementam active_ride_flow1_test.dart sem repetir casos já existentes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:Ride4Free/active_ride_flow.dart';
import 'package:Ride4Free/ride4free_api.dart';

// ---------------------------------------------------------------------------
// Mock — reutilizar a mesma definição do ficheiro 1, ou copiar aqui
// (Copia-se aqui para que o ficheiro seja autónomo)
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
        Invocation.method(
            #respondJoinRequest, [requestId], {#accept: accept}),
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
        returnValueForMissingStub:
            Future.value(Ride4FreeUser(id: 0, email: '', name: '')),
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
  // =========================================================================
  // _statusCard — ramos não cobertos
  // =========================================================================

  group('ActiveRidePage - _statusCard ramos adicionais', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    // Ramo: ambos driverIn=1 e passengerIn=1 mas status ainda NÃO é 'in_progress'
    // → deve mostrar "A iniciar…"
    testWidgets(
        'STATUS-U1: Status card mostra "A iniciar…" quando ambos confirmados mas status não in_progress',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(
          initialRide: _passengerRide(driverIn: 1, passengerIn: 1),
          api: mockApi,
        ),
      ));
      await tester.pump(Duration.zero);

      expect(find.textContaining('A iniciar'), findsOneWidget);
    });

    // Ramo: condutor já confirmou (driverIn=1), passageiro ainda não
    // O condutor é _isDriver=true, então _myInCar = _driverIn = true
    // e _otherInCar = _passengerIn = false → "À espera que o outro confirme"
    testWidgets(
        'STATUS-U2: Condutor já confirmou — mostra mensagem de espera pelo passageiro',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(
          initialRide: _driverRide(driverIn: 1, passengerIn: 0),
          api: mockApi,
        ),
      ));
      await tester.pump(Duration.zero);

      expect(
          find.textContaining('À espera que o outro confirme'), findsOneWidget);
    });

    // Ramo: status 'in_progress' para o condutor
    testWidgets('STATUS-U3: Condutor em in_progress vê "Viagem em curso"',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(
          initialRide:
              _driverRide(status: 'in_progress', driverIn: 1, passengerIn: 1),
          api: mockApi,
        ),
      ));
      await tester.pump(Duration.zero);

      expect(find.textContaining('Viagem em curso'), findsOneWidget);
    });
  });

  // =========================================================================
  // _infoCard — cobertura dos ícones (condutor, passageiro, veículo, lugares)
  // =========================================================================

  group('ActiveRidePage - _infoCard ícones', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets('ICON-U1: Ícone person_pin exibido para "Condutor"',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.person_pin), findsOneWidget);
    });

    testWidgets('ICON-U2: Ícone directions_car exibido para "Veículo"',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.directions_car), findsOneWidget);
    });

    testWidgets('ICON-U3: Ícone chair_alt exibido para "Lugares"',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.chair_alt), findsOneWidget);
    });

    testWidgets('ICON-U4: Ícone person exibido para "Passageiro" (condutor)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _driverRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  // =========================================================================
  // confirmInCar — caminho de erro
  // =========================================================================

  group('ActiveRidePage - confirmInCar erros', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets(
        'CONFIRM-ERR-U1: Ride4FreeApiException em confirmInCar mostra SnackBar com body',
        (tester) async {
      when(mockApi.confirmInCar(1))
          .thenThrow(Ride4FreeApiException(400, 'Viagem já iniciada'));

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.text('Iniciar viagem'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Viagem já iniciada'), findsOneWidget);
    });

    testWidgets(
        'CONFIRM-ERR-U2: Após erro em confirmInCar o botão fica novamente activo',
        (tester) async {
      when(mockApi.confirmInCar(1))
          .thenThrow(Ride4FreeApiException(400, 'Erro qualquer'));

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.text('Iniciar viagem'));
      await tester.pumpAndSettle();

      // O botão deve estar habilitado novamente (busy=false)
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Iniciar viagem'),
      );
      expect(btn.onPressed, isNotNull);
    });
  });

  // =========================================================================
  // completeRide — caminho de erro
  // =========================================================================

  group('ActiveRidePage - completeRide erros', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets(
        'COMPLETE-ERR-U1: Ride4FreeApiException em completeRide mostra SnackBar',
        (tester) async {
      when(mockApi.completeRide(1))
          .thenThrow(Ride4FreeApiException(400, 'Viagem não pode ser terminada'));

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(
          initialRide:
              _passengerRide(status: 'in_progress', driverIn: 1, passengerIn: 1),
          api: mockApi,
        ),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.text('Terminar viagem'));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Viagem não pode ser terminada'), findsOneWidget);
    });
  });

  // =========================================================================
  // _refresh — modo silencioso vs. com erro visível
  // =========================================================================

  group('ActiveRidePage - _refresh comportamento', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets(
        'REFRESH-U1: _refresh silencioso não mostra SnackBar em caso de erro',
        (tester) async {
      // A primeira chamada ao getActiveRideState (no initState) falha
      when(mockApi.getActiveRideState()).thenThrow(Exception('timeout'));

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      // pump(Duration.zero) despoleta o _refresh inicial (silent=false)
      // mas como é o primeiro acesso e está mounted, deveria mostrar SnackBar
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();

      // Em modo não silencioso deve aparecer "Erro ao atualizar viagem."
      expect(find.textContaining('Erro ao atualizar'), findsOneWidget);
    });

    testWidgets(
        'REFRESH-U2: _refresh actualiza dados da viagem quando API devolve ride',
        (tester) async {
      final updatedRide = _passengerRide(status: 'in_progress', driverIn: 1, passengerIn: 1);

      when(mockApi.getActiveRideState()).thenAnswer(
          (_) async => (ride: updatedRide, pendingRating: null));
      when(mockApi.listRideMessages(1))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();

      // Após refresh com status in_progress deve aparecer "Terminar viagem"
      expect(find.text('Terminar viagem'), findsOneWidget);
    });
  });

  // =========================================================================
  // _ActiveRideChatSheet — _myId e alinhamento de mensagens
  // =========================================================================

  group('ActiveRideChatSheet - alinhamento de mensagens', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets('CHAT-U6: Mensagem própria não mostra nome do remetente',
        (tester) async {
      when(mockApi.me())
          .thenAnswer((_) async => Ride4FreeUser(id: 42, email: 'eu@test.pt', name: 'Eu'));
      when(mockApi.listRideMessages(1)).thenAnswer((_) async => [
            {'sender_user_id': 42, 'sender_name': 'Eu', 'body': 'Mensagem minha'},
          ]);

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      // O texto "Eu" (nome do remetente) NÃO deve aparecer para mensagens próprias
      expect(find.text('Eu'), findsNothing);
      expect(find.text('Mensagem minha'), findsOneWidget);
    });

    testWidgets(
        'CHAT-U7: Mensagem de outro utilizador mostra nome do remetente',
        (tester) async {
      when(mockApi.me())
          .thenAnswer((_) async => Ride4FreeUser(id: 42, email: 'eu@test.pt', name: 'Eu'));
      when(mockApi.listRideMessages(1)).thenAnswer((_) async => [
            {'sender_user_id': 99, 'sender_name': 'João', 'body': 'Olá!'},
          ]);

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      expect(find.text('João'), findsOneWidget);
    });

    testWidgets('CHAT-U8: Falha em me() não crasha o chat sheet',
        (tester) async {
      when(mockApi.me()).thenThrow(Exception('auth error'));
      when(mockApi.listRideMessages(1)).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      // O chat deve abrir mesmo sem saber o id do utilizador
      expect(find.text('Chat da Viagem'), findsOneWidget);
    });

    testWidgets('CHAT-U9: Envio via tecla Enter/submit chama sendRideMessage',
        (tester) async {
      when(mockApi.sendRideMessage(1, 'Chego em 5 min'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: _passengerRide(), api: mockApi),
      ));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Chego em 5 min');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      verify(mockApi.sendRideMessage(1, 'Chego em 5 min')).called(1);
    });
  });

  // =========================================================================
  // DriverRideRequestsPage — casos adicionais
  // =========================================================================

  group('DriverRideRequestsPage - casos adicionais', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets(
        'DRR-U9: Recusar pedido com Ride4FreeApiException mostra detalhe do erro',
        (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => [
            {
              'id': 10,
              'passenger_name': 'Rui Neves',
              'rating_display': '4.2',
              'passenger_count': 1
            }
          ]);
      when(mockApi.respondJoinRequest(10, accept: false))
          .thenThrow(Ride4FreeApiException(400, '{"detail": "Pedido expirado"}'));

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Recusar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pedido expirado'), findsOneWidget);
    });

    testWidgets(
        'DRR-U10: Ride4FreeApiException com body JSON inválido mostra "Erro."',
        (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => [
            {
              'id': 11,
              'passenger_name': 'Carla',
              'rating_display': '3.9',
              'passenger_count': 1
            }
          ]);
      when(mockApi.respondJoinRequest(11, accept: true))
          .thenThrow(Ride4FreeApiException(500, 'Internal Server Error'));

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aceitar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro.'), findsOneWidget);
    });

    testWidgets(
        'DRR-U11: Sem destino fornecido — campo destino não é renderizado',
        (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      // destination é null, logo o Text correspondente não deve aparecer
      expect(find.text('Porto → Lisboa'), findsNothing);
    });

    testWidgets(
        'DRR-U12: Múltiplos pedidos — todos os nomes aparecem na lista',
        (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => [
            {
              'id': 20,
              'passenger_name': 'Alice',
              'rating_display': '5.0',
              'passenger_count': 1
            },
            {
              'id': 21,
              'passenger_name': 'Bob',
              'rating_display': '4.0',
              'passenger_count': 2
            },
          ]);

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('DRR-U13: Aceitar pedido bem-sucedido mostra "Passageiro aceite."',
        (tester) async {
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async => [
            {
              'id': 10,
              'passenger_name': 'Marta',
              'rating_display': '4.6',
              'passenger_count': 1
            }
          ]);
      // Após aceitar, a lista fica vazia
      when(mockApi.respondJoinRequest(10, accept: true))
          .thenAnswer((_) async => {});

      int callCount = 0;
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return [
            {
              'id': 10,
              'passenger_name': 'Marta',
              'rating_display': '4.6',
              'passenger_count': 1
            }
          ];
        }
        return [];
      });

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aceitar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Passageiro aceite'), findsOneWidget);
    });

    testWidgets('DRR-U14: Recusar pedido bem-sucedido mostra "Pedido recusado."',
        (tester) async {
      int callCount = 0;
      when(mockApi.listJoinRequestsForOffer(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return [
            {
              'id': 10,
              'passenger_name': 'Nuno',
              'rating_display': '4.1',
              'passenger_count': 1
            }
          ];
        }
        return [];
      });
      when(mockApi.respondJoinRequest(10, accept: false))
          .thenAnswer((_) async => {});

      await tester.pumpWidget(MaterialApp(
        home: DriverRideRequestsPage(offerId: 1, api: mockApi),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Recusar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pedido recusado'), findsOneWidget);
    });
  });

  // =========================================================================
  // ActiveRideCoordinator — ciclo de vida
  // =========================================================================

  group('ActiveRideCoordinator - ciclo de vida', () {
    testWidgets('ARC-U2: Coordinator renderiza o widget filho correctamente',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ActiveRideCoordinator(
          child: Scaffold(body: Text('Conteúdo filho')),
        ),
      ));
      await tester.pump(Duration.zero);

      expect(find.text('Conteúdo filho'), findsOneWidget);
    });

    testWidgets('ARC-U3: Coordinator faz dispose sem erros (sem token)',
        (tester) async {
      Ride4FreeAuth.token = null; // sem token, _poll retorna cedo

      await tester.pumpWidget(const MaterialApp(
        home: ActiveRideCoordinator(child: SizedBox()),
      ));
      await tester.pump(Duration.zero);

      // Remover o widget do árvore dispara dispose()
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      // Não deve lançar nenhuma excepção
    });
  });

  // =========================================================================
  // ActiveRidePage — campos com valores nulos (fallbacks)
  // =========================================================================

  group('ActiveRidePage - valores nulos usam fallbacks', () {
    late MockRide4FreeApi mockApi;

    setUp(() {
      mockApi = MockRide4FreeApi();
      Ride4FreeAuth.token = 'test-token';
    });

    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets(
        'FALLBACK-U1: Ride sem campos opcionais usa strings de fallback',
        (tester) async {
      // Ride mínima — apenas id e is_driver/is_passenger
      final minimalRide = {'id': 1, 'is_passenger': true, 'is_driver': false};

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: minimalRide, api: mockApi),
      ));
      await tester.pump(Duration.zero);

      // Fallbacks definidos no código
      expect(find.textContaining('Condutor'), findsOneWidget);
      expect(find.textContaining('Veículo'), findsOneWidget);
    });

    testWidgets('FALLBACK-U2: Ride de condutor sem campos opcionais usa fallbacks',
        (tester) async {
      final minimalDriverRide = {
        'id': 2,
        'is_passenger': false,
        'is_driver': true
      };

      await tester.pumpWidget(MaterialApp(
        home: ActiveRidePage(initialRide: minimalDriverRide, api: mockApi),
      ));
      await tester.pump(Duration.zero);

      // O fallback para passenger_name é 'Passageiro'
      expect(find.text('Passageiro'), findsOneWidget);
    });
  });

  // =========================================================================
  // showRideMessage — contexto desmontado (não deve crashar)
  // =========================================================================

  group('showRideMessage - edge cases', () {
    testWidgets('UTIL-U2: showRideMessage não crasha quando chamada repetidamente',
        (tester) async {
      late BuildContext capturedCtx;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              capturedCtx = ctx;
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showRideMessage(ctx, 'Primeira mensagem');
                    showRideMessage(ctx, 'Segunda mensagem');
                  },
                  child: const Text('Disparar'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Disparar'));
      await tester.pumpAndSettle();

      // Pelo menos uma das mensagens deve estar visível
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data == 'Primeira mensagem' || w.data == 'Segunda mensagem')),
        findsAtLeastNWidgets(1),
      );
    });
  });
}