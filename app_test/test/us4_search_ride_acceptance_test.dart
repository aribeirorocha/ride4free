// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  group('US4 - Search Ride (Testes de Aceitação por André Rocha)', () {
    
    // Helper para carregar o ecrã, passando a simulação de haver ou não boleias
    Future<void> launchSearchScreen(WidgetTester tester, {required bool hasMatches}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SearchRideScreenMock(hasMatches: hasMatches), 
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('SS-1: Successful Match within Radius (Encontra boleias)', (tester) async {
      // Arranco o ecrã a simular que a API devolveu resultados
      await launchSearchScreen(tester, hasMatches: true);

      // 1. GIVEN: O passageiro preencheu a origem e destino e ajustou o slider
      // Vou verificar se o slider de distância existe no ecrã
      expect(find.byType(Slider), findsOneWidget);

      // 2. WHEN: A app procura por condutores na mesma direção (já simulado ao carregar)
      
      // 3. THEN: Mostra as boleias encontradas com base no mockup
      expect(find.text('Boleias Encontradas'), findsOneWidget);
      
      // Valido se os condutores do mockup aparecem na lista
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Maria Santos'), findsOneWidget);
      
      // Valido se a distância a pé (walking tolerance) está a ser mostrada (ex: 200m)
      expect(find.textContaining('200m'), findsWidgets);

      // Valido que o botão de reservar está disponível num dos cards
      expect(find.text('Reservar Boleia'), findsWidgets);
    });

    testWidgets('SS-2: No Matching Drivers (Não há boleias no raio indicado)', (tester) async {
      // Arranco o ecrã a simular que não há ninguém a ir para aquele destino
      await launchSearchScreen(tester, hasMatches: false);

      // 1. GIVEN / WHEN: O utilizador procura, mas a base de dados volta vazia
      
      // 2. THEN: A app mostra a mensagem de erro que desenhei no Figma
      expect(find.text('Sem Boleias Disponíveis'), findsOneWidget);
      expect(find.textContaining('Infelizmente, não encontrámos condutores'), findsOneWidget);
      
      // E não deve haver nenhum botão de "Reservar Boleia" nem nomes de pessoas
      expect(find.text('Reservar Boleia'), findsNothing);
      expect(find.text('João Silva'), findsNothing);
    });
  });
}

/* ----------------------------------------------------------------------
  MOCK WIDGET 
  Ecrã falso para validar a US4 (Search Ride) com a tolerância a pé.
  Este Mock tem o Slider visual e responde à variável 'hasMatches'.
  Apagar isto quando tivermos a ligação real com a base de dados!
  ----------------------------------------------------------------------
*/
class SearchRideScreenMock extends StatelessWidget {
  final bool hasMatches;

  const SearchRideScreenMock({super.key, required this.hasMatches});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Procurar Boleia')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Critérios de pesquisa (Origem e Destino)
            const TextField(decoration: InputDecoration(labelText: 'De: Senhora da Hora')),
            const TextField(decoration: InputDecoration(labelText: 'Para: FEUP')),
            const SizedBox(height: 16),
            
            // Slider da Tolerância a pé (Walking Tolerance)
            const Text('Distância máxima a pé: 500m'),
            Slider(
              value: 500,
              min: 100,
              max: 1000,
              onChanged: (val) {}, // Mock visual
            ),
            const Divider(),

            // Lógica condicional dos resultados
            Expanded(
              child: hasMatches 
                ? ListView(
                    children: [
                      const Text('Boleias Encontradas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // Card do João Silva (como no mockup)
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Text('JS')),
                          title: const Text('João Silva'),
                          subtitle: const Text('Passa a: 200m do destino'),
                          trailing: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Reservar Boleia'),
                          ),
                        ),
                      ),
                      // Card da Maria Santos
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Text('MS')),
                          title: const Text('Maria Santos'),
                          subtitle: const Text('Passa a: 50m do destino'),
                          trailing: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Reservar Boleia'),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    // Estado vazio (Empty State) como no mockup
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.directions_walk, size: 60, color: Colors.orange),
                        SizedBox(height: 16),
                        Text('Sem Boleias Disponíveis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                        SizedBox(height: 8),
                        Text('Infelizmente, não encontrámos condutores neste raio.', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
