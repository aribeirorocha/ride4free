import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Ajustem o path se necessário!
import 'package:Ride4Free/main.dart'; 

void main() {
  group('US2 - Book Ride (Real UI Tests)', () {
    
    // Helper para lançar o ecrã real de pesquisa e reserva
    Future<void> launchSearchScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          // Agora usamos o ecrã a sério que está no main.dart
          home: Scaffold(body: SearchRidePage()), 
        ),
      );
      // Usamos apenas pump() em vez de pumpAndSettle() porque o componente do Mapa 
      // pode ficar num loop infinito de animação à espera da Internet nos testes.
      await tester.pump(); 
    }

    testWidgets('SB-1: Interface de Pesquisa carrega corretamente (Elementos Base)', (tester) async {
      await launchSearchScreen(tester);

      // GIVEN: O utilizador entra no ecrã de procurar boleia
      // THEN: A secção de controlo de distância (Raio de Tolerância) tem de existir
      expect(find.text('Raio de Tolerancia'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // E o botão gigante vermelho de reservar a boleia tem de estar desenhado
      expect(find.text('Reservar Boleia'), findsOneWidget);
    });
  });
}