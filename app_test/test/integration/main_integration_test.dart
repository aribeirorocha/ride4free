import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:app_test/main.dart';
import 'package:app_test/sigarra/sigarra_auth_service.dart';
import 'package:app_test/ride4free_api.dart';
void main() {
  group('Integration - Navegação e Estrutura Principal', () {
    
    testWidgets('Deve navegar entre todas as abas da HomeShell sem erros', (tester) async {
      // Simulamos que já estamos autenticados para entrar na HomeShell
      final identity = UniversityIdentity(username: 'up123', displayName: 'Teste');
      
      await tester.pumpWidget(MaterialApp(
        home: HomeShell(
          onUniversityLogout: () async {},
          identity: identity,
        ),
      ));

      // Aba 1: Comunidade
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);

      // Navegar para Busca (Aba 2)
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Boleias Encontradas'), findsOneWidget);

      // Navegar para Oferecer (Aba 3)
      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();
      expect(find.text('Oferecer Boleia'), findsOneWidget);

      // Navegar para Perfil (Aba 4)
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('UP: up123'), findsOneWidget);
    });
  });
  group('Integration - Main & Bootstrapping', () {
    
    setUp(() {
      // Limpa as preferências antes de cada teste para garantir isolamento
      SharedPreferences.setMockInitialValues({});
      Ride4FreeAuth.token = null;
    });

    testWidgets('MAIN-IT1: Se não houver sessão, deve mostrar UniversityLoginPage', (tester) async {
      await tester.pumpWidget(const MyApp());
      
      // O AppBootstrapper começa em loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();

      // Verifica se o formulário de login universitário aparece
      expect(find.byType(UniversityLoginPage), findsOneWidget);
      expect(find.text('Autenticacao Universitaria'), findsOneWidget);
    });

    testWidgets('MAIN-IT2: Validação de campos vazios no Login Universitário', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tenta clicar em Entrar sem preencher nada
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Preencha as credenciais universitarias.'), findsOneWidget);
    });

    testWidgets('MAIN-IT3: Se já houver sessão no disco, deve saltar o login e ir para HomeShell', (tester) async {
      // Simulamos que o UniversitySessionStore já tem dados guardados
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up123456789',
        'university_display_name': 'Estudante Teste',
      });

      await tester.pumpWidget(const MyApp());
      
      // Aguarda o _restoreSession completar
      await tester.pumpAndSettle();

      // Já não deve estar no Login, mas sim na Home
      expect(find.byType(UniversityLoginPage), findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);
    });

    testWidgets('MAIN-IT4: Fluxo de Logout limpa ecrã e volta ao Login', (tester) async {
      // 1. Começamos logados
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up123456789',
        'university_display_name': 'Estudante Teste',
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 2. Navegamos até ao Perfil (index 3)
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // 3. Clicamos no botão de Logout Universitário
      final logoutBtn = find.widgetWithText(OutlinedButton, 'Terminar sessão universitária');
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      
      // Aguarda as animações de saída e transição do Bootstrapper
      await tester.pumpAndSettle();

      // 4. Devemos estar de volta ao Login
      expect(find.byType(UniversityLoginPage), findsOneWidget);
      
      // 5. Verifica se as SharedPreferences foram limpas
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('university_logged_in'), isNull);
    });

    testWidgets('MAIN-IT5: TopTitleBar exibe o título correto em diferentes contextos', (tester) async {
      // Teste rápido de widget de integração
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: TopTitleBar(title: 'Teste de Título')),
      ));

      expect(find.text('Teste de Título'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      // Verifica se a cor de fundo é o kRed definido (0xFFDF3E45)
      final container = tester.widget<Container>(find.byType(Container).first);
      expect((container.decoration as BoxDecoration?)?.color, isNull); // É via 'color' property
      expect(container.color, const Color(0xFFDF3E45));
    });
  });
}