import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Ride4Free/main.dart';
import 'package:Ride4Free/sigarra/sigarra_auth_service.dart';
import 'package:Ride4Free/ride4free_api.dart';

void main() {
  group('Integration - Navegação e Estrutura Principal', () {

    testWidgets('Deve navegar entre todas as abas da HomeShell sem erros', (tester) async {
      final identity = UniversityIdentity(username: 'up123', displayName: 'Teste');

      await tester.pumpWidget(MaterialApp(
        home: HomeShell(
          onUniversityLogout: () async {},
          identity: identity,
        ),
      ));

      expect(find.text('Comunidade Ride4Free'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('RAIO DE TOLERANCIA'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();
      expect(find.text('Oferecer Boleia'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('UP: up123'), findsOneWidget);
    });
  });

  group('Integration - Main & Bootstrapping', () {

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Ride4FreeAuth.token = null;
    });

    testWidgets('MAIN-IT1: Se não houver sessão, deve mostrar UniversityLoginPage', (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(UniversityLoginPage), findsOneWidget);
      expect(find.text('Autenticacao Universitaria'), findsOneWidget);
    });

    testWidgets('MAIN-IT2: Validação de campos vazios no Login Universitário', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.text('Preencha as credenciais universitarias.'), findsOneWidget);
    });

    testWidgets('MAIN-IT3: Se já houver sessão no disco, deve saltar o login e ir para HomeShell', (tester) async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up123456789',
        'university_display_name': 'Estudante Teste',
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.byType(UniversityLoginPage), findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);
    });

    testWidgets('MAIN-IT4: Fluxo de Logout limpa ecrã e volta ao Login', (tester) async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up123456789',
        'university_display_name': 'Estudante Teste',
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      final logoutBtn = find.widgetWithText(OutlinedButton, 'Terminar Sessão');
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();
      expect(find.byType(UniversityLoginPage), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('university_logged_in'), isNull);
    });

    testWidgets('MAIN-IT5: TopTitleBar exibe o título correto em diferentes contextos', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: TopTitleBar(title: 'Teste de Título')),
      ));
      expect(find.text('Teste de Título'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect((container.decoration as BoxDecoration?)?.color, isNull);
      expect(container.color, const Color(0xFFDF3E45));
    });
  });

// Helper reutilizável
UniversityIdentity makeIdentity({
  String username = 'up202300001',
  String displayName = 'Estudante Teste',
}) => UniversityIdentity(username: username, displayName: displayName);

Future<void> launchHomeShell(WidgetTester tester, {UniversityIdentity? identity}) async {
  final id = identity ?? makeIdentity();
  await tester.pumpWidget(MaterialApp(
    home: HomeShell(
      onUniversityLogout: () async {},
      identity: id,
    ),
  ));
  await tester.pumpAndSettle();
}

  // ===========================================================================
  // IT-PROFILE: ProfilePage
  // ===========================================================================
group('Integration — ProfilePage', () {

    testWidgets('IT-PROF-1: Perfil mostra o username correto do utilizador autenticado', (tester) async {
      await launchHomeShell(tester, identity: makeIdentity(username: 'up987654321'));
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      // ✅ CORREÇÃO: O novo design usa "username · Universidade do Porto"
      expect(find.text('up987654321 · Universidade do Porto'), findsOneWidget);
    });

    testWidgets('IT-PROF-2: Perfil mostra o displayName correto', (tester) async {
      await launchHomeShell(tester, identity: makeIdentity(displayName: 'Maria João'));
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('Maria João'), findsOneWidget);
    });

    testWidgets('IT-PROF-3: Botão de logout universitário está presente no perfil', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      // ✅ CORREÇÃO: O botão no design Premium mudou para 'Terminar Sessão'
      expect(find.widgetWithText(OutlinedButton, 'Terminar Sessão'), findsOneWidget);
    });

    testWidgets('IT-PROF-4: Clicar logout chama onUniversityLogout', (tester) async {
      bool logoutCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: HomeShell(
          onUniversityLogout: () async { logoutCalled = true; },
          identity: makeIdentity(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      // ✅ CORREÇÃO: Usar o nome atualizado do botão para fazer o tap
      await tester.tap(find.widgetWithText(OutlinedButton, 'Terminar Sessão'));
      await tester.pumpAndSettle();
      expect(logoutCalled, isTrue);
    });

    testWidgets('IT-PROF-5: Perfil carrega corretamente com username e botão logout', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      // ✅ CORREÇÃO: Atualizado para os novos formatos de texto
      expect(find.text('up202300001 · Universidade do Porto'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Terminar Sessão'), findsOneWidget);
    });

    testWidgets('IT-PROF-6: Perfil mostra ícone de pessoa no avatar', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('IT-PROF-7: Perfil mostra o título principal', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      // ✅ CORREÇÃO: Removemos a URL da API do ecrã Premium.
      // Em vez disso, garantimos que o ecrã tem o TopTitleBar correto.
      expect(find.text('Perfil'), findsOneWidget);
    });
    testWidgets('IT-PROF-8: O Perfil Premium mostra as estatísticas rápidas', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      expect(find.text('Avaliação'), findsOneWidget);
      expect(find.text('Créditos'), findsOneWidget);
    });

    testWidgets('IT-PROF-9: O campo do veículo (Premium UI) está presente no perfil', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Valida se a nossa nova label com formato Premium (maiúsculas) está no ecrã
      expect(find.text('O TEU VEÍCULO (PARA CONDUTORES)'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget); // O nosso novo botão de gravar quadrado
    });
  });

  // ===========================================================================
  // IT-COMMUNITY: CommunityBoardPage
  // ===========================================================================
  group('Integration — CommunityBoardPage', () {

    testWidgets('IT-COM-1: Aba inicial mostra secção Condutores', (tester) async {
      await launchHomeShell(tester);
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);
      expect(find.text('Condutores'), findsOneWidget);
      expect(find.text('Passageiros'), findsOneWidget);
      expect(find.text('Sem passageiros disponiveis.'), findsNothing);
    });

    testWidgets('IT-COM-2: Trocar para Passageiros mostra secção correta', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.text('Passageiros'));
      await tester.pumpAndSettle();
      expect(find.text('Sem passageiros disponiveis.'), findsOneWidget);
    });

    testWidgets('IT-COM-3: SegmentedButton de secções está presente', (tester) async {
      await launchHomeShell(tester);
      expect(find.byType(SegmentedButton<int>), findsOneWidget);
      expect(find.text('Condutores'), findsOneWidget);
      expect(find.text('Passageiros'), findsOneWidget);
    });

    testWidgets('IT-COM-4: Sem token, selecionar Passageiros mostra snackbar de sessão', (tester) async {
      Ride4FreeAuth.token = null;
      await launchHomeShell(tester);
      await tester.tap(find.text('Passageiros'));
      await tester.pump();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });

    testWidgets('IT-COM-5: Labels das secções estão todos visíveis', (tester) async {
      await launchHomeShell(tester);
      expect(find.text('Condutores'), findsOneWidget);
      expect(find.text('Passageiros'), findsOneWidget);
    });

    testWidgets('IT-COM-6: Trocar de secção e voltar mantém estado correto', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.text('Passageiros'));
      await tester.pumpAndSettle();
      expect(find.text('Sem passageiros disponiveis.'), findsOneWidget);
      await tester.tap(find.text('Condutores'));
      await tester.pumpAndSettle();
      expect(find.byType(SegmentedButton<int>), findsOneWidget);
      expect(find.text('Sem passageiros disponiveis.'), findsNothing);
    });

    testWidgets('IT-COM-7: Sem token, selecionar Condutores mostra snackbar de sessão', (tester) async {
      Ride4FreeAuth.token = null;
      await launchHomeShell(tester);
      // A página já está em Condutores — selecionar novamente via tap
      await tester.tap(find.text('Condutores'));
      await tester.pump();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });

    testWidgets('IT-COM-8: TopTitleBar da comunidade tem título correto', (tester) async {
      await launchHomeShell(tester);
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  // ===========================================================================
  // IT-SEARCH: SearchRidePage
  // ===========================================================================
  group('Integration — SearchRidePage', () {

    testWidgets('IT-SRC-1: Página de pesquisa carrega com título correto', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Boleias Encontradas'), findsOneWidget);
    });

    testWidgets('IT-SRC-2: Sem token, "Pedir boleia" mostra snackbar de sessão', (tester) async {
      Ride4FreeAuth.token = null;
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pedir boleia'));
      await tester.pump();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });

    testWidgets('IT-SRC-3: Slider de raio está presente na página de pesquisa', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Raio de Tolerancia'), findsOneWidget);
    });

    testWidgets('IT-SRC-4: Botão "Reservar Boleia" está visível', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Reservar Boleia'), findsOneWidget);
    });

    testWidgets('IT-SRC-5: Sem token, "Reservar Boleia" mostra snackbar de sessão', (tester) async {
      Ride4FreeAuth.token = null;
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reservar Boleia'));
      await tester.pump();
      expect(find.text('Inicie sessão no perfil.'), findsOneWidget);
    });

    testWidgets('IT-SRC-6: Botão "Procurar condutores" está visível', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Procurar condutores'), findsOneWidget);
    });
  });

  // ===========================================================================
  // IT-OFFER: OfferRidePage — apenas widgets visíveis sem scroll
  // ===========================================================================
  group('Integration — OfferRidePage', () {

    testWidgets('IT-OFR-1: Página de oferta carrega com título correto', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();
      expect(find.text('Oferecer Boleia'), findsOneWidget);
    });

  

    testWidgets('IT-OFR-3: Página de oferta tem label PONTO DE PARTIDA', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();
      expect(find.text('PONTO DE PARTIDA'), findsOneWidget);
    });

    testWidgets('IT-OFR-4: Instrução de "Toque no mapa" visível para ponto de partida', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();
      expect(find.text('Toque no mapa para definir o ponto de partida'), findsOneWidget);
    });

  });

  // ===========================================================================
  // IT-BOOT: AppBootstrapper
  // ===========================================================================
  group('Integration — AppBootstrapper (bootstrapping)', () {

    testWidgets('IT-BOOT-1: Sem sessão, CircularProgressIndicator aparece primeiro', (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('IT-BOOT-2: Sem sessão, após settle mostra UniversityLoginPage', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.byType(UniversityLoginPage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('IT-BOOT-3: Com sessão guardada, salta directamente para HomeShell', (tester) async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up111222333',
        'university_display_name': 'Utilizador Sessão',
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(UniversityLoginPage), findsNothing);
    });

    testWidgets('IT-BOOT-4: Com sessão, username correcto aparece no perfil', (tester) async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up555666777',
        'university_display_name': 'Carlos Ferreira',
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('UP: up555666777'), findsOneWidget);
      expect(find.text('Carlos Ferreira'), findsOneWidget);
    });


    testWidgets('IT-BOOT-9: NavigationBar tem 5 destinos no HomeShell', (tester) async {
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up999',
        'university_display_name': 'Test User',
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      

      expect(find.byType(NavigationDestination), findsNWidgets(5)); 
    });

    testWidgets('IT-BOOT-10: MyApp usa MaterialApp com tema correto', (tester) async {
      await tester.pumpWidget(const MyApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });
  });
  // ===========================================================================
  // IT-PEDIDOS: PedidosPage
  // ===========================================================================
  group('Integration — PedidosPage', () {

    testWidgets('IT-PED-1: Página de Pedidos carrega com título e abas corretas', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.inbox)); // Ícone da aba Pedidos
      await tester.pumpAndSettle();

      expect(find.text('Pedidos de Boleia'), findsOneWidget);
      expect(find.text('Os meus pedidos'), findsOneWidget);
      expect(find.text('Pedidos recebidos'), findsOneWidget);
    });

    testWidgets('IT-PED-2: Aba "Os meus pedidos" mostra estado vazio corretamente', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.inbox));
      await tester.pumpAndSettle();

      // Sem dados mockados, a lista deve estar vazia e mostrar este texto
      expect(find.text('Ainda não pediste boleias.'), findsOneWidget);
    });

    testWidgets('IT-PED-3: Trocar para a aba "Pedidos recebidos" atualiza a vista', (tester) async {
      await launchHomeShell(tester);
      await tester.tap(find.byIcon(Icons.inbox));
      await tester.pumpAndSettle();

      // Clica na segunda tab
      await tester.tap(find.text('Pedidos recebidos'));
      await tester.pumpAndSettle();

      expect(find.text('Sem pedidos de passageiros.'), findsOneWidget);
    });
  });
  
}