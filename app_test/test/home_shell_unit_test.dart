import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_test/main.dart';

void main() {
  group('Unit/Widget Tests - Ride4Free App', () {

    testWidgets('UT-1: A navegação (BottomNavigationBar) troca de ecrãs corretamente', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      // O index default é 0 (CommunityBoardPage)
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);
      expect(find.text('Oferecer Boleia'), findsNothing);

      // Clicar no ícone de carro para ir para OfferRidePage (index 2)
      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();

      expect(find.text('Oferecer Boleia'), findsOneWidget);
      expect(find.text('Comunidade Ride4Free'), findsNothing);

      // Clicar no ícone de pesquisa para ir para SearchRidePage (index 1)
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

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
      await tester.pump();

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

    testWidgets('UT-3: O ecrã SearchRidePage carrega no estado inicial correto', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchRidePage())));
      await tester.pump();

      // A lista começa vazia — sem dados de API ainda
      expect(
        find.text('Procurar condutores'),
        findsOneWidget,
      );

      // O slider de tolerância de distância está presente
      expect(find.text('Raio de Tolerancia'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // O botão principal de reserva está visível
      expect(find.text('Reservar Boleia'), findsOneWidget);

      // O campo de destino está presente e com o valor por defeito
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('FEUP (Polo II)'), findsOneWidget);
    });

  });
}