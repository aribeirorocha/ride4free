import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:app_test/main.dart';

void main() {
  group('Unit/Widget Tests - Ride4Free App', () {

    testWidgets('UT-1: A navegação (BottomNavigationBar) troca de ecrãs corretamente', (tester) async {
      await tester.pumpWidget(const MyApp());

      // O index default é 1 (OfferRidePage)
      expect(find.text('Oferecer Boleia'), findsOneWidget);
      expect(find.text('Boleias Encontradas'), findsNothing);

      // Clicar no primeiro ícone (Search)
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(); // Espera que a animação termine

      // Agora deve estar no ecrã de pesquisa
      expect(find.text('Boleias Encontradas'), findsOneWidget);
      expect(find.text('Oferecer Boleia'), findsNothing);
    });

    testWidgets('UT-2: Lógica de Adicionar/Remover Lugares na OfferRidePage', (tester) async {
      // Isolamos o widget OfferRidePage para teste
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: OfferRidePage())));

      // O valor inicial de lugares é 3, então a recompensa deve ser +30
      expect(find.text('3'), findsOneWidget);
      expect(find.text('+30 Creditos'), findsOneWidget);

      // Vamos encontrar o botão de diminuir (-)
      final removeIcon = find.byIcon(Icons.remove);

      // Clicar 3 vezes para meter os lugares a zero
      await tester.tap(removeIcon);
      await tester.tap(removeIcon);
      await tester.tap(removeIcon);
      await tester.pump(); // Atualiza o ecrã

      // Verifica se a lógica bloqueou nos 0 lugares e ativou o erro
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Lotacao Invalida'), findsOneWidget);
      expect(find.text('+30 Creditos'), findsNothing);

      // Agora vamos adicionar 1 lugar
      final addIcon = find.byIcon(Icons.add);
      await tester.tap(addIcon);
      await tester.pump();

      // A lotação é 1, a recompensa deve ser automaticamente calculada (+10)
      expect(find.text('1'), findsOneWidget);
      expect(find.text('+10 Creditos'), findsOneWidget);
    });

    testWidgets('UT-3: O ecrã SearchRidePage mostra a lista de condutores estática', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchRidePage())));

      // Verifica se a lista foi gerada com os nomes corretos
      expect(find.text('Joao Silva'), findsOneWidget);
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('Ricardo Pereira'), findsOneWidget);
      
      // Verifica se o botão de reserva está presente
      expect(find.text('Reservar Boleia'), findsOneWidget);
    });
    
  });
}