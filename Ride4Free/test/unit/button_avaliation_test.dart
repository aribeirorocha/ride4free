
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:Ride4Free/main.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

/// ---------------------------------------------------------------------------
/// WIDGET DE TESTE
/// ---------------------------------------------------------------------------
///
/// Este widget simula exatamente o comportamento do teu método:
///
/// Future<void> showRatingDialog(...)
///
/// Como o teu código usa:
/// - mounted
/// - context
/// - snackbar
/// - navegação
///
/// ...a melhor maneira é testar com um Widget real.
/// ---------------------------------------------------------------------------

class TestRatingPage extends StatefulWidget {
  final Future<bool> Function() onPromptResult;

  const TestRatingPage({
    super.key,
    required this.onPromptResult,
  });

  @override
  State<TestRatingPage> createState() => TestRatingPageState();
}

class TestRatingPageState extends State<TestRatingPage> {
  bool navigateCalled = false;
  bool messageCalled = false;

  Future<void> showRatingDialog({
    required int rideId,
    required String targetName,
  }) async {
    if (!mounted) return;

    final submitted = await widget.onPromptResult();

    if (submitted && mounted) {
      navigateHome(context);
      showSuccessMessage(context);
    }
  }

  void navigateHome(BuildContext context) {
    navigateCalled = true;
  }

  void showSuccessMessage(BuildContext context) {
    messageCalled = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Obrigado pela avaliação!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('rate_button'),
          onPressed: () async {
            await showRatingDialog(
              rideId: 1,
              targetName: 'João',
            );
          },
          child: const Text('Avaliar'),
        ),
      ),
    );
  }
}

void main() {
  group('showRatingDialog()', () {
    testWidgets(
      'deve mostrar mensagem e navegar quando submitted == true',
      (tester) async {
        final key = GlobalKey<TestRatingPageState>();

        await tester.pumpWidget(
          MaterialApp(
            home: TestRatingPage(
              key: key,
              onPromptResult: () async => true,
            ),
          ),
        );

        // carrega no botão
        await tester.tap(find.byKey(const Key('rate_button')));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // verifica snackbar
        expect(find.text('Obrigado pela avaliação!'), findsOneWidget);

        // verifica métodos chamados
        expect(key.currentState!.navigateCalled, true);
        expect(key.currentState!.messageCalled, true);
      },
    );

    testWidgets(
      'não deve navegar nem mostrar mensagem quando submitted == false',
      (tester) async {
        final key = GlobalKey<TestRatingPageState>();

        await tester.pumpWidget(
          MaterialApp(
            home: TestRatingPage(
              key: key,
              onPromptResult: () async => false,
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('rate_button')));

        await tester.pumpAndSettle();

        // snackbar NÃO aparece
        expect(find.text('Obrigado pela avaliação!'), findsNothing);

        // métodos NÃO chamados
        expect(key.currentState!.navigateCalled, false);
        expect(key.currentState!.messageCalled, false);
      },
    );

    testWidgets(
      'deve chamar o dialog exatamente 1 vez',
      (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: TestRatingPage(
              onPromptResult: () async {
                callCount++;
                return true;
              },
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('rate_button')));

        await tester.pumpAndSettle();

        expect(callCount, 1);
      },
    );
  });
}