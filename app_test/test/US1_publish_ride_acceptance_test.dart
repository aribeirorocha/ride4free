import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:app_test/main.dart';

void main() {
  group('US1: Publish Ride (Real UI Tests)', () {
    
    Future<void> launchOfferScreen(WidgetTester tester) async {
      // Carregamos diretamente a página real que vocês criaram no main.dart
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
      // O vosso código assume 3 lugares por defeito
      expect(find.text('3'), findsOneWidget); 
      
      // THEN: A recompensa matemática deve ser +30
      expect(find.text('+30 Creditos'), findsOneWidget);
      
      // E o botão vermelho "Publicar Viagem" deve estar no ecrã
      expect(find.text('Publicar Viagem'), findsOneWidget);
    });

    testWidgets('PR-2: Lotação a zero bloqueia a publicação (Validação)', (tester) async {
      await launchOfferScreen(tester);

      // GIVEN: O condutor decide reduzir os lugares para zero
      final removeSeatButton = find.byIcon(Icons.remove);
      await tester.tap(removeSeatButton); // Fica a 2
      await tester.tap(removeSeatButton); // Fica a 1
      await tester.tap(removeSeatButton); // Fica a 0
      await tester.pumpAndSettle();

      // WHEN / THEN: O ecrã tem de mostrar o erro que programaram
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Lotacao Invalida'), findsOneWidget);
      expect(find.text('Indique pelo menos 1 lugar disponivel para ganhar creditos.'), findsOneWidget);

      // E o botão "Publicar Viagem" continua visível (mas internamente está desativado pelo null)
      expect(find.text('Publicar Viagem'), findsOneWidget);
    });

    testWidgets('PR-3: Inserir novo destino no TextField', (tester) async {
      await launchOfferScreen(tester);

      // GIVEN: Encontramos a caixa de texto do destino
      final destField = find.byType(TextField);
      expect(destField, findsOneWidget);

      // WHEN: Escrevemos um novo destino
      await tester.enterText(destField, 'Estação de Campanhã');
      await tester.pumpAndSettle();

      // THEN: O texto foi atualizado no ecrã
      expect(find.text('Estação de Campanhã'), findsOneWidget);
    });
  });
}