import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Ride4Free/main.dart'; // Ajusta se necessário

void main() {
  group('Integration - Fluxos de Viagem (Offer/Search)', () {

    testWidgets('Deve validar formato de hora antes de permitir publicação', (tester) async {
      // Truque do ecrã gigante.vscode/settings.json
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: OfferRidePage())));
      await tester.pumpAndSettle();

      final timeField = find.byType(TextField).first;
      final publishButton = find.text('Publicar Viagem');

      // 1. Escrever hora inválida e clicar
      await tester.enterText(timeField, '99:99'); 
      await tester.pumpAndSettle();
      await tester.tap(publishButton);
      await tester.pumpAndSettle(); // Espera a SnackBar subir

      // 2. Verifica erro
      expect(find.text('Por favor, insira uma hora válida (HH:mm).'), findsOneWidget);
      
      // 👉 A MAGIA ESTÁ AQUI: Avançar o relógio virtual em 5 segundos 
      // para a primeira SnackBar desaparecer!
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      
      // 3. Corrigir a hora e clicar novamente
      await tester.enterText(timeField, '08:30'); 
      await tester.pumpAndSettle();
      await tester.tap(publishButton);
      await tester.pumpAndSettle(); // Espera a nova SnackBar (a do mapa) subir
      
      // 4. Como já passou o tempo e a hora está certa, o erro antigo JÁ NÃO ESTÁ LÁ!
      expect(find.text('Por favor, insira uma hora válida (HH:mm).'), findsNothing);
    });

  });
}
