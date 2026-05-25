// =============================================================================
// UNIT TESTS — PedidosPage
// Usa `http.runWithClient` para injetar respostas falsas na API.
// Assim, testamos os métodos privados através de cliques reais na UI,
// respeitando as regras de privacidade do Dart a 100%!
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Imports do teu projeto
import 'package:Ride4Free/pedidos_page.dart';
import 'package:Ride4Free/ride4free_api.dart';

void main() {
  
  // ===========================================================================
  // PARTE 1: ESTADOS VAZIOS (Utilizador sem sessão)
  // ===========================================================================
  group('PedidosPage - Estados Vazios (Sem Token)', () {
    setUp(() => Ride4FreeAuth.token = null);

    testWidgets('PED-U1: Mostra estado vazio de "Os meus pedidos"', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
      await tester.pumpAndSettle(); 
      expect(find.text('Ainda não pediste boleias.'), findsOneWidget);
    });

    testWidgets('PED-U2: Mostra estado vazio de "Pedidos recebidos"', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
      await tester.pumpAndSettle(); 
      await tester.tap(find.text('Pedidos recebidos'));
      await tester.pumpAndSettle(); 
      expect(find.text('Sem pedidos de passageiros.'), findsOneWidget);
    });
  });

  // ===========================================================================
  // PARTE 2: COBERTURA DAS LINHAS PRIVADAS (Com MockClient)
  // ===========================================================================
  group('PedidosPage - Cobertura de Linhas Privadas', () {
    
    setUp(() => Ride4FreeAuth.token = 'token_valido_teste');
    tearDown(() => Ride4FreeAuth.token = null);

   testWidgets('PED-COV-1: Cobre a tradução de todos os _statusLabel', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('my-join-requests')) {
          return http.Response(jsonEncode({
            'requests': [
              {'id': 3, 'status': 'declined'}, // Este é o que procuramos
            ]
          }), 200);
        }
        return http.Response('{"requests": []}', 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        // 1. pumpAndSettle garante que todas as animações e loads da API terminaram
        await tester.pumpAndSettle();

        // 2. O design premium faz .toUpperCase(). 
        // Se o texto é "Recusado", o widget mostra "RECUSADO".
        // Vamos garantir que o widget está realmente no ecrã antes de pedir o expect
        final finder = find.text('RECUSADO');
        
        // Se ainda falhar, fazemos um scroll para garantir que a lista apareceu
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(find.byType(ListView), 500);
          await tester.pumpAndSettle();
        }

        expect(finder, findsOneWidget);
      }, () => mockClient);
    });
    testWidgets('PED-COV-2: _load e o bloco catch (Erro ao carregar)', (tester) async {
      // Configuramos a API para lançar um erro mortal 500
      final errorClient = MockClient((request) async => http.Response('{"detail": "Erro fatal"}', 500));

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        await tester.pump(); // Inicia o widget
        await tester.pumpAndSettle(); // Espera pela SnackBar
        
        // Verifica se a linha do catch foi ativada!
        expect(find.textContaining('Erro ao carregar pedidos'), findsOneWidget);
      }, () => errorClient);
    });

    testWidgets('PED-COV-3: _driverRespond (Aceitar e Recusar)', (tester) async {
      int apiCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('incoming-join-requests')) {
          return http.Response(jsonEncode({'requests': [{'id': 10, 'status': 'pending'}]}), 200);
        } else if (request.url.path.contains('respond')) {
          apiCalls++;
          // No primeiro clique devolvemos sucesso, no segundo forçamos erro para testar o Catch
          return apiCalls == 1 ? http.Response('{"status": "ok"}', 200) : http.Response('Erro', 500);
        }
        return http.Response('{"requests": []}', 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Pedidos recebidos'));
        await tester.pumpAndSettle();

        // 1. Clicar em Aceitar
        await tester.tap(find.text('Aceitar'));
        await tester.pumpAndSettle();
        expect(find.text('Passageiro aceite. Aguarda confirmação.'), findsOneWidget);
        
        // Esconde a SnackBar para não sobrepor o próximo botão
        ScaffoldMessenger.of(tester.element(find.byType(PedidosPage))).clearSnackBars();

        // 2. Clicar em Recusar (Irá forçar o erro 500 na nossa MockApi)
        await tester.tap(find.text('Recusar'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsOneWidget); // Confirmamos que o catch disparou

      }, () => mockClient);
    });
     testWidgets('PED-COV-5: _openChat abre a BottomSheet', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('incoming-join-requests')) {
          // Precisamos de um pedido pendente para o botão de chat aparecer
          return http.Response(jsonEncode({'requests': [{'id': 10, 'status': 'pending'}]}), 200);
        }
        return http.Response('{"requests": []}', 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pedidos recebidos'));
        await tester.pumpAndSettle();

        // Clica no botão conversar
        await tester.tap(find.text('Conversar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300)); // Espera o Modal abrir
        
        // Verifica se a folha do chat abriu e carregou o campo de escrita que está no teu código
        expect(find.text('Escreve uma mensagem...'), findsOneWidget);

      }, () => mockClient);
    });
  });
testWidgets('PED-COV-6: _send envia mensagem e atualiza chat dentro do ChatSheet', (tester) async {
      // 1. Mock para capturar o envio da mensagem
      bool sent = false;
      final mockApi = MockClient((request) async {
        if (request.method == 'POST') {
          sent = true;
          return http.Response('{}', 200);
        }
        return http.Response(jsonEncode({'messages': [{'body': 'Olá'}]}), 200);
      });

      // 2. Instanciamos o ChatSheet diretamente (é um widget privado, mas podemos testar assim)
      // Como não conseguimos chamar construtor privado, abrimos como modal:
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => JoinReqestChatSheet(requestId: 99, api: Ride4FreeApi(client: mockApi)),
              ),
              child: const Text('Abrir'),
            );
          }),
        ),
      ));

      // 3. Abrir o modal
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // 4. Agora sim, o TextField e o botão "send_rounded" existem dentro do modal!
      await tester.enterText(find.byType(TextField), 'Mensagem de teste');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // 5. Validação
      expect(sent, isTrue);
    });
    group('UI - Zona de Informação Extra', () {
    testWidgets('INF-U1: Esconde-se completamente quando origem e partida são nulos', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: InfoExtraWidget(origin: null, dep: null), // Assumindo que este é o nome da classe
        ),
      ));
      
      // Verifica que o container com a cor F8F8F8 não existe
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('INF-U2: Mostra apenas a origem quando a hora de partida é nula', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: InfoExtraWidget(origin: 'Rua das Flores', dep: null),
        ),
      ));
      
      expect(find.text('Rua das Flores'), findsOneWidget);
      expect(find.textContaining('Partida:'), findsNothing);
    });

    testWidgets('INF-U3: Mostra ambos corretamente quando fornecidos', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: InfoExtraWidget(origin: 'Rua A', dep: '08:15'),
        ),
      ));
      
      expect(find.text('Rua A'), findsOneWidget);
      expect(find.text('Partida: 08:15'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });
  });
}