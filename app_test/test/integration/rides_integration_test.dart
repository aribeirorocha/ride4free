import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_test/main.dart';

void main() {
  group('Integration - Fluxos de Viagem (Offer/Search)', () {

    testWidgets('Deve validar formato de hora antes de permitir publicação', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: OfferRidePage())));
      
      final timeField = find.byType(TextField).first;
      await tester.enterText(timeField, '99:99'); // Hora inválida
      await tester.pump();

      expect(find.text('Formato inválido'), findsOneWidget);
      
      await tester.enterText(timeField, '08:30'); // Hora válida
      await tester.pump();
      expect(find.text('Formato inválido'), findsNothing);
    });
  });
}
