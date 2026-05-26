import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Ride4Free/profile_rating_button.dart';

void main() {
  // Helper para montar o widget num ambiente limpo
  Future<void> loadRatingButton(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: ProfileRatingButton(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Integration - ProfileRatingButton & RatingSheet', () {
    
    testWidgets('RAT-IT1: Deve abrir o sheet e listar perfis iniciais', (tester) async {
      await loadRatingButton(tester);

      // Clica no botão para abrir o sheet
      await tester.tap(find.text('Rate profiles'));
      await tester.pumpAndSettle();

      // Verifica se o título do sheet aparece
      expect(find.text('Give Recent drivers an avaliation'), findsOneWidget);
      
      // Verifica se os perfis padrão estão lá
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Sam Chen'), findsOneWidget);
    });



    testWidgets('RAT-IT3: Deve permitir avaliar um perfil e mostrar no Summary Card', (tester) async {
      await loadRatingButton(tester);
      
      // 1. Abrir Sheet
      await tester.tap(find.text('Rate profiles'));
      await tester.pumpAndSettle();

      // 2. Selecionar 'Alex Rivera'
      await tester.tap(find.text('Alex Rivera'));
      await tester.pumpAndSettle();

      // 3. Tocar na 4ª estrela (índice 3 do Row de estrelas)
      // Procuramos o StarPicker dentro do item selecionado
      final starIcon = find.byIcon(Icons.star_outline_rounded).at(3); 
      await tester.tap(starIcon);
      await tester.pumpAndSettle();

      // 4. Salvar
      await tester.tap(find.text('Save rating'));
      await tester.pumpAndSettle();

      // 5. Verificar se o Summary Card apareceu no ecrã principal com os dados corretos
      expect(find.text('Current ratings'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsOneWidget);
      
      // Verifica se existem 4 estrelas preenchidas no card principal
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    });

    testWidgets('RAT-IT4: Cancelar não deve guardar alterações', (tester) async {
      await loadRatingButton(tester);
      await tester.tap(find.text('Rate profiles'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maya Patel'));
      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      
      // Clica em Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // O Summary Card não deve existir
      expect(find.text('Current ratings'), findsNothing);
    });

    testWidgets('RAT-IT5: Erro ao tentar salvar sem selecionar perfil', (tester) async {
      await loadRatingButton(tester);
      await tester.tap(find.text('Rate profiles'));
      await tester.pumpAndSettle();

      // Tenta salvar sem clicar em ninguém
      await tester.tap(find.text('Save rating'));
      await tester.pump(); // Inicia animação do SnackBar

      expect(find.text('Select a profile first.'), findsOneWidget);
    });
  });
}