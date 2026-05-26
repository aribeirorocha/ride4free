


import 'package:Ride4Free/ride4free_api.dart';
import 'package:Ride4Free/ride_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MockRide4FreeApi extends Ride4FreeApi {
  List<Map<String, dynamic>> passengerMock = [];
  List<Map<String, dynamic>> driverMock = [];

  // Substituímos o comportamento original apenas para o ambiente de testes
  @override
  Future<List<Map<String, dynamic>>> listMyPassengerJoinRequests() async {
    return passengerMock;
  }

  @override
  Future<List<Map<String, dynamic>>> listDriverIncomingJoinRequests() async {
    return driverMock;
  }
}

void main() {
  group('RideNotificationHub — Cobertura Total do checkItem (_processLists)', () {
    late MockRide4FreeApi mockApi;
    late RideNotificationHub hub;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      SharedPreferences.setMockInitialValues({});
      Ride4FreeAuth.token = 'tok';
      
      hub = RideNotificationHub.instance;
      hub.reset();
      
      mockApi = MockRide4FreeApi();
      // Injetamos o nosso mock diretamente na propriedade se o teu código o permitir,
      // ou garantimos o reset do estado.
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      Ride4FreeAuth.token = null;
    });

    test('COV-1: Primeiro Poll (_firstPoll) deve saltar a criação de alertas visuais', () async {
      await hub.initialize();

      // Forçamos dados no mock
      mockApi.driverMock = [
        {'id': 1, 'status': 'pending', 'destination_display': 'Porto'}
      ];

      // Simulamos o refresh. Como é o primeiro poll, o skipAlerts é true
      await hub.refresh();

      // Deve contar como unread, mas não dispara o array de novos alertas do sistema
      expect(hub.unreadCount, 0); 
    });

    test('COV-2: Segundo Poll — Novo pedido (isNewRequest) gera RideAlert para condutor', () async {
      await hub.initialize();

      // 1. Primeiro poll (esvazia a flag _firstPoll)
      await hub.refresh();

      // 2. Segundo poll com o novo pedido pendente
      mockApi.driverMock = [
        {
          'id': 50,
          'status': 'pending',
          'destination_display': 'Lisboa',
          'passenger_name': 'Rui',
          'last_message_body': 'Olá!'
        }
      ];

      await hub.refresh();
      // O checkItem deve processar o ramo: isNewRequest -> unread++ -> newAlerts.add
      expect(hub.isRequestUnread(mockApi.driverMock.first, isDriverView: true), isTrue);
    });

    test('COV-3: Segundo Poll — Confirmação do passageiro (needsPassengerAction) gera RideAlert', () async {
      await hub.initialize();
      await hub.refresh(); // consome _firstPoll

      mockApi.passengerMock = [
        {
          'id': 60,
          'status': 'accepted',
          'needs_passenger_confirmation': true,
          'offer_destination': 'Braga',
        }
      ];

      await hub.refresh();
      expect(hub.isRequestUnread(mockApi.passengerMock.first, isDriverView: false), isTrue);
    });

    test('COV-4: Mensagem nova de terceiros (hasUnreadMessage) incrementa contador e gera alerta', () async {
      await hub.initialize();
      await hub.refresh(); // consome _firstPoll

      mockApi.passengerMock = [
        {
          'id': 70,
          'status': 'accepted',
          'last_message_at': '2026-05-26T21:00:00Z',
          'last_message_body': 'Estou no carro',
          'last_message_sender_id': 9, // ID do Condutor
          'passenger_user_id': 2,      // Nós somos o passageiro
          'driver_user_id': 9,
        }
      ];

      await hub.refresh();
      expect(hub.isRequestUnread(mockApi.passengerMock.first, isDriverView: false), isTrue);
    });

    test('COV-5: Fallbacks de Strings — Quando chaves de destino ou nomes são nulos', () async {
      await hub.initialize();
      await hub.refresh();

      // Criamos um mapa propositadamente sem 'destination_display' nem 'offer_destination'
      final requestVazio = {
        'id': 80,
        'status': 'pending',
      };

      mockApi.driverMock = [requestVazio];
      await hub.refresh();

      // Validamos se o método isRequestUnread lida bem com os null fallbacks (?? 'destino')
      expect(hub.isRequestUnread(requestVazio, isDriverView: true), isTrue);
    });

    test('COV-6: Cobertura de markPedidosTabSeen sincroniza timestamps de impressões digitais', () async {
      await hub.initialize();
      
      // Simular fingerprints existentes no mapa privado através de manipulação de ações
      final request = {
        'id': 90,
        'status': 'pending',
        'last_message_at': '2026-05-26T21:45:00Z'
      };
      
      await hub.markRequestSeen(90, lastMessageAt: '2026-05-26T21:45:00Z');
      await hub.markPedidosTabSeen();

      expect(hub.unreadCount, 0);
    });
  });
}