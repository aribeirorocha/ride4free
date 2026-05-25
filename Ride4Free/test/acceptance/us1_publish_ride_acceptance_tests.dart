// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Ride4Free/main.dart';

void main() {
  group('US1: Publish Ride (Real UI Tests)', () {
    
    Future<void> launchOfferScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OfferRidePage()), 
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('PR-1: Valores iniciais e botão de publicar visível', (tester) async {
      await launchOfferScreen(tester);

      // GIVEN: O ecrã carrega com os valores por defeito
      // O código assume 3 lugares por defeito
      expect(find.text('3'), findsOneWidget); 
      
      // THEN: A recompensa matemática deve ser +30
      expect(find.text('+30 Créditos'), findsOneWidget);
      
      // E o botão vermelho "Publicar Viagem" deve estar no ecrã
      expect(find.text('Publicar Viagem'), findsOneWidget);
    });

    testWidgets('PR-2: Lotação a zero bloqueia a publicação (Validação)', (tester) async {
      await launchOfferScreen(tester);

      // GIVEN: O condutor decide reduzir os lugares para zero
      // Encontrar o botão de remover (ícone de menos)
      final removeSeatButton = find.byIcon(Icons.remove);
      
      // Clicar 3 vezes para chegar a 0
      await tester.tap(removeSeatButton); // 3 -> 2
      await tester.pumpAndSettle();
      await tester.tap(removeSeatButton); // 2 -> 1
      await tester.pumpAndSettle();
      await tester.tap(removeSeatButton); // 1 -> 0
      await tester.pumpAndSettle();

      // WHEN / THEN: O ecrã tem de mostrar o erro
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Lotacao Invalida'), findsOneWidget);
      expect(find.text('Indique pelo menos 1 lugar disponivel para ganhar créditos.'), findsOneWidget);

      // E o botão "Publicar Viagem" continua visível (mas desativado)
      expect(find.text('Publicar Viagem'), findsOneWidget);
    });

    testWidgets('PR-3: Inserir novo destino no TextField', (tester) async {
      await launchOfferScreen(tester);

      // GIVEN: Encontramos a caixa de texto do destino pela key
      final destField = find.byKey(const Key('destination_field'));
      expect(destField, findsOneWidget);

      // WHEN: Escrevemos um novo destino
      await tester.enterText(destField, 'Estação de Campanhã');
      await tester.pumpAndSettle();

      // THEN: O texto foi atualizado no ecrã
      expect(find.text('Estação de Campanhã'), findsOneWidget);
    });
  });
}