import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:app_test/active_ride_flow.dart';
import 'package:app_test/ride4free_api.dart';

// Criamos um Mock para a API para não depender de rede real
class MockRide4FreeApi extends Mock implements Ride4FreeApi {}
// Adiciona isto perto do teu main()

void main() {
  group('ActiveRidePage - Lógica e UI', () {
    testWidgets('AR-U2: Botão de chat abre BottomSheet', (tester) async {
      final ride = {'id': 1, 'status': 'matched'};
      
      await tester.pumpWidget(MaterialApp(home: ActiveRidePage(initialRide: ride)));
      await tester.pumpAndSettle();

      // Testa se o botão flutuante de chat existe e abre algo
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pumpAndSettle();

      // Verifica se o modal (ChatSheet) abriu
      expect(find.text('Chat da Viagem'), findsOneWidget);
    });
  });

  group('ActiveRideCoordinator - Polling Logic', () {
    testWidgets('ARC-U1: Coordinator inicializa e dispara polling', (tester) async {
      // Este teste valida se o Coordinator não crasha ao iniciar
      await tester.pumpWidget(const MaterialApp(
        home: ActiveRideCoordinator(child: Scaffold(body: Text('Child'))),
      ));
      expect(find.text('Child'), findsOneWidget);
    });
  });

  group('DriverRideRequestsPage - Lista de Pedidos', () {
    testWidgets('DRR-U1: Exibe indicador de loading durante a carga', (tester) async {
      // 1. Criamos um MockClient que demora 1 segundo a responder
      // Isso dá tempo ao teste para encontrar o CircularProgressIndicator no ecrã
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 1));
        return http.Response('{"requests": []}', 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          home: DriverRideRequestsPage(offerId: 1)
        ));
        
        // 2. Usamos Duration.zero para disparar o primeiro frame imediato
        await tester.pump(Duration.zero);
        
        // 3. Agora ele deve encontrar o CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // 4. Depois, esperamos que o loading termine
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }, () => mockClient);
    });
  });
}