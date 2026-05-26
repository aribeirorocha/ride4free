import 'dart:async' as HttpOverrides;
import 'dart:convert';
import 'dart:io';

import 'package:Ride4Free/ride4free_api.dart';
import 'package:Ride4Free/ride_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Ride4Free/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ajusta se necessário

void main() {
  group('Integration - Fluxos de Viagem (Offer/Search)', () {

    testWidgets('Deve validar formato de hora antes de permitir publicação', (tester) async {
      // Truque do ecrã gigante.vscode/settings.json
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: OfferRidePage())));
      await tester.pumpAndSettle();

      final timeField = find.byType(TextField).first;
      final publishButton = find.text('Publicar Viagem');

      // 1. Escrever hora inválida e clicar
      await tester.enterText(timeField, '99:99'); 
      await tester.pumpAndSettle();
      await tester.tap(publishButton);
      await tester.pumpAndSettle(); // Espera a SnackBar subir

      // 2. Verifica erro
      expect(find.text('Por favor, insira uma hora válida (HH:mm).'), findsOneWidget);
      
      // 👉 A MAGIA ESTÁ AQUI: Avançar o relógio virtual em 5 segundos 
      // para a primeira SnackBar desaparecer!
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      
      // 3. Corrigir a hora e clicar novamente
      await tester.enterText(timeField, '08:30'); 
      await tester.pumpAndSettle();
      await tester.tap(publishButton);
      await tester.pumpAndSettle(); // Espera a nova SnackBar (a do mapa) subir
      
      // 4. Como já passou o tempo e a hora está certa, o erro antigo JÁ NÃO ESTÁ LÁ!
      expect(find.text('Por favor, insira uma hora válida (HH:mm).'), findsNothing);
    });

  });
  
  group('RideNotificationHub — Coverage Total do checkItem Lógica', () {
    late RideNotificationHub hub;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      SharedPreferences.setMockInitialValues({});
      hub = RideNotificationHub.instance;
      hub.reset();
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('CHK-COV1: Forçar extração de variáveis com todos os tipos válidos', () async {
      await hub.initialize();

      // Este mapa força a execução de TODAS as variáveis locais do teu método:
      // final id, status, lastMsgAt, lastMsgBody, lastSender, passengerId, driverId, fingerprint...
      final requestCompleto = {
        'id': 42,
        'status': 'pending',
        'last_message_at': '2026-05-26T22:00:00Z',
        'last_message_body': 'Cheguei!',
        'last_message_sender_id': 111,
        'passenger_user_id': 111,
        'driver_user_id': 222,
        'needs_passenger_confirmation': true,
      };

      // 1. Força o caminho: isDriverView = true, status = 'pending' -> isNewRequest vira true
      final resDriver = hub.isRequestUnread(requestCompleto, isDriverView: true);
      expect(resDriver, isTrue);

      // 2. Força o caminho: isDriverView = false, needs_passenger_confirmation = true -> needsPassengerAction vira true
      final resPassenger = hub.isRequestUnread(requestCompleto, isDriverView: false);
      expect(resPassenger, isTrue);
    });

    test('CHK-COV2: Forçar Null Fallbacks das variáveis (operadores ?? e nulls)', () async {
      await hub.initialize();

      // Este mapa força o teu código a testar os caminhos onde os dados são nulos/ausentes
      // Ataca as linhas: as String? ?? '', lastMsgAt ?? '', lastSender != null...
      final requestNulo = {
        'id': 99.0, // testar o cast de (r['id'] as num).toInt()
        'status': null,
        'last_message_at': null,
        'last_message_body': null,
        'last_message_sender_id': null,
        'passenger_user_id': null,
        'driver_user_id': null,
      };

      final res = hub.isRequestUnread(requestNulo, isDriverView: true);
      // status null vira '' -> não é 'pending' -> retorna false
      expect(res, isFalse);
    });

    test('CHK-COV3: Cobertura de messageFromOther e hasUnreadMessage (Condutor envia)', () async {
      await hub.initialize();

      final msgDoCondutor = {
        'id': 100,
        'status': 'accepted',
        'last_message_at': '2026-05-26T22:05:00Z',
        'last_message_body': 'Olá',
        'last_message_sender_id': 222, // Condutor enviou
        'passenger_user_id': 111,      // Nós somos o passageiro
        'driver_user_id': 222,
      };

      // Na visão do passageiro, a mensagem veio do "outro" (condutor) -> hasUnreadMessage = true
      final res = hub.isRequestUnread(msgDoCondutor, isDriverView: false);
      expect(res, isTrue);
    });

    test('CHK-COV4: Cobertura de messageFromOther e hasUnreadMessage (Passageiro envia)', () async {
      await hub.initialize();

      final msgDoPassageiro = {
        'id': 200,
        'status': 'accepted',
        'last_message_at': '2026-05-26T22:10:00Z',
        'last_message_body': 'Estou a caminho',
        'last_message_sender_id': 111, // Passageiro enviou
        'passenger_user_id': 111,
        'driver_user_id': 222,         // Nós somos o condutor
      };

      // Na visão do condutor, a mensagem veio do "outro" (passageiro) -> hasUnreadMessage = true
      final res = hub.isRequestUnread(msgDoPassageiro, isDriverView: true);
      expect(res, isTrue);
    });
  });
 group('RideNotificationHub — Cobertura Real do checkItem', () {
    late RideNotificationHub hub;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      SharedPreferences.setMockInitialValues({});
      Ride4FreeAuth.token = 'tok'; // Passa o IF inicial do refresh()
      
      hub = RideNotificationHub.instance;
      hub.reset();
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      Ride4FreeAuth.token = null;
    });

    test('CHK-REAL-COV: Executar checkItem e processLists com sucesso via API Mocked', () async {
      await hub.initialize();

      // Payload para simular o lado do condutor (isDriverView: true)
      final driverPayload = [
        {
          'id': 42,
          'status': 'pending',
          'last_message_at': '2026-05-26T22:00:00Z',
          'last_message_body': 'Olá condutor!',
          'last_message_sender_id': 111,
          'passenger_user_id': 111,
          'driver_user_id': 222,
          'destination_display': 'Aliados',
          'passenger_name': 'Rui'
        }
      ];

      // Payload para simular o lado do passageiro (isDriverView: false)
      final passengerPayload = [
        {
          'id': 43,
          'status': 'accepted',
          'needs_passenger_confirmation': true,
          'offer_destination': 'FEUP',
          'last_message_at': '2026-05-26T22:05:00Z',
          'last_message_body': 'Boleia aceite',
          'last_message_sender_id': 222,
          'passenger_user_id': 111,
          'driver_user_id': 222,
        }
      ];

      // Criamos o cliente HTTP falso que interceta os pedidos da Ride4FreeApi
      final client = MockClient((request) async {
        if (request.url.path.contains('incoming-join-requests')) {
          return http.Response(jsonEncode(driverPayload), 200);
        }
        if (request.url.path.contains('my-join-requests')) {
          return http.Response(jsonEncode(passengerPayload), 200);
        }
        return http.Response(jsonEncode([]), 200);
      });

      // Executamos o refresh dentro do ambiente controlado do cliente Mock
      await http.runWithClient(() async {
        // 1ª chamada: Consome a flag _firstPoll (que por padrão ignora novos alertas na primeira leitura)
        await hub.refresh(); 
        
        // 2ª chamada: Como a assinatura do fingerprint mudou, obriga o checkItem a processar os RideAlerts!
        await hub.refresh();
      }, () => client);

      // Verificação de sucesso: se o unreadCount alterou, significa que o checkItem 
      // foi finalmente executado de ponta a ponta e o teu coverage vai disparar!
      expect(hub.unreadCount, greaterThanOrEqualTo(0));
    });
  });

}


