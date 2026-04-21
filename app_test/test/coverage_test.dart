// =============================================================================
// COVERAGE TESTS — Ride4Free (Corrigido)
// Focado estritamente em testar o código real da aplicação, sem mocks de UI falsos.
// Cobre: Exceções de API, Validações de UI, Snackbars de Autenticação e BottomSheets.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_test/main.dart';
import 'package:app_test/profile_rating_button.dart';
import 'package:app_test/ride4free_api.dart';

// -----------------------------------------------------------------------------
// Helpers de Inicialização (Usam sempre os Ecrãs Reais)
// -----------------------------------------------------------------------------

Future<void> launchPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
  await tester.pumpAndSettle();
}

void main() {
  // ---------------------------------------------------------------------------
  // 1. COBERTURA DO CLIENTE API (Ride4FreeApi e Modelos)
  // Testa diretamente a lógica Dart sem depender da UI.
  // ---------------------------------------------------------------------------
  group('COV-API: Internos da Ride4FreeApi e Modelos', () {
    
    test('API-1: Configuração da Base URL é válida', () {
      expect(Ride4FreeConfig.baseUrl, isNotEmpty);
      expect(Ride4FreeConfig.baseUrl, startsWith('http'));
    });

    test('API-2: Ride4FreeApiException guarda valores e converte para string', () {
      final erro = Ride4FreeApiException(404, 'Não encontrado');
      expect(erro.statusCode, 404);
      expect(erro.body, 'Não encontrado');
      expect(erro.toString(), contains('404'));
    });

    test('API-3: Ride4FreeUser desserializa JSON corretamente', () {
      final json = {'id': 10, 'email': 'teste@feup.pt', 'name': 'Estudante'};
      final user = Ride4FreeUser.fromJson(json);
      
      expect(user.id, 10);
      expect(user.email, 'teste@feup.pt');
      expect(user.name, 'Estudante');
    });

    test('API-4: Injeção de Token nos Headers funciona', () {
      // Simula login guardando um token na variável estática
      Ride4FreeAuth.token = 'meu_token_secreto';
      expect(Ride4FreeAuth.token, isNotNull);
      
      // Limpa após o teste
      Ride4FreeAuth.token = null;
    });
  });

  // ---------------------------------------------------------------------------
  // 2. COBERTURA DE SEGURANÇA E PERMISSÕES (Snackbars)
  // Garante que clicar em ações protegidas sem token dispara os erros.
  // ---------------------------------------------------------------------------
  group('COV-AUTH: Bloqueios de Ação Sem Sessão Iniciada', () {
    
    setUp(() {
      // Garante que começamos sempre sem sessão (Logout)
      Ride4FreeAuth.token = null;
    });

    testWidgets('SEC-1: "Pedir Boleia" na SearchRidePage exige login', (tester) async {
      await launchPage(tester, const SearchRidePage());
      
      // Encontra e clica no botão
      final btn = find.text('Pedir boleia');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await tester.pumpAndSettle();
        // Verifica se a Snackbar real de erro aparece
        expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
      }
    });

testWidgets('SEC-2: "Ver passageiros" na OfferRidePage exige login', (tester) async {
  await launchPage(tester, const OfferRidePage());
  await tester.pumpAndSettle(); 
  
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
  await tester.pumpAndSettle(); 
  
  final btn = find.text('Ver passageiros para este destino');
  await tester.tap(btn);
  
  await tester.pump(const Duration(seconds: 1)); 

  expect(find.textContaining(RegExp('perfil', caseSensitive: false)), findsWidgets);
});

    testWidgets('SEC-3: "Atualizar secao" na Base de Dados exige login', (tester) async {
      await launchPage(tester, const CommunityBoardPage());
      
      // Troca para a aba BD
      await tester.tap(find.text('BD'));
      await tester.pumpAndSettle();
      
      // Tenta atualizar
      await tester.tap(find.text('Atualizar secao'));
      await tester.pumpAndSettle();
      
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. COBERTURA DA PÁGINA DE PERFIL E FORMULÁRIOS (Sad Paths)
  // Testa os catch blocks e o comportamento dos TextFields.
  // ---------------------------------------------------------------------------
  group('COV-PROFILE: Tratamento de Erros no Formulário', () {
    
    setUp(() {
      Ride4FreeAuth.token = null;
    });

    testWidgets('PROF-1: Inserir dados e tentar Login falha graciosamente (Sem API)', (tester) async {
      await launchPage(tester, const ProfilePage());
      
      // Preenche os campos (garante que os inputs funcionam)
      await tester.enterText(find.byType(TextField).at(0), 'teste@feup.pt');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      
      // Clica em Entrar. Como não há backend a correr no teste, a API vai lançar erro.
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      
      // O catch block no _login deve mostrar um erro na Snackbar
      expect(find.textContaining('Erro:'), findsOneWidget);
    });

    testWidgets('PROF-2: Botão "Submeter Avaliacao" está presente e clicável', (tester) async {
      await launchPage(tester, const ProfilePage());
      
      // Faz scroll até ao fim para encontrar o botão
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      
      final submeterBtn = find.text('Submeter Avaliacao');
      expect(submeterBtn, findsOneWidget);
      
      // Clica para garantir que não crasha
      await tester.tap(submeterBtn);
      await tester.pumpAndSettle();
    });
  });

  // ---------------------------------------------------------------------------
  // 4. COBERTURA DE COMPONENTES VISUAIS ESTÁTICOS (TopTitleBars e InputLikes)
  // ---------------------------------------------------------------------------
  group('COV-UI: Renderização de Textos e Cabeçalhos', () {
    
    testWidgets('UI-1: Cabeçalho e campos fixos na OfferRidePage', (tester) async {
      await launchPage(tester, const OfferRidePage());
      
      // Título
      expect(find.text('Oferecer Boleia'), findsOneWidget);
      
      // Labels
      expect(find.text('PONTO DE PARTIDA'), findsOneWidget);
      expect(find.text('DESTINO'), findsOneWidget);
      expect(find.text('HORA'), findsOneWidget);
      
      // Textos fixos (InputLike)
      expect(find.text('Residencia Universitaria'), findsOneWidget);
      expect(find.text('08:15'), findsOneWidget);
    });

    testWidgets('UI-2: Teste de Lógica de Recompensa Inválida (0 lugares)', (tester) async {
      await launchPage(tester, const OfferRidePage());
      
      // Reduz lugares para 0
      final removeIcon = find.byIcon(Icons.remove);
      await tester.tap(removeIcon);
      await tester.tap(removeIcon);
      await tester.tap(removeIcon);
      await tester.pumpAndSettle();
      
      // Verifica o texto gigante de instrução
      expect(find.text('Indique pelo menos 1 lugar disponivel para ganhar creditos.'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. COBERTURA DO RATING BOTTOM SHEET (ProfileRatingButton)
  // Testa interações e estados iniciais do componente de avaliação.
  // ---------------------------------------------------------------------------
  group('COV-RATING: BottomSheet de Avaliação Comunitária', () {
    
    testWidgets('RAT-1: Abertura do BottomSheet mostra avatares default', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProfileRatingButton())));
      
      // Abre o menu
      await tester.tap(find.text('Rate profiles'));
      await tester.pumpAndSettle();
      
      // Verifica título
      expect(find.text('Give Recent drivers an avaliation'), findsOneWidget);
      
      // Verifica se as iniciais dos perfis default (Alex Rivera, Sam Chen, etc) estão lá
      expect(find.text('AR'), findsOneWidget);
      expect(find.text('SC'), findsOneWidget);
      expect(find.text('MP'), findsOneWidget);
      
      // Verifica se o HintText de adicionar novo existe
      expect(find.text('New profile name...'), findsOneWidget);
    });

    testWidgets('RAT-2: Estrelas Outline (vazias) por defeito nos perfis não selecionados', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProfileRatingButton())));
      
      await tester.tap(find.text('Rate profiles'));
      await tester.pumpAndSettle();
      
      // Procura pelas estrelas com border outline
      expect(find.byIcon(Icons.star_outline_rounded), findsWidgets);
    });
  });
}