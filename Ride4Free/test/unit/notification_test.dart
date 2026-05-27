import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Ajusta os imports para o teu projeto
import 'package:Ride4Free/ride_notification_service.dart'; 
import 'package:Ride4Free/ride4free_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RideNotificationHub — Lógica e Notificações Blindada', () {
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      FlutterLocalNotificationsPlatform.instance = AndroidFlutterLocalNotificationsPlugin();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'initialize' || 
              methodCall.method == 'requestNotificationsPermission' ||
              methodCall.method == 'requestPermission') {
            return true;
          }
          return null; 
        },
      );
    });

    test('RNH-1: Cobertura total via MockClient e Refresh', () async {
      // 1. Criar o MockClient primeiro
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        final path = request.url.path;

        if (callCount <= 2) {
          // Respostas da 1ª Chamada
          if (path.contains('driver/incoming')) {
            return http.Response(jsonEncode({'requests': [{ 'id': 1, 'status': 'pending', 'last_message_at': 'T1', 'passenger_name': 'João' }]}), 200);
          }
          if (path.contains('passenger/my-join')) {
            return http.Response(jsonEncode({'requests': [{ 'id': 2, 'status': 'accepted', 'last_message_at': 'T1', 'needs_passenger_confirmation': true }, { 'id': 3, 'status': 'accepted', 'last_message_at': 'T1', 'driver_user_id': 99, 'last_message_sender_id': 99, 'last_message_body': 'Olá' }]}), 200);
          }
        } else {
          // Respostas da 2ª Chamada (força a ativação dos RideAlerts)
          if (path.contains('driver/incoming')) {
            return http.Response(jsonEncode({'requests': [{ 'id': 1, 'status': 'pending', 'last_message_at': 'T2', 'passenger_name': 'João' }]}), 200);
          }
          if (path.contains('passenger/my-join')) {
            return http.Response(jsonEncode({'requests': [{ 'id': 2, 'status': 'accepted', 'last_message_at': 'T2', 'needs_passenger_confirmation': true }, { 'id': 3, 'status': 'accepted', 'last_message_at': 'T2', 'driver_user_id': 99, 'last_message_sender_id': 99, 'last_message_body': 'Cheguei' }]}), 200);
          }
        }
        return http.Response(jsonEncode({}), 200);
      });

      // 2. ENVOLVER TUDO NO RUNWITHCLIENT
      // Como o Singleton nunca foi tocado antes, o construtor da API que vive
      // dentro do RideNotificationHub vai apanhar o nosso MockClient!
      await http.runWithClient(() async {
        
        // Colocamos o token e instanciamos o Singleton apenas AQUI DENTRO
        Ride4FreeAuth.token = 'token_valido_cobertura';
        final hub = RideNotificationHub.instance;
        
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        await hub.initialize();

        // Primeira passagem (firstPoll = true) -> Regista as viagens sem disparar alertas
        await hub.refresh();

        // Segunda passagem -> Apanha a mudança nos dados (T1 para T2) e dispara o checkItem e Notificações!
        await hub.refresh();

        // Validação épica: o mock funcionou e a contagem foi atualizada
        expect(hub.unreadCount, equals(3));
        
        // Limpar o singleton antes do teste fechar
        hub.reset();

      }, () => mockClient);
    });
  });
}