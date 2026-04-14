import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// O meu import principal da app. 
// Malta, ajustem o path quando tivermos a estrutura final montada!
import 'package:app_test/main.dart'; 

void main() {
  group('US2 - Book Ride (Testes de Aceitação por André Rocha)', () {
    
    // Criei este helper para me facilitar a vida e não repetir código.
    // Como aprendi no TPC3, isto isola o arranque do ecrã.
    Future<void> launchBookingScreen(WidgetTester tester, {bool hasCredits = true}) async {
      await tester.pumpWidget(
        MaterialApp(
          // Passo a flag hasCredits para simular o estado da base de dados
          home: BookRideScreenMock(hasCredits: hasCredits), 
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('SB-1: Reserva com Sucesso (Quando tenho os 10 créditos no saldo)', (tester) async {
      await launchBookingScreen(tester, hasCredits: true);

      // 1. GIVEN: Encontrei a viagem e estou a ver os detalhes.
      expect(find.text('Miguel Antunes'), findsOneWidget);
      expect(find.text('De: Senhora da Hora'), findsOneWidget);
      expect(find.textContaining('10 Créditos'), findsOneWidget);

      // 2. WHEN: Clico no botão vermelho gigante
      final bookButton = find.text('Reservar Lugar Agora');
      expect(bookButton, findsOneWidget); // Garanto que o botão lá está
      await tester.tap(bookButton);
      await tester.pumpAndSettle(); // Espero que a animação termine

      // 3. THEN: O sistema desconta os créditos e confirma a reserva
      // Como a UI de sucesso ainda não está 100% fechada, 
      // vou validar que aparece um Dialog ou Snackbar a dizer "Confirmada"
      expect(find.text('Reserva Confirmada'), findsOneWidget);
    });

    testWidgets('SB-2: Saldo Insuficiente (Quando estou "teso" e tenho 0 ou 5 créditos)', (tester) async {
      // Carrego o ecrã mas forço a simulação de saldo insuficiente
      await launchBookingScreen(tester, hasCredits: false);

      // 1. GIVEN: A viagem custa 10 créditos mas não tenho saldo
      expect(find.text('Miguel Antunes'), findsOneWidget);

      // 2. WHEN: Tento confirmar a reserva...

      // Portanto, o botão "Reservar Lugar Agora" não deve existir.
      expect(find.text('Reservar Lugar Agora'), findsNothing);

      // 3. THEN: O sistema bloqueia a ação.
      // E vejo o texto de erro que desenhei no mockup: "Créditos Insuficientes"
      expect(find.text('Créditos Insuficientes'), findsOneWidget);
      
      // Valido também se o ícone de aviso está lá (Warning)
      expect(find.byType(Icon), findsWidgets); 
    });
  });
}
/* ----------------------------------------------------------------------
  MOCK WIDGET 
  Ecrã falso criado apenas para que os testes de aceitação 
  da US2 (Book Ride) compilarem enquanto a verdadeira UI não é desenvolvida.
  Quando o ecrã real de detalhes da viagem existir, apaguem esta classe!
  ----------------------------------------------------------------------
*/
class BookRideScreenMock extends StatelessWidget {
  final bool hasCredits;

  const BookRideScreenMock({super.key, required this.hasCredits});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Boleia')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações base que o teste (GIVEN) vai procurar
            const Text('Miguel Antunes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('De: Senhora da Hora'),
            const Text('Para: FEUP'),
            const SizedBox(height: 8),
            const Text('Custo: 10 Créditos', style: TextStyle(fontSize: 16, color: Colors.blue)),
            const SizedBox(height: 40),
            
            // Lógica condicional: O que acontece se tiveres créditos vs se estiveres a zero
            if (hasCredits) ...[
              // SB-1: Com saldo -> Mostra o botão vermelho
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () {
                    // Simula o pop-up de sucesso que o teste (THEN) está à espera
                    showDialog(
                      context: context,
                      builder: (context) => const AlertDialog(
                        title: Text('Reserva Confirmada'),
                        content: Text('Lugar garantido com o Miguel!'),
                      ),
                    );
                  },
                  child: const Text('Reservar Lugar Agora', style: TextStyle(color: Colors.white)),
                ),
              ),
            ] else ...[
              // SB-2: Sem saldo -> Esconde o botão de reservar e mostra o erro
              Center(
                child: Column(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 50),
                    SizedBox(height: 10),
                    Text(
                      'Créditos Insuficientes', 
                      style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}