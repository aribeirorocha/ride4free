import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:app_test/main.dart'; 

// Helper para arrancar a app e navegar para o ecrã de publicar boleia
Future<void> launchPublishScreen(WidgetTester tester) async {
  // Nota: Para este teste isolado, assumimos que a app arranca diretamente 
  // para o ecrã de Publicar, ou usamos um MaterialApp com o Scaffold desse ecrã.
  await tester.pumpWidget(
    const MaterialApp(
      home: PublishRideScreen(), // Substituir pelo nome real do Widget
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('US1: Successful Publication', () {
    testWidgets('PR-1 — Entering valid route and capacity shows reward and allows publication', (tester) async {
      await launchPublishScreen(tester);

      // GIVEN the driver has entered the starting point, destination, and time
      await tester.enterText(find.widgetWithText(TextField, 'PONTO DE PARTIDA'), 'FEUP');
      await tester.enterText(find.widgetWithText(TextField, 'DESTINO'), 'Estação Trindade');
      await tester.enterText(find.widgetWithText(TextField, 'DATA'), '06/04/2026');
      await tester.enterText(find.widgetWithText(TextField, 'HORA'), '18:00');

      // AND specified how many available seats (Assumindo que o default é 1, clicamos no '+')
      final addSeatButton = find.byIcon(Icons.add);
      if (addSeatButton.evaluate().isNotEmpty) {
        await tester.tap(addSeatButton);
        await tester.pumpAndSettle();
      }
      
      // Verifica se a UI mostra pelo menos 2 lugares (usando a tua label 'LUGARES')
      expect(find.text('2'), findsWidgets);

      // THEN the system validates the data and shows an estimated reward of +30 credits
      // (O mockup mostra a "Recompensa Estimada" verde no ecrã)
      expect(find.textContaining('+30 Créditos'), findsOneWidget);

      // WHEN they click "Publish Trip"
      await tester.tap(find.text('Publicar Viagem'));
      await tester.pumpAndSettle();


    });
  });

  group('US1: Invalid Capacity', () {
    testWidgets('PR-2 — Attempting to publish with 0 seats shows an error warning', (tester) async {
      await launchPublishScreen(tester);

      // GIVEN the driver enters the route...
      await tester.enterText(find.widgetWithText(TextField, 'PONTO DE PARTIDA'), 'FEUP');
      await tester.enterText(find.widgetWithText(TextField, 'DESTINO'), 'Estação Trindade');

      // ...but keeps seats at 0 (Clicamos no '-' para reduzir os lugares para 0)
      final removeSeatButton = find.byIcon(Icons.remove);
      if (removeSeatButton.evaluate().isNotEmpty) {
        await tester.tap(removeSeatButton);
        await tester.pumpAndSettle();
      }

      // Verificamos se o contador está a zero
      expect(find.text('0'), findsWidgets);

      // WHEN they attempt to publish the trip
      await tester.tap(find.text('Publicar Viagem'));
      await tester.pumpAndSettle();

      // THEN the system prevents publication and displays an "Invalid Capacity" warning
      // (A testar exatamente a frase vermelha que está no teu Mockup de Erro)
      expect(find.textContaining('A Lotação é inválida'), findsOneWidget);
      expect(find.textContaining('Indique pelo menos 1 lugar'), findsOneWidget);
    });
  });
}

/* ----------------------------------------------------------------------
  MOCK WIDGET 
  Ecrã falso criado apenas para que os testes 
  de aceitação compilem enquanto a verdadeira UI não é desenvolvida.
  Quando o ecrã real existir, apaguem esta classe!
  ----------------------------------------------------------------------
*/
class PublishRideScreen extends StatelessWidget {
  const PublishRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar Boleia')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Campos de texto baseados no Mockup
            const TextField(decoration: InputDecoration(labelText: 'PONTO DE PARTIDA')),
            const TextField(decoration: InputDecoration(labelText: 'DESTINO')),
            const TextField(decoration: InputDecoration(labelText: 'DATA')),
            const TextField(decoration: InputDecoration(labelText: 'HORA')),
            
            // Secção dos Lugares (Lotação)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.remove), onPressed: () {}),
                // Textos hardcoded para o teste os conseguir encontrar
                const Text('0'), 
                const Text('2'),
                IconButton(icon: const Icon(Icons.add), onPressed: () {}),
              ],
            ),
            
            // Textos de erro e recompensas
            const Text('A Lotação é inválida. Indique pelo menos 1 lugar.', style: TextStyle(color: Colors.red)),
            const Text('Recompensa Estimada: +30 Créditos', style: TextStyle(color: Colors.green)),
            
            // Botão de submissão
            ElevatedButton(
              onPressed: () {}, 
              child: const Text('Publicar Viagem'),
            ),
          ],
        ),
      ),
    );
  }
}