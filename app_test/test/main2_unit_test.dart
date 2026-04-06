import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:app_test/main2.dart'; 

void main() {
  group('Unit & Widget Tests - Counter & Rating App', () {

    // ── Teste Unitário Puro ──────────────────────────────────────────────
    test('UT-1: O modelo Profile deve assumir os valores por defeito corretos', () {
      final profile = Profile(id: 99, name: 'Engenharia Software');

      expect(profile.id, 99);
      expect(profile.name, 'Engenharia Software');
      expect(profile.role, 'Team member'); // Valor default que definiste
      expect(profile.stars, 0);            // Valor default que definiste
    });

    // ── Testes de Widget (Interface Gráfica) ─────────────────────────────
    testWidgets('WT-1: O botão do contador (Smoke Test) soma corretamente', (tester) async {
      await tester.pumpWidget(MyApp());

      // Verifica que o contador começa a 0
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Clica no botão flutuante '+'
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(); // Atualiza o ecrã

      // Verifica que passou para 1
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('WT-2: Abre a folha de avaliações (BottomSheet) e adiciona um perfil', (tester) async {
      await tester.pumpWidget(MyApp());

      // Clica no botão "Rate profiles"
      await tester.tap(find.text('Rate profiles'));
      await tester.pumpAndSettle(); // Espera que a animação da BottomSheet termine

      // Verifica se a folha abriu corretamente
      expect(find.text('Choose a profile to rate'), findsOneWidget);

      // Escreve o nome de um novo condutor no TextField
      await tester.enterText(find.byType(TextField), 'Novo Condutor Teste');
      
      // Clica no botão "+ Add"
      await tester.tap(find.text('+ Add'));
      await tester.pumpAndSettle();

      // Verifica se o novo condutor apareceu na lista com a role default
      expect(find.text('Novo Condutor Teste'), findsOneWidget);
      expect(find.text('Team member'), findsOneWidget); 
    });

    testWidgets('WT-3: Avalia um perfil e verifica se o Cartão de Resumo aparece', (tester) async {
      await tester.pumpWidget(MyApp());

      // Confirma que o painel de resumo NÃO existe no início
      expect(find.text('Current ratings'), findsNothing);

      // Abre a folha
      await tester.tap(find.text('Rate profiles'));
      await tester.pumpAndSettle();

      // Seleciona a "Maya Patel"
      await tester.tap(find.text('Maya Patel'));
      await tester.pumpAndSettle();

      // Dá-lhe um rating clicando numa das estrelas vazias
      // Como a Maya começa com 0 estrelas, clicamos na primeira estrela do ecrã
      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pumpAndSettle();

      // Guarda a avaliação
      await tester.tap(find.text('Save rating'));
      await tester.pumpAndSettle(); // Espera que a folha feche

      // Agora o painel de resumo "Current ratings" JÁ TEM de estar visível
      expect(find.text('Current ratings'), findsOneWidget);
      
      // A Maya Patel tem de aparecer no cartão de resumo no ecrã principal
      expect(find.text('Maya Patel'), findsOneWidget);
    });

  });
}