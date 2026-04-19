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
  await tester.pump();
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
  // IT-NAV: HomeShell ↔ páginas filhas
  // ---------------------------------------------------------------------------
  group('IT-NAV: HomeShell → navegação entre páginas', () {
    testWidgets('NAV-IT1: index 0 carrega CommunityBoardPage', (tester) async {
      await launchApp(tester);
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);
    });

    testWidgets('NAV-IT2: tap no ícone search mostra SearchRidePage', (tester) async {
      await launchApp(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Boleias Encontradas'), findsOneWidget);
    });

    testWidgets('NAV-IT3: tap no ícone car mostra OfferRidePage', (tester) async {
      await launchApp(tester);
      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();
      expect(find.text('Oferecer Boleia'), findsOneWidget);
    });

    testWidgets('NAV-IT4: tap no ícone person mostra ProfilePage', (tester) async {
      await launchApp(tester);
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('Avaliar Passageiro'), findsOneWidget);
    });

    // NAV-IT5: usa tester.binding.window para definir um ecrã suficientemente
    // alto e evitar o overflow do flutter_map que causava a falha anterior.
    testWidgets('NAV-IT5: IndexedStack preserva estado ao navegar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await launchApp(tester);

      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // IT-OFFER: OfferRidePage — integração de widgets internos
  // ---------------------------------------------------------------------------
  group('IT-OFFER: OfferRidePage — integração de widgets internos', () {
    testWidgets('OF-IT1: _SeatPicker e _RewardPanel estão sincronizados', (tester) async {
      await launchOfferPage(tester);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('+30 Creditos'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('+40 Creditos'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('+30 Creditos'), findsOneWidget);
    });

    testWidgets('OF-IT2: _RewardPanel muda para erro quando lugares = 0', (tester) async {
      await launchOfferPage(tester);
      final remove = find.byIcon(Icons.remove);
      await tester.tap(remove);
      await tester.tap(remove);
      await tester.tap(remove);
      await tester.pump();
      expect(find.text('Lotacao Invalida'), findsOneWidget);
      expect(find.text('+30 Creditos'), findsNothing);
    });

    testWidgets('OF-IT3: botão "Publicar Viagem" fica desativado com 0 lugares', (tester) async {
      await launchOfferPage(tester);
      final remove = find.byIcon(Icons.remove);
      await tester.tap(remove);
      await tester.tap(remove);
      await tester.tap(remove);
      await tester.pump();
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Publicar Viagem'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('OF-IT4: botão "Publicar Viagem" fica ativo com 1+ lugar', (tester) async {
      await launchOfferPage(tester);
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Publicar Viagem'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('OF-IT5: TextField do destino atualiza o estado do formulário', (tester) async {
      await launchOfferPage(tester);
      await tester.enterText(find.byType(TextField), 'Porto Campanhã');
      await tester.pump();
      expect(find.text('Porto Campanhã'), findsOneWidget);
    });

    testWidgets('OF-IT6: "Publicar Viagem" sem token mostra snackbar', (tester) async {
      Ride4FreeAuth.token = null;
      await launchOfferPage(tester);
      await tester.tap(find.text('Publicar Viagem'));
      await tester.pumpAndSettle();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });
  });

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
    testWidgets('RT-IT2: adicionar perfil via "+ Add" aparece na lista ao reabrir', (tester) async {
      await launchRatingButton(tester);
      await openRatingSheet(tester);

      await tester.enterText(find.byType(TextField).first, 'Novo Utilizador');
      await tester.tap(find.text('+ Add'));
      await tester.pumpAndSettle();

      // Fecha e reabre o sheet
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await openRatingSheet(tester);

      expect(find.text('Novo Utilizador'), findsOneWidget);
    });

    testWidgets('RT-IT3: guardar avaliação fecha o sheet', (tester) async {
      await launchRatingButton(tester);
      await openRatingSheet(tester);

      await selectProfileInSheet(tester, 'Alex Rivera');
      await tapStarInSheet(tester, 'Alex Rivera', 3);
      await tapSheetFooterButton(tester, 'Save rating');

      expect(find.text('Save rating'), findsNothing);
    });

    // RT-IT4 corrigido: após Save rating, força rebuild do pai com pump()
    // para o summary card aparecer.
    testWidgets('RT-IT4: depois de guardar, summary card aparece', (tester) async {
      await launchRatingButton(tester);
      await openRatingSheet(tester);

      await selectProfileInSheet(tester, 'Sam Chen');
      await tapStarInSheet(tester, 'Sam Chen', 5);
      await tapSheetFooterButton(tester, 'Save rating');

      // Rebuild do pai após fechar o sheet
      await tester.pump();

      expect(find.text('Current ratings'), findsOneWidget);
      expect(find.text('Sam Chen'), findsOneWidget);
    });

    testWidgets('RT-IT5: Cancel fecha o sheet sem guardar', (tester) async {
      await launchRatingButton(tester);
      await openRatingSheet(tester);

      await selectProfileInSheet(tester, 'Alex Rivera');
      await tapSheetFooterButton(tester, 'Cancel');

      expect(find.text('Current ratings'), findsNothing);
    });

    testWidgets('RT-IT6: guardar sem perfil selecionado mostra snackbar', (tester) async {
      await launchRatingButton(tester);
      await openRatingSheet(tester);
      await tapSheetFooterButton(tester, 'Save rating');
      expect(find.text('Select a profile first.'), findsOneWidget);
    });

    // RT-IT7 corrigido: usa scrollUntilVisible para garantir que Maya Patel
    // está visível e hittable antes de tentar interagir.
    testWidgets('RT-IT7: guardar com 0 estrelas mostra snackbar', (tester) async {
      await launchRatingButton(tester);
      await openRatingSheet(tester);
      await selectProfileInSheet(tester, 'Maya Patel');
      await tapSheetFooterButton(tester, 'Save rating');
      expect(find.text('Choose a star rating.'), findsOneWidget);
    });

    // RT-IT8 corrigido: usa find.descendant para resolver a ambiguidade de
    // "Alex Rivera" que aparece simultaneamente no sheet e no summary card.
    testWidgets('RT-IT8: atualizar avaliação reflete no summary card', (tester) async {
      await launchRatingButton(tester);

      // Primeira avaliação: 2 estrelas
      await openRatingSheet(tester);
      await selectProfileInSheet(tester, 'Alex Rivera');
      await tapStarInSheet(tester, 'Alex Rivera', 2);
      await tapSheetFooterButton(tester, 'Save rating');
      await tester.pump();

      // Segunda avaliação: 4 estrelas
      await openRatingSheet(tester);

      // Usa find.descendant para encontrar "Alex Rivera" APENAS dentro do sheet
      final sheetFinder = find.byType(DraggableScrollableSheet);
      final listFinder = find.descendant(of: sheetFinder, matching: find.byType(ListView));
      final alexInSheet = find.descendant(of: listFinder, matching: find.text('Alex Rivera'));
      await tester.scrollUntilVisible(alexInSheet, 80, scrollable: listFinder);
      await tester.pumpAndSettle();
      await tester.tap(alexInSheet);
      await tester.pumpAndSettle();

      await tapStarInSheet(tester, 'Alex Rivera', 4);
      await tapSheetFooterButton(tester, 'Save rating');
      await tester.pump();

      // Verifica no summary card
      final summaryCard = find.ancestor(
        of: find.text('Current ratings'),
        matching: find.byType(Container),
      ).first;
      final alexInSummary = find.descendant(
        of: summaryCard,
        matching: find.text('Alex Rivera'),
      );
      final summaryRow = find.ancestor(
        of: alexInSummary,
        matching: find.byType(Row),
      ).first;
      expect(
        find.descendant(of: summaryRow, matching: find.byIcon(Icons.star_rounded)),
        findsNWidgets(4),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // IT-AUTH: Ride4FreeAuth — proteção de ações
  // ---------------------------------------------------------------------------
  group('IT-AUTH: Ride4FreeAuth — proteção de ações', () {
    testWidgets('AU-IT1: sem token, ProfilePage mostra formulário de login', (tester) async {
      Ride4FreeAuth.token = null;
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProfilePage())));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password (mín. 6)'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Registar'), findsOneWidget);
    });

    testWidgets('AU-IT2: OfferRide bloqueia publicação sem token', (tester) async {
      Ride4FreeAuth.token = null;
      await launchOfferPage(tester);
      await tester.tap(find.text('Publicar Viagem'));
      await tester.pumpAndSettle();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });

    testWidgets('AU-IT3: SearchRide bloqueia pesquisa sem token', (tester) async {
      Ride4FreeAuth.token = null;
      await launchSearchPage(tester);
      await tester.tap(find.text('Procurar condutores'));
      await tester.pumpAndSettle();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });

    testWidgets('AU-IT4: CommunityBoard bloqueia atualização sem token', (tester) async {
      Ride4FreeAuth.token = null;
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CommunityBoardPage())),
      );
      await tester.pump();
      await tester.tap(find.text('Atualizar secao'));
      await tester.pumpAndSettle();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // IT-COMM: CommunityBoardPage — integração de widgets internos
  // ---------------------------------------------------------------------------
  group('IT-COMM: CommunityBoardPage — integração de widgets internos', () {
    testWidgets('CB-IT1: SegmentedButton tem os 3 segmentos corretos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CommunityBoardPage())),
      );
      await tester.pump();
      expect(find.text('Condutores'), findsOneWidget);
      expect(find.text('Passageiros'), findsOneWidget);
      expect(find.text('BD'), findsOneWidget);
    });

    testWidgets('CB-IT2: estado inicial mostra mensagem de lista vazia', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CommunityBoardPage())),
      );
      await tester.pump();
      expect(
        find.text('Sem condutores disponiveis. Carregue em "Atualizar secao".'),
        findsOneWidget,
      );
    });

    testWidgets('CB-IT3: trocar para "Passageiros" mostra mensagem vazia correta',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CommunityBoardPage())),
      );
      await tester.pump();
      await tester.tap(find.text('Passageiros'));
      await tester.pump();
      expect(
        find.text('Sem passageiros disponiveis. Carregue em "Atualizar secao".'),
        findsOneWidget,
      );
    });
  });
}