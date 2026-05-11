import 'package:app_test/sigarra/sigarra_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_test/main.dart';




void main() {
  group('Unit/Widget Tests - Ride4Free App', () {

    final testIdentity = UniversityIdentity(
      username: 'up123456',
      displayName: 'Utilizador Teste',
    );

    testWidgets('UT-1: Navegação entre abas no HomeShell', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Monta o widget
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HomeShell(
            identity: testIdentity,
            onUniversityLogout: () async { return; },
          ),
        ),
      ));

      // 2. O SEGREDO: pump(Duration) permite que o initState complete 
      // e que o addPostFrameCallback (do _showMessage) seja executado com segurança.
      await tester.pump(const Duration(milliseconds: 100));

      // 3. Verificação Inicial (Comunidade)
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);

      // 4. Navegação para Procura (Ícone de lupa)
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Boleias Encontradas'), findsOneWidget);

      // 5. Navegação para Oferta (Ícone de carro)
      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Oferecer Boleia'), findsOneWidget);
    });


    testWidgets('UT-3: O ecrã SearchRidePage carrega no estado inicial correto', (tester) async {
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchRidePage())));
      await tester.pump();

      expect(find.text('Procurar condutores'), findsOneWidget);
      expect(find.text('Raio de Tolerancia'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}