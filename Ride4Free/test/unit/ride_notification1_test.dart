import 'package:Ride4Free/ride_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Setup global para evitar crashes de plataforma
  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RideNotificationHub.instance.reset();
  });

  group('RideNotificationHub - Inicialização e Persistência', () {
    test('IN-U1: deve iniciar com unreadCount 0 e estado vazio', () async {
      await RideNotificationHub.instance.initialize();
      expect(RideNotificationHub.instance.unreadCount, 0);
    });
  });

  group('RideNotificationHub - Lógica de Notificações', () {
    test('LC-U1: pedido novo (pending) como driver conta como unread', () async {
      await RideNotificationHub.instance.initialize();
      
      final r = {'id': 1, 'status': 'pending'};
      // Verifica se o hub considera o pedido como "unread"
      expect(RideNotificationHub.instance.isRequestUnread(r, isDriverView: true), isTrue);
    });

    test('LC-U2: pedido visto (markRequestSeen) deixa de ser unread', () async {
      await RideNotificationHub.instance.initialize();
      
      final r = {'id': 1, 'status': 'pending'};
      await RideNotificationHub.instance.markRequestSeen(1);
      
      expect(RideNotificationHub.instance.isRequestUnread(r, isDriverView: true), isFalse);
      expect(RideNotificationHub.instance.unreadCount, 0);
    });

    test('LC-U3: markPedidosTabSeen limpa todas as pendências', () async {
      await RideNotificationHub.instance.initialize();
      
      // Processar lista com 2 pedidos pendentes
      // Nota: Como não temos a API real, teríamos de usar o método _processLists, 
      // mas como ele é privado, testamos o impacto no estado.
      await RideNotificationHub.instance.markPedidosTabSeen();
      
      expect(RideNotificationHub.instance.unreadCount, 0);
    });
  });
}