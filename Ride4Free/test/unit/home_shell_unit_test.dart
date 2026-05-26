import 'package:Ride4Free/sigarra/sigarra_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Ride4Free/main.dart';




void main() {
  group('Unit/Widget Tests - Ride4Free App', () {

    final testIdentity = UniversityIdentity(
      username: 'up123456',
      displayName: 'Utilizador Teste',
    );

    testWidgets('UT-1: Navegação entre abas no HomeShell', (tester) async {
      
      await tester.pumpWidget(MaterialApp(
        home: HomeShell(
          identity: testIdentity, // Garante que a variável existe
          onUniversityLogout: () async { return; },
        ),
      ));

      // Esperar que a página carregue as localizações e renderize
      await tester.pumpAndSettle();

      // 2. Verificação Inicial (Aba 0)
      expect(find.byType(CommunityBoardPage), findsOneWidget);

      // 3. Navegação para Procura (Aba 1)
      // Como as coordenadas agora estão perfeitas, o tap normal funciona à primeira!
      final searchTab = find.widgetWithText(NavigationDestination, 'Procurar');
      await tester.tap(searchTab);
      await tester.pumpAndSettle();

      // Confirma que abriu a aba da Lupa
      expect(find.byType(SearchRidePage), findsOneWidget);

      // 4. Navegação para Oferta (Aba 2)
      final offerTab = find.widgetWithText(NavigationDestination, 'Oferecer');
      await tester.tap(offerTab);
      await tester.pumpAndSettle();

      // Confirma que abriu a aba do Carro
      expect(find.byType(OfferRidePage), findsOneWidget);
    });
          testWidgets('UT-3: O ecrã SearchRidePage carrega no estado inicial correto', (tester) async {
      // Truque do ecrã grande para o Slider e os botões estarem visíveis sem scroll
      tester.view.physicalSize = const Size(1080, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());
      
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchRidePage())));
      
      // CORREÇÃO: pumpAndSettle para esperar que o _fetchLocation() termine
      await tester.pumpAndSettle();

      expect(find.text('Procurar condutores'), findsOneWidget);
      
      // CORREÇÃO: O teu _label() converte tudo para maiúsculas!
      expect(find.text('RAIO DE TOLERANCIA'), findsOneWidget);
      
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}