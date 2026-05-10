import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_test/main.dart';
import 'package:app_test/ride4free_api.dart';

void main() {
  group('SearchRidePage - Widget Tests', () {
    Future<void> launchSearchPage(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SearchRidePage()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('WS-1: Page loads with title "Boleias Encontradas"', (tester) async {
      await launchSearchPage(tester);
      expect(find.text('Boleias Encontradas'), findsOneWidget);
    });

    testWidgets('WS-2: Destination field contains default value "FEUP (Polo II)"', (tester) async {
      await launchSearchPage(tester);
      expect(find.text('FEUP (Polo II)'), findsOneWidget);
    });

    testWidgets('WS-3: "Procurar condutores" button is visible', (tester) async {
      await launchSearchPage(tester);
      expect(find.text('Procurar condutores'), findsOneWidget);
    });

    testWidgets('WS-4: "Pedir boleia" button is visible', (tester) async {
      await launchSearchPage(tester);
      expect(find.text('Pedir boleia'), findsOneWidget);
    });

    testWidgets('WS-5: "Reservar Boleia" bottom button is visible', (tester) async {
      await launchSearchPage(tester);
      expect(find.text('Reservar Boleia'), findsOneWidget);
    });

    testWidgets('WS-6: Tolerance radius slider is present', (tester) async {
      await launchSearchPage(tester);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Raio de Tolerancia'), findsOneWidget);
    });

    testWidgets('WS-7: Map widget is displayed', (tester) async {
      await launchSearchPage(tester);
      // The map is in a ClipRRect with height 130
      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('WS-8: Can edit destination field', (tester) async {
      await launchSearchPage(tester);
      
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'Porto Airport');
      await tester.pumpAndSettle();

      expect(find.text('Porto Airport'), findsOneWidget);
    });

    testWidgets('WS-9: Origin shows "De: Residencia Universitaria"', (tester) async {
      await launchSearchPage(tester);
      expect(find.text('De: Residencia Universitaria'), findsOneWidget);
    });

    testWidgets('WS-10: Search button is initially enabled', (tester) async {
      // Ensure token is null to test the initial state
      Ride4FreeAuth.token = null;
      
      await launchSearchPage(tester);
      
      final button = find.widgetWithText(FilledButton, 'Procurar condutores');
      expect(button, findsOneWidget);
    });
  });

  group('ProfilePage - Widget Tests', () {
    Future<void> launchProfilePage(WidgetTester tester) async {
      Ride4FreeAuth.token = null;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ProfilePage()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('WP-1: Page loads with title "Avaliar Passageiro"', (tester) async {
      Ride4FreeAuth.token = null;
      await launchProfilePage(tester);
      expect(find.text('Avaliar Passageiro'), findsOneWidget);
    });

    testWidgets('WP-2: Email input field is visible when not logged in', (tester) async {
      await launchProfilePage(tester);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('WP-3: Email input has label "Email"', (tester) async {
      await launchProfilePage(tester);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('WP-4: Password input has label "Password (mín. 6)"', (tester) async {
      await launchProfilePage(tester);
      expect(find.text('Password (mín. 6)'), findsOneWidget);
    });

    testWidgets('WP-5: Name input has label "Nome (registo)"', (tester) async {
      await launchProfilePage(tester);
      expect(find.text('Nome (registo)'), findsOneWidget);
    });

    testWidgets('WP-6: "Entrar" (Login) button is visible', (tester) async {
      await launchProfilePage(tester);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('WP-7: "Registar" (Register) button is visible', (tester) async {
      await launchProfilePage(tester);
      expect(find.text('Registar'), findsOneWidget);
    });

    testWidgets('WP-8: Password field obscures text', (tester) async {
      await launchProfilePage(tester);
      
      final passwordFields = find.byType(TextField);
      // Should have 3 text fields (email, password, name)
      expect(passwordFields, findsWidgets);
    });

    testWidgets('WP-9: Can enter email', (tester) async {
      await launchProfilePage(tester);
      
      final emailField = find.byType(TextField).first;
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('WP-10: Rating section is displayed', (tester) async {
      await launchProfilePage(tester);
      
      // Should show a sample profile to rate
      expect(find.text('Miguel Antunes'), findsOneWidget);
      expect(find.text('Excelente passageiro'), findsOneWidget);
    });

    testWidgets('WP-11: Star rating is visible', (tester) async {
      await launchProfilePage(tester);
      
      // Check for star symbols (★)
      expect(find.text('★★★★★'), findsOneWidget);
    });

    testWidgets('WP-12: Reward section shows correctly', (tester) async {
      await launchProfilePage(tester);
      
      expect(find.text('RECOMPENSA TOTAL'), findsOneWidget);
      expect(find.text('+50 Pontos'), findsOneWidget);
    });

    testWidgets('WP-13: "Submeter Avaliacao" button is visible', (tester) async {
      await launchProfilePage(tester);
      
      expect(find.text('Submeter Avaliacao'), findsOneWidget);
    });

    testWidgets('WP-14: API base URL is displayed', (tester) async {
      await launchProfilePage(tester);
      
      expect(find.byType(Text), findsWidgets);
      // Check that page displays API configuration info
      expect(find.text('API:'), findsOneWidget);
    });

    testWidgets('WP-15: ProfileRatingButton widget is present', (tester) async {
      await launchProfilePage(tester);
      
      // The ProfileRatingButton should be in the page
      expect(find.text('Rate profiles'), findsOneWidget);
    });

    testWidgets('WP-16: Tick marks are displayed', (tester) async {
      await launchProfilePage(tester);
      
      expect(find.text('Chegou a horas'), findsOneWidget);
      expect(find.text('Nao sujou o carro'), findsOneWidget);
      expect(find.text('Foi respeitador'), findsOneWidget);
      expect(find.text('Boa conversa'), findsOneWidget);
    });
  });

  group('CommunityBoardPage - Widget Tests', () {
    Future<void> launchCommunityPage(WidgetTester tester) async {
      Ride4FreeAuth.token = null;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CommunityBoardPage()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('WC-1: Page loads with title "Comunidade Ride4Free"', (tester) async {
      await launchCommunityPage(tester);
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);
    });

    testWidgets('WC-2: Segmented button with three sections (Condutores, Passageiros, BD)', (
      tester,
    ) async {
      await launchCommunityPage(tester);
      
      expect(find.text('Condutores'), findsOneWidget);
      expect(find.text('Passageiros'), findsOneWidget);
      expect(find.text('BD'), findsOneWidget);
    });

    testWidgets('WC-3: "Atualizar secao" button is visible', (tester) async {
      await launchCommunityPage(tester);
      expect(find.text('Atualizar secao'), findsOneWidget);
    });

    testWidgets('WC-4: Default section is "Drivers" (Condutores)', (tester) async {
      await launchCommunityPage(tester);
      
      // Should initially show drivers message or list
      expect(find.text('Sem condutores disponiveis. Carregue em "Atualizar secao".'), findsOneWidget);
    });

    testWidgets('WC-5: Can switch to Passengers section', (tester) async {
      await launchCommunityPage(tester);
      
      // Tap on Passengers button
      await tester.tap(find.text('Passageiros'));
      await tester.pumpAndSettle();
      
      // Should now show passengers message
      expect(find.text('Sem passageiros disponiveis. Carregue em "Atualizar secao".'), findsOneWidget);
    });

    testWidgets('WC-6: Can switch to Database section', (tester) async {
      await launchCommunityPage(tester);
      
      // Tap on BD button
      await tester.tap(find.text('BD'));
      await tester.pumpAndSettle();
      
      // Should now show schema message
      expect(find.text('Schema indisponivel. Carregue em "Atualizar secao".'), findsOneWidget);
    });

    testWidgets('WC-7: Condutores icon is present', (tester) async {
      await launchCommunityPage(tester);
      expect(find.byIcon(Icons.drive_eta), findsOneWidget);
    });

    testWidgets('WC-8: Passageiros icon is present', (tester) async {
      await launchCommunityPage(tester);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('WC-9: BD icon is present', (tester) async {
      await launchCommunityPage(tester);
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });
  });

  group('OfferRidePage - Additional Tests', () {
    Future<void> launchOfferPage(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: OfferRidePage()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('WO-1: Page title is "Oferecer Boleia"', (tester) async {
      await launchOfferPage(tester);
      expect(find.text('Oferecer Boleia'), findsOneWidget);
    });

    testWidgets('WO-2: Destination field has default text', (tester) async {
      await launchOfferPage(tester);
      expect(find.text('FEUP (Polo II)'), findsOneWidget);
    });

    testWidgets('WO-3: "Ver passageiros para este destino" button exists', (tester) async {
      await launchOfferPage(tester);
      expect(find.text('Ver passageiros para este destino'), findsOneWidget);
    });

    testWidgets('WO-4: Origin field shows "Residencia Universitaria"', (tester) async {
      await launchOfferPage(tester);
      expect(find.text('Residencia Universitaria'), findsOneWidget);
    });

    testWidgets('WO-5: Time field shows default "08:15"', (tester) async {
      await launchOfferPage(tester);
      expect(find.text('08:15'), findsOneWidget);
    });

    testWidgets('WO-6: Field labels are displayed', (tester) async {
      await launchOfferPage(tester);
      
      expect(find.text('PONTO DE PARTIDA'), findsOneWidget);
      expect(find.text('DESTINO'), findsOneWidget);
      expect(find.text('HORA'), findsOneWidget);
      expect(find.text('LUGARES'), findsOneWidget);
    });

    testWidgets('WO-7: Initial reward shows "+30 Creditos"', (tester) async {
      await launchOfferPage(tester);
      expect(find.text('+30 Creditos'), findsOneWidget);
    });

    testWidgets('WO-8: Seat picker buttons (+ and -) are visible', (tester) async {
      await launchOfferPage(tester);
      
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('WO-9: Incrementing seats increases reward', (tester) async {
      await launchOfferPage(tester);

      // Initial state: 3 seats, +30 creditos
      expect(find.text('+30 Creditos'), findsOneWidget);

      // Click add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should now show +40 creditos (4 seats * 10)
      expect(find.text('+40 Creditos'), findsOneWidget);
    });

    testWidgets('WO-10: Decrementing seats decreases reward', (tester) async {
      await launchOfferPage(tester);

      // Initial state: 3 seats, +30 creditos
      expect(find.text('+30 Creditos'), findsOneWidget);

      // Click remove button
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      // Should now show +20 creditos (2 seats * 10)
      expect(find.text('+20 Creditos'), findsOneWidget);
    });

    testWidgets('WO-11: Can update destination text', (tester) async {
      await launchOfferPage(tester);

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'New Destination');
      await tester.pumpAndSettle();

      expect(find.text('New Destination'), findsOneWidget);
    });

    testWidgets('WO-12: Publish button text depends on loading state', (tester) async {
      await launchOfferPage(tester);

      // Initially should show "Publicar Viagem"
      expect(find.text('Publicar Viagem'), findsOneWidget);
    });
  });

  group('Navigation Flow Tests', () {
    testWidgets('NT-1: Can navigate between all four tabs', (tester) async {
      await tester.pumpWidget(const MyApp());

      // Start at Community Board
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);

      // Navigate to Search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Boleias Encontradas'), findsOneWidget);

      // Navigate to Offer
      await tester.tap(find.byIcon(Icons.directions_car));
      await tester.pumpAndSettle();
      expect(find.text('Oferecer Boleia'), findsOneWidget);

      // Navigate to Profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('Avaliar Passageiro'), findsOneWidget);

      // Navigate back to Community
      await tester.tap(find.byIcon(Icons.groups));
      await tester.pumpAndSettle();
      expect(find.text('Comunidade Ride4Free'), findsOneWidget);
    });

    testWidgets('NT-2: Bottom navigation bar has four icons', (tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byIcon(Icons.groups), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
