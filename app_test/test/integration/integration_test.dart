// =============================================================================
// INTEGRATION TESTS — Ride4Free
// =============================================================================


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_test/main.dart';
import 'package:app_test/profile_rating_button.dart';
import 'package:app_test/ride4free_api.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> launchApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
}

Future<void> launchOfferPage(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: OfferRidePage())));
  await tester.pump();
}

Future<void> launchSearchPage(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchRidePage())));
  await tester.pump();
}

Future<void> launchRatingButton(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ProfileRatingButton(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openRatingSheet(WidgetTester tester) async {
  await tester.tap(find.text('Rate profiles'));
  await tester.pumpAndSettle();
}

/// Toca numa estrela dentro do sheet, usando scrollUntilVisible para garantir
/// que o perfil está visível antes de interagir.
Future<void> tapStarInSheet(WidgetTester tester, String profileName, int starIndex) async {
  final sheetFinder = find.byType(DraggableScrollableSheet);
  final listFinder = find.descendant(of: sheetFinder, matching: find.byType(ListView));

  // Faz scroll até o nome estar visível
  final nameFinder = find.descendant(of: listFinder, matching: find.text(profileName));
  await tester.scrollUntilVisible(nameFinder, 80, scrollable: listFinder);
  await tester.pumpAndSettle();

  // Encontra a linha (InkWell) do perfil
  final profileRow = find.ancestor(of: nameFinder, matching: find.byType(InkWell)).first;

  // Encontra as estrelas dentro dessa linha
  final starsInRow = find.descendant(
    of: profileRow,
    matching: find.byWidgetPredicate(
      (w) => w is Icon &&
          (w.icon == Icons.star_rounded || w.icon == Icons.star_outline_rounded),
    ),
  );

  await tester.tap(starsInRow.at(starIndex - 1));
  await tester.pumpAndSettle();
}

/// Seleciona um perfil pelo nome dentro do sheet (com scroll se necessário).
Future<void> selectProfileInSheet(WidgetTester tester, String name) async {
  // Encontra o texto com o nome do perfil
  final target = find.text(name);
  
  // O truque mágico: procurar pelo motor de Scroll em vez da ListView!
  final scrollableFinder = find.descendant(
    of: find.byType(DraggableScrollableSheet),
    matching: find.byType(Scrollable),
  );

  // Faz scroll até o nome aparecer
  await tester.scrollUntilVisible(target, 80, scrollable: scrollableFinder);
  await tester.pumpAndSettle();
  
  // Clica no perfil
  await tester.tap(target);
  await tester.pumpAndSettle();
}
/// Toca no botão do footer do sheet (Save rating / Cancel), fazendo drag se necessário.
Future<void> tapSheetFooterButton(WidgetTester tester, String label) async {
  final sheetFinder = find.byType(DraggableScrollableSheet);
  final btn = find.descendant(of: sheetFinder, matching: find.text(label));
  if (tester.getTopLeft(btn).dy > 700) {
    await tester.drag(sheetFinder, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

void main() {


  // ---------------------------------------------------------------------------
  // IT-SEARCH: SearchRidePage — integração de widgets internos
  // ---------------------------------------------------------------------------
  group('IT-SEARCH: SearchRidePage — integração de widgets internos', () {
    testWidgets('SR-IT1: Slider de tolerância e label coexistem', (tester) async {
      await launchSearchPage(tester);
      expect(find.text('Raio de Tolerancia'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('SR-IT2: botão "Reservar Boleia" está visível por defeito', (tester) async {
      await launchSearchPage(tester);
      expect(find.text('Reservar Boleia'), findsOneWidget);
    });

    testWidgets('SR-IT3: sem token, "Pedir boleia" mostra snackbar', (tester) async {
      Ride4FreeAuth.token = null;
      await launchSearchPage(tester);
      await tester.tap(find.text('Pedir boleia'));
      await tester.pumpAndSettle();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });

    testWidgets('SR-IT4: sem token, "Procurar condutores" mostra snackbar', (tester) async {
      Ride4FreeAuth.token = null;
      await launchSearchPage(tester);
      await tester.tap(find.text('Procurar condutores'));
      await tester.pumpAndSettle();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });

    testWidgets('SR-IT5: TextField do destino aceita nova entrada', (tester) async {
      await launchSearchPage(tester);
      final field = find.byType(TextField);
      await tester.enterText(field, 'ISEP');
      await tester.pump();
      expect(find.text('ISEP'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // IT-RATING: ProfileRatingButton ↔ _RatingSheet
  // ---------------------------------------------------------------------------
  group('IT-RATING: ProfileRatingButton ↔ _RatingSheet', () {
    testWidgets('RT-IT1: abrir sheet mostra os perfis default', (tester) async {
      await launchRatingButton(tester);
      await openRatingSheet(tester);
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Sam Chen'), findsOneWidget);
      expect(find.text('Maya Patel'), findsOneWidget);
    });

    // RT-IT2 corrigido: fecha e reabre o sheet para verificar o perfil adicionado,
    // porque onAddProfile atualiza o pai e o sheet só recebe a lista nova ao reabrir.


    testWidgets('RT-IT6: guardar sem perfil selecionado mostra snackbar', (tester) async {
      await launchRatingButton(tester);
      await openRatingSheet(tester);
      await tapSheetFooterButton(tester, 'Save rating');
      expect(find.text('Select a profile first.'), findsOneWidget);
    });

   
  // ---------------------------------------------------------------------------
  // IT-AUTH: Ride4FreeAuth — proteção de ações
  // ---------------------------------------------------------------------------
  group('IT-AUTH: Ride4FreeAuth — proteção de ações', () {


    testWidgets('AU-IT3: SearchRide bloqueia pesquisa sem token', (tester) async {
      Ride4FreeAuth.token = null;
      await launchSearchPage(tester);
      await tester.tap(find.text('Procurar condutores'));
      await tester.pumpAndSettle();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });

  });

  // ---------------------------------------------------------------------------
  // IT-COMM: CommunityBoardPage — integração de widgets internos
  // ---------------------------------------------------------------------------
});
}