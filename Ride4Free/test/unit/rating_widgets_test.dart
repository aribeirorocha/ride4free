import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:Ride4Free/rating_widgets.dart';
import 'package:Ride4Free/ride4free_api.dart';

// Fake sem geração de código — mocktail já está no teu pubspec.yaml
class _MockApi extends Mock implements Ride4FreeApi {}

void main() {

  // ===========================================================================
  // UT-AVG: averageCriteria
  // ===========================================================================
  group('averageCriteria', () {
    test('AV-U1: mapa vazio devolve 0', () {
      expect(averageCriteria({}), 0);
    });

    test('AV-U2: critério único devolve o próprio valor', () {
      expect(averageCriteria({'pontualidade': 3}), 3);
    });

    test('AV-U3: todos a 4 devolve 4', () {
      expect(averageCriteria({
        'pontualidade': 4,
        'simpatia': 4,
        'limpeza_veiculo': 4,
        'comunicacao': 4,
      }), 4);
    });

    test('AV-U4: 2.5 arredonda para 3', () {
      expect(averageCriteria({'a': 2, 'b': 3}), 3);
    });

    test('AV-U5: 2.33 arredonda para 2', () {
      expect(averageCriteria({'a': 2, 'b': 2, 'c': 3}), 2);
    });

    test('AV-U6: 3.5 arredonda para 4', () {
      expect(averageCriteria({
        'pontualidade': 1,
        'simpatia': 3,
        'limpeza_veiculo': 5,
        'comunicacao': 5,
      }), 4);
    });

    test('AV-U7: todos a 5 devolve 5', () {
      expect(averageCriteria({
        'pontualidade': 5,
        'simpatia': 5,
        'limpeza_veiculo': 5,
        'comunicacao': 5,
      }), 5);
    });

    test('AV-U8: todos a 1 devolve 1', () {
      expect(averageCriteria({
        'pontualidade': 1,
        'simpatia': 1,
        'limpeza_veiculo': 1,
        'comunicacao': 1,
      }), 1);
    });
  });

  // ===========================================================================
  // UT-CRIT: ratingCriteriaLabels
  // ===========================================================================
  group('ratingCriteriaLabels', () {
    test('CR-U1: tem exactamente 4 entradas', () {
      expect(ratingCriteriaLabels.length, 4);
    });

    test('CR-U2: label de pontualidade correcto', () {
      expect(ratingCriteriaLabels['pontualidade'], 'Pontualidade');
    });

    test('CR-U3: label de simpatia correcto', () {
      expect(ratingCriteriaLabels['simpatia'], 'Simpatia');
    });

    test('CR-U4: label de limpeza_veiculo correcto', () {
      expect(ratingCriteriaLabels['limpeza_veiculo'], 'Limpeza do veículo');
    });

    test('CR-U5: label de comunicacao correcto', () {
      expect(ratingCriteriaLabels['comunicacao'], 'Comunicação');
    });
  });

  // ===========================================================================
  // UT-SDISPLAY: StarDisplay
  // ===========================================================================
  group('StarDisplay', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('SD-U1: renderiza exactamente 5 ícones', (tester) async {
      await tester.pumpWidget(wrap(const StarDisplay(stars: 3)));
      expect(find.byType(Icon), findsNWidgets(5));
    });

    testWidgets('SD-U2: stars=0 → todas outline', (tester) async {
      await tester.pumpWidget(wrap(const StarDisplay(stars: 0)));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.every((i) => i.icon == Icons.star_outline_rounded), isTrue);
    });

    testWidgets('SD-U3: stars=5 → todas preenchidas', (tester) async {
      await tester.pumpWidget(wrap(const StarDisplay(stars: 5)));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.every((i) => i.icon == Icons.star_rounded), isTrue);
    });

    testWidgets('SD-U4: stars=3 → primeiras 3 preenchidas, últimas 2 outline', (tester) async {
      await tester.pumpWidget(wrap(const StarDisplay(stars: 3)));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      for (int i = 0; i < 3; i++) {
        expect(icons[i].icon, Icons.star_rounded);
      }
      for (int i = 3; i < 5; i++) {
        expect(icons[i].icon, Icons.star_outline_rounded);
      }
    });

    testWidgets('SD-U5: size personalizada aplicada a todos os ícones', (tester) async {
      await tester.pumpWidget(wrap(const StarDisplay(stars: 2, size: 42)));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.every((i) => i.size == 42), isTrue);
    });

    testWidgets('SD-U6: size por defeito é 18', (tester) async {
      await tester.pumpWidget(wrap(const StarDisplay(stars: 1)));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.every((i) => i.size == 18), isTrue);
    });

    testWidgets('SD-U7: cor das estrelas preenchidas é amber', (tester) async {
      await tester.pumpWidget(wrap(const StarDisplay(stars: 5)));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.every((i) => i.color == Colors.amber), isTrue);
    });
  });

  // ===========================================================================
  // UT-SROW: StarRow
  // ===========================================================================
  group('StarRow', () {
    Widget buildRow({required int stars, required ValueChanged<int> onChanged}) =>
        MaterialApp(home: Scaffold(body: StarRow(stars: stars, onChanged: onChanged)));

    testWidgets('SR-U1: renderiza 5 GestureDetectors', (tester) async {
      await tester.pumpWidget(buildRow(stars: 3, onChanged: (_) {}));
      expect(find.byType(GestureDetector), findsNWidgets(5));
    });

    testWidgets('SR-U2: tap na 1.ª estrela chama onChanged(1)', (tester) async {
      int? received;
      await tester.pumpWidget(buildRow(stars: 0, onChanged: (v) => received = v));
      final detectors = tester.widgetList<GestureDetector>(find.byType(GestureDetector)).toList();
      await tester.tap(find.byWidget(detectors[0]));
      await tester.pump();
      expect(received, 1);
    });

    testWidgets('SR-U3: tap na 3.ª estrela chama onChanged(3)', (tester) async {
      int? received;
      await tester.pumpWidget(buildRow(stars: 0, onChanged: (v) => received = v));
      final detectors = tester.widgetList<GestureDetector>(find.byType(GestureDetector)).toList();
      await tester.tap(find.byWidget(detectors[2]));
      await tester.pump();
      expect(received, 3);
    });

    testWidgets('SR-U4: tap na 5.ª estrela chama onChanged(5)', (tester) async {
      int? received;
      await tester.pumpWidget(buildRow(stars: 0, onChanged: (v) => received = v));
      final detectors = tester.widgetList<GestureDetector>(find.byType(GestureDetector)).toList();
      await tester.tap(find.byWidget(detectors[4]));
      await tester.pump();
      expect(received, 5);
    });

    testWidgets('SR-U5: estrelas preenchidas são amber, outline são grey[300]', (tester) async {
      await tester.pumpWidget(buildRow(stars: 2, onChanged: (_) {}));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons[0].color, Colors.amber);
      expect(icons[1].color, Colors.amber);
      expect(icons[2].color, Colors.grey[300]);
    });

    testWidgets('SR-U6: size personalizada aplicada a todos', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StarRow(stars: 4, onChanged: (_) {}, size: 40)),
      ));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.every((i) => i.size == 40), isTrue);
    });
  });

  // ===========================================================================
  // UT-DIALOG: _StructuredRatingDialog (via showStructuredRatingDialog)
  // ===========================================================================
  group('_StructuredRatingDialog', () {
    late _MockApi api;

    setUp(() {
      api = _MockApi();
    });

    // Abre o dialog com api configurável
    Future<void> openDialog(WidgetTester tester, {int rideId = 42, String name = 'João Silva'}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showStructuredRatingDialog(
                ctx,
                rideId: rideId,
                targetName: name,
                api: api,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('DG-U1: dialog mostra título "Avalia a viagem"', (tester) async {
      await openDialog(tester);
      expect(find.text('Avalia a viagem'), findsOneWidget);
    });

    testWidgets('DG-U2: dialog mostra o nome do target', (tester) async {
      await openDialog(tester);
      expect(find.textContaining('João Silva'), findsOneWidget);
    });

    testWidgets('DG-U3: mostra os 4 critérios em português', (tester) async {
      await openDialog(tester);
      expect(find.text('Pontualidade'), findsOneWidget);
      expect(find.text('Simpatia'), findsOneWidget);
      expect(find.text('Limpeza do veículo'), findsOneWidget);
      expect(find.text('Comunicação'), findsOneWidget);
    });

    testWidgets('DG-U4: classificação global inicial é 5', (tester) async {
      await openDialog(tester);
      expect(find.textContaining('Classificação global: 5'), findsOneWidget);
    });

    testWidgets('DG-U5: botão Cancelar fecha o dialog', (tester) async {
      await openDialog(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Avalia a viagem'), findsNothing);
    });

    testWidgets('DG-U6: Cancelar devolve false', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              result = await showStructuredRatingDialog(
                ctx, rideId: 1, targetName: 'Ana', api: api,
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(result, false);
    });

    
  

    testWidgets('DG-U8: Enviar com sucesso mostra snackbar de confirmação', (tester) async {
      when(() => api.rateRideParticipant(any(), stars: any(named: 'stars')))
          .thenAnswer((_) async {});

      await openDialog(tester);
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('Avaliação enviada! Obrigado.'), findsOneWidget);
    });

    testWidgets('DG-U9: Enviar com sucesso fecha o dialog', (tester) async {
      when(() => api.rateRideParticipant(any(), stars: any(named: 'stars')))
          .thenAnswer((_) async {});

      await openDialog(tester);
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('Avalia a viagem'), findsNothing);
    });

    testWidgets('DG-U11: Enviar chama rateRideParticipant com o rideId correcto', (tester) async {
      when(() => api.rateRideParticipant(any(), stars: any(named: 'stars')))
          .thenAnswer((_) async {});

      await openDialog(tester, rideId: 99);
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      verify(() => api.rateRideParticipant(99, stars: 5)).called(1);
    });

    testWidgets('DG-U12: API falha → mostra snackbar de erro', (tester) async {
      when(() => api.rateRideParticipant(any(), stars: any(named: 'stars')))
          .thenThrow(Exception('timeout'));

      await openDialog(tester);
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('Erro ao enviar avaliação.'), findsOneWidget);
    });

    testWidgets('DG-U13: API falha → dialog permanece aberto', (tester) async {
      when(() => api.rateRideParticipant(any(), stars: any(named: 'stars')))
          .thenThrow(Exception('timeout'));

      await openDialog(tester);
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('Avalia a viagem'), findsOneWidget);
    });

  });
}