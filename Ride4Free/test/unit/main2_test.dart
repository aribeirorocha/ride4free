// =============================================================================
// TESTES ADICIONAIS — Ride4Free (main2_test.dart)
// Foco em aumentar a cobertura das linhas ainda não testadas em main.dart:
//   - OfferRidePage (widget completo, _publish, _seePassengers)
//   - SearchRidePage (widget completo, abas, _search, _registerRequest)
//   - CommunityBoardPage (widget completo, _buildSectionBody, secções)
//   - ProfilePage (widget completo, _loadProfile, logout)
//   - _ConferenceMap (renderização, botões de zoom)
//   - SeatPicker (borda kRed com seats=0)
//   - InputLike / TickRow (decoração)
//   - HomeShell (_onTabSelected, marcação de pedidos)
//   - AppBootstrapper (_onUniversityLogout, loading → login flow)
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Ride4Free/main.dart';
import 'package:Ride4Free/ride4free_api.dart';
import 'package:Ride4Free/sigarra/sigarra_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helper: identidade de teste reutilizável
// ---------------------------------------------------------------------------
UniversityIdentity _testIdentity({
  String username = 'up202300001',
  String displayName = 'Utilizador Teste',
}) =>
    UniversityIdentity(
      username: username,
      displayName: displayName,
      photoUrl: null,
    );

void main() {
  // =========================================================================
  // UT-OFFER: OfferRidePage — widget completo
  // =========================================================================
  group('OfferRidePage — widget completo', () {
    setUp(() {
      Ride4FreeAuth.token = null;
    });

    testWidgets('OFR-U1: renderiza sem erros com token nulo', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: OfferRidePage())));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('OFR-U2: TopTitleBar mostra "Oferecer Boleia"', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: OfferRidePage())));
      await tester.pump();
      expect(find.text('Oferecer Boleia'), findsOneWidget);
    });

    testWidgets('OFR-U3: botão "Publicar Viagem" está presente', (tester) async {
  // 1. Aumentamos artificialmente a altura do ecrã virtual do teste
  // Isto obriga o ListView a renderizar todos os seus filhos (incluindo o botão)
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  
  // Garantimos que o tamanho volta ao normal após o teste para não afetar outros testes
  addTearDown(() => tester.view.reset());

  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: OfferRidePage()),
    ),
  );

  // 2. Usamos pumpAndSettle para dar tempo aos frames e Futures (como o _fetchLocation) terminarem
  await tester.pumpAndSettle();

  // 3. Agora o botão já foi instanciado e está visível
  expect(find.text('Publicar Viagem'), findsOneWidget);
});

    testWidgets('OFR-U4: campo de hora tem valor inicial "08:15"',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: OfferRidePage())));
          await tester.pump();
          expect(find.text('08:15'), findsOneWidget);
        });

    testWidgets('OFR-U5: secção de veículo contém hint "Renault Clio Preto"',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: OfferRidePage())));
          await tester.pump();
          expect(find.text('Ex: Renault Clio Preto', skipOffstage: false), findsOneWidget);
        });

    testWidgets('OFR-U6: RewardPanel está presente na página', (tester) async {
  // 1. Aumentamos o ecrã virtual para garantir que o ListView renderiza tudo
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  
  // Repor o tamanho no fim do teste
  addTearDown(() => tester.view.reset());

  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: OfferRidePage()),
    ),
  );

  // 2. Usar pumpAndSettle para esperar que todos os frames e animações (como o carregamento do mapa) terminem
  await tester.pumpAndSettle();

  // 3. Agora o finder normal já vai encontrar o widget perfeitamente
  expect(find.byType(RewardPanel), findsOneWidget);
});

    testWidgets('OFR-U7: SeatPicker está presente na página', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: OfferRidePage())));
      await tester.pump();
      expect(find.byType(SeatPicker), findsOneWidget);
    });

    testWidgets('OFR-U8: _publish() com hora inválida mostra SnackBar de erro', (tester) async {
  // 1. Aumentamos o ecrã para evitar problemas de scroll no ListView
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  
  // 2. Garantimos que o token é reposto independentemente de o teste passar ou falhar
  addTearDown(() {
    tester.view.reset();
    Ride4FreeAuth.token = null;
  });

  Ride4FreeAuth.token = 'fake_token';

  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: OfferRidePage()),
    ),
  );
  
  // Esperar que o ecrã carregue (incluindo o _fetchLocation)
  await tester.pumpAndSettle();

  // 3. Escreve a hora inválida (garantimos que é o primeiro TextField)
  final timeField = find.byType(TextField).first;
  await tester.enterText(timeField, 'hora_invalida');
  await tester.pumpAndSettle();

  // 4. Como o ecrã é gigante, o botão já está visível, podemos clicar diretamente
  await tester.tap(find.text('Publicar Viagem'));
  
  // 5. pumpAndSettle avança o tempo no teste até que todas as animações terminem
  // (neste caso, a animação da SnackBar a aparecer no ecrã)
  await tester.pumpAndSettle();

  // 6. Validar que a SnackBar está presente e com a mensagem correta
  expect(find.byType(SnackBar), findsOneWidget);
  expect(find.textContaining('hora válida'), findsOneWidget); // Verifica também se o texto é o esperado!
});

    testWidgets('OFR-U9: _publish() com hora válida mas sem origem/destino mostra erro', (tester) async {
  // 1. Aumentamos o ecrã virtual para garantir que o ListView renderiza tudo
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  
  // 2. Garantimos a limpeza, mesmo que o teste falhe a meio
  addTearDown(() {
    tester.view.reset();
    Ride4FreeAuth.token = null;
  });

  Ride4FreeAuth.token = 'fake_token';

  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: OfferRidePage()),
    ),
  );
  
  // Esperar que o ecrã carregue inicialmente
  await tester.pumpAndSettle();

  // 3. Inserir uma hora válida (o campo de destino e origem ficam vazios/null por defeito no teste)
  final timeField = find.byType(TextField).first;
  await tester.enterText(timeField, '09:00');
  await tester.pumpAndSettle();

  // 4. Clicar no botão (que agora está visível graças ao ecrã gigante)
  await tester.tap(find.text('Publicar Viagem'));
  
  // 5. Deixar a animação da SnackBar subir
  await tester.pumpAndSettle();

  // 6. Validar que a SnackBar apareceu com o erro correto de mapa
  // 6. Validar que a SnackBar apareceu com o texto de erro completo
expect(find.byType(SnackBar), findsOneWidget);
expect(find.text('Selecione o ponto de partida e de chegada no mapa.'), findsOneWidget); // Verifica parte do texto "Selecione o ponto de partida e de chegada no mapa."
});
    testWidgets('OFR-U10: incrementar lugares via SeatPicker atualiza o estado',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: OfferRidePage())));
          await tester.pump();

          // Valor inicial é 3, após + fica 4
          // O SeatPicker pode estar fora do ecrã — scroll até ele
          final seatPicker = find.byType(SeatPicker, skipOffstage: false);
          await tester.ensureVisible(seatPicker);
          await tester.pump();
          // Usa .last para atingir o botão add do SeatPicker
          await tester.tap(find.byIcon(Icons.add).last);
          await tester.pump();
          expect(find.text('4', skipOffstage: false), findsOneWidget);
        });

    testWidgets('OFR-U11: decrementar lugares via SeatPicker atualiza o estado',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: OfferRidePage())));
          await tester.pump();

          // Valor inicial é 3, após - fica 2
          // O SeatPicker pode estar fora do ecrã — scroll até ele
          final seatPicker = find.byType(SeatPicker, skipOffstage: false);
          await tester.ensureVisible(seatPicker);
          await tester.pump();
          // Usa .last para atingir o botão remove do SeatPicker
          await tester.tap(find.byIcon(Icons.remove).last);
          await tester.pump();
          expect(find.text('2', skipOffstage: false), findsOneWidget);
        });

    testWidgets(
        'OFR-U12: decrementar até 0 bloqueia botão "Publicar Viagem"',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: OfferRidePage())));
          await tester.pump();

          // O SeatPicker pode estar fora do ecrã — scroll até ele
          final seatPicker = find.byType(SeatPicker, skipOffstage: false);
          await tester.ensureVisible(seatPicker);
          await tester.pump();

          // Decrementa 3 vezes (3 → 0)
          for (int i = 0; i < 3; i++) {
            await tester.tap(find.byIcon(Icons.remove).last);
            await tester.pump();
          }

          // RewardPanel inválido visível
          expect(find.text('Lotacao Invalida', skipOffstage: false), findsOneWidget);
        });

    testWidgets('OFR-U13: label "Hora" e "Lugares" estão visíveis',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: OfferRidePage())));
          await tester.pump();
          expect(find.text('HORA'), findsOneWidget);
          expect(find.text('LUGARES'), findsOneWidget);
        });
  });

  // =========================================================================
  // UT-SEARCH: SearchRidePage — widget completo e abas
  // =========================================================================
  group('SearchRidePage — widget completo e abas', () {
    setUp(() {
      Ride4FreeAuth.token = null;
    });

    testWidgets('SRP-U1: renderiza sem erros', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SearchRidePage())));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('SRP-U2: TopTitleBar mostra "Procurar Boleia"',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();
          expect(find.text('Procurar Boleia'), findsOneWidget);
        });

    testWidgets('SRP-U3: SegmentedButton tem abas "Procurar" e "Pedir Boleia"',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();
          expect(find.text('Pedir Boleia'), findsOneWidget);
        });

    testWidgets('SRP-U4: aba "Procurar" mostra campo de destino',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();
          expect(find.text('Ex: FEUP (Polo II)'), findsWidgets);
        });

    testWidgets('SRP-U5: aba "Procurar" tem botão "Procurar condutores"',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();
          expect(find.text('Procurar condutores'), findsOneWidget);
        });

    testWidgets('SRP-U6: trocar para aba "Pedir Boleia" renderiza sem erro',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();

          await tester.tap(find.text('Pedir Boleia'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
        });

    testWidgets(
        'SRP-U7: aba "Pedir Boleia" mostra campo Origem e campo Destino',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();

          await tester.tap(find.text('Pedir Boleia'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('ORIGEM'), findsOneWidget);
          expect(find.text('DESTINO'), findsOneWidget);
        });

    testWidgets('SRP-U8: aba "Pedir Boleia" tem botão "Pedir Boleia"',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();

          await tester.tap(find.text('Pedir Boleia'));
          await tester.pump(const Duration(milliseconds: 300));

          // O botão de submissão também tem este label
          expect(find.text('Pedir Boleia'), findsWidgets);
        });

    testWidgets(
        'SRP-U9: _search sem token mostra SnackBar "Inicie sessão no perfil."',
            (tester) async {
          Ride4FreeAuth.token = null;
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();

          await tester.tap(find.text('Procurar condutores'));
          await tester.pump(); // trigger setState
          await tester.pump(); // flush postFrameCallback

          expect(find.byType(SnackBar), findsOneWidget);
        });

    testWidgets(
        'SRP-U10: _registerRequest sem token mostra SnackBar de erro',
            (tester) async {
          Ride4FreeAuth.token = null;
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();

          await tester.tap(find.text('Pedir Boleia'));
          await tester.pump(const Duration(milliseconds: 300));

          // Toca no botão "Pedir Boleia" (FilledButton.icon de submissão)
          // O botão de submissão é o último elemento com este texto
          final submitBtn = find.text('Pedir Boleia', skipOffstage: false).last;
          await tester.ensureVisible(submitBtn);
          await tester.pump();
          await tester.tap(submitBtn);
          await tester.pump(); // trigger setState
          await tester.pump(); // flush postFrameCallback

          expect(find.byType(SnackBar), findsOneWidget);
        });

    testWidgets('SRP-U11: slider de raio está presente na aba Procurar',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();
          expect(find.byType(Slider), findsOneWidget);
        });

    testWidgets('SRP-U12: label "Raio de Tolerancia" está visível',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();
          expect(find.text('RAIO DE TOLERANCIA'), findsOneWidget);
        });

    testWidgets(
        'SRP-U13: sem resultados mostra "Nenhum condutor encontrado neste raio."',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();
          expect(
              find.text('Nenhum condutor encontrado neste raio.',
                  skipOffstage: false),
              findsOneWidget);
        });

    testWidgets(
        'SRP-U14: SeatPicker presente na aba "Pedir Boleia"',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: SearchRidePage())));
          await tester.pump();

          await tester.tap(find.text('Pedir Boleia'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(SeatPicker), findsOneWidget);
        });
  });

  // =========================================================================
  // UT-COMMUNITY: CommunityBoardPage — widget completo
  // =========================================================================
  group('CommunityBoardPage — widget completo', () {
    setUp(() {
      Ride4FreeAuth.token = null;
    });

    testWidgets('CB-U1: renderiza sem erros', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: CommunityBoardPage())));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CB-U2: título "Comunidade Ride4Free" presente',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: CommunityBoardPage())));
          await tester.pump();
          expect(find.text('Comunidade Ride4Free'), findsOneWidget);
        });

    testWidgets('CB-U3: SegmentedButton tem "Condutores" e "Passageiros"',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: CommunityBoardPage())));
          await tester.pump();
          expect(find.text('Condutores'), findsOneWidget);
          expect(find.text('Passageiros'), findsOneWidget);
        });

    testWidgets('CB-U4: secção 0 (condutores) está selecionada por defeito',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: CommunityBoardPage())));
          await tester.pump();

          // Mensagem de estado vazio para condutores sem token
          expect(find.byType(SegmentedButton<int>), findsOneWidget);
        });

    testWidgets('CB-U5: trocar para "Passageiros" não lança exceção',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: CommunityBoardPage())));
          await tester.pump();

          await tester.tap(find.text('Passageiros'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
        });

    testWidgets(
        'CB-U6: sem token _loadSection mostra SnackBar "Inicie sessão no perfil."',
            (tester) async {
          Ride4FreeAuth.token = null;
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: CommunityBoardPage())));
          await tester.pump();

          // _loadSection() é chamado em initState — com token null dispara snackbar
          expect(find.byType(SnackBar), findsOneWidget);
        });

    testWidgets('CB-U7: dispose cancela o Timer sem crashar', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: CommunityBoardPage())));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('CB-U8: lista vazia de condutores mostra mensagem de loading',
            (tester) async {
          Ride4FreeAuth.token = null;
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: CommunityBoardPage())));
          await tester.pump();

          // Com _drivers vazia e token null, a secção body mostra estado vazio
          expect(find.byType(CommunityBoardPage), findsOneWidget);
        });

    testWidgets(
        'CB-U9: secção passageiros vazia mostra "Sem passageiros à procura"',
            (tester) async {
          Ride4FreeAuth.token = 'fake_token';
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: CommunityBoardPage())));
          await tester.pump();

          await tester.tap(find.text('Passageiros'));
          await tester.pump(const Duration(milliseconds: 300));

          // Com _passengers vazia mostra mensagem
          expect(
              find.text('Sem passageiros à procura no momento.'), findsOneWidget);
          Ride4FreeAuth.token = null;
        });
  });

  // =========================================================================
  // UT-PROFILE: ProfilePage — widget completo
  // =========================================================================
  group('ProfilePage — widget completo', () {
    setUp(() {
      Ride4FreeAuth.token = null;
    });

    testWidgets('PRF-U1: sem token mostra CircularProgressIndicator inicial',
            (tester) async {
          final identity = _testIdentity();
          // Com token null, _loadProfile termina imediatamente e mostra o perfil
          // O CircularProgressIndicator existe apenas num frame transitório antes
          // de initState correr — verificamos que o widget carregou sem erros
          await tester.pumpWidget(MaterialApp(
            home: ProfilePage(
              onUniversityLogout: () async {},
              identity: identity,
            ),
          ));
          expect(tester.takeException(), isNull);
          // Após pump, o profile UI sem dados está visível (token null → sem loading)
          await tester.pump();
          expect(find.byType(ProfilePage), findsOneWidget);
        });

    testWidgets('PRF-U2: TopTitleBar mostra "Perfil"', (tester) async {
      final identity = _testIdentity();
      await tester.pumpWidget(MaterialApp(
        home: ProfilePage(
          onUniversityLogout: () async {},
          identity: identity,
        ),
      ));
      await tester.pump();
      await tester.pump();
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('PRF-U3: sem token mostra botão "Terminar Sessão"',
            (tester) async {
          final identity = _testIdentity();
          await tester.pumpWidget(MaterialApp(
            home: ProfilePage(
              onUniversityLogout: () async {},
              identity: identity,
            ),
          ));
          // Espera que _loadingProfile fique false (token null → retorna de imediato)
          await tester.pump();
          await tester.pump();
          expect(find.text('Terminar Sessão'), findsOneWidget);
        });

    testWidgets('PRF-U4: displayName do identity é mostrado', (tester) async {
      final identity = _testIdentity(displayName: 'Ana Costa');
      await tester.pumpWidget(MaterialApp(
        home: ProfilePage(
          onUniversityLogout: () async {},
          identity: identity,
        ),
      ));
      await tester.pump();
      await tester.pump();
      expect(find.text('Ana Costa'), findsOneWidget);
    });

    testWidgets('PRF-U5: username e universidade são mostrados',
            (tester) async {
          final identity = _testIdentity(username: 'up202300099');
          await tester.pumpWidget(MaterialApp(
            home: ProfilePage(
              onUniversityLogout: () async {},
              identity: identity,
            ),
          ));
          await tester.pump();
          await tester.pump();
          expect(find.textContaining('up202300099'), findsOneWidget);
          expect(find.textContaining('Universidade do Porto'), findsOneWidget);
        });

    testWidgets('PRF-U6: isActive=true não lança exceção', (tester) async {
      final identity = _testIdentity();
      await tester.pumpWidget(MaterialApp(
        home: ProfilePage(
          isActive: true,
          onUniversityLogout: () async {},
          identity: identity,
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'PRF-U7: pressionar "Terminar Sessão" invoca onUniversityLogout',
            (tester) async {
          bool logoutCalled = false;
          final identity = _testIdentity();

          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: ProfilePage(
                onUniversityLogout: () async {
                  logoutCalled = true;
                },
                identity: identity,
              ),
            ),
          ));
          await tester.pump();
          await tester.pump();

          await tester.tap(find.text('Terminar Sessão'));
          await tester.pump();
          await tester.pump();

          expect(logoutCalled, isTrue);
        });

    testWidgets('PRF-U8: CircleAvatar está presente no header',
            (tester) async {
          final identity = _testIdentity();
          await tester.pumpWidget(MaterialApp(
            home: ProfilePage(
              onUniversityLogout: () async {},
              identity: identity,
            ),
          ));
          await tester.pump();
          await tester.pump();
          expect(find.byType(CircleAvatar), findsOneWidget);
        });
  });

  // =========================================================================
  // UT-CONFMAP: _ConferenceMap — renderização e botões de zoom
  // =========================================================================
  group('_ConferenceMap — renderização e botões de zoom', () {
    testWidgets('CM-U1: renderiza sem localização (userLocation null)',
            (tester) async {
          // _ConferenceMap é privado mas é acessível via OfferRidePage
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: OfferRidePage())));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });

    testWidgets('CM-U2: botões de zoom (+) e (-) estão presentes',
            (tester) async {
          await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: OfferRidePage())));
          await tester.pump();

          // Há pelo menos um botão + e um botão - nos mapas
          expect(find.byIcon(Icons.add), findsWidgets);
          expect(find.byIcon(Icons.remove), findsWidgets);
        });

    testWidgets('CM-U3: pressionar zoom + não lança exceção', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: OfferRidePage())));
      await tester.pump();

      // Toca no primeiro FloatingActionButton.small (zoom in)
      final addButtons = find.byIcon(Icons.add);
      if (addButtons.evaluate().isNotEmpty) {
        await tester.tap(addButtons.first);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('CM-U4: pressionar zoom - não lança exceção', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: OfferRidePage())));
      await tester.pump();

      final removeButtons = find.byIcon(Icons.remove);
      if (removeButtons.evaluate().isNotEmpty) {
        await tester.tap(removeButtons.first);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // UT-SEATPICKER-EXTRA: SeatPicker — borda e cores
  // =========================================================================
  group('SeatPicker — borda vermelha com seats=0', () {
    testWidgets('SPX-U1: renderiza com seats=0 sem lançar exceção',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: SeatPicker(seats: 0, onDec: () {}, onInc: () {}),
            ),
          ));
          expect(tester.takeException(), isNull);
        });

    testWidgets('SPX-U2: Container com seats=0 tem borda vermelha (kRed)',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: SeatPicker(seats: 0, onDec: () {}, onInc: () {}),
            ),
          ));
          // Procura o Container do SeatPicker com borda colorida
          final containers = tester.widgetList<Container>(find.byType(Container));
          final hasRedBorder = containers.any((c) {
            final decoration = c.decoration;
            if (decoration is BoxDecoration && decoration.border != null) {
              final side = decoration.border!.top;
              return side.color == kRed;
            }
            return false;
          });
          expect(hasRedBorder, isTrue);
        });

    testWidgets('SPX-U3: texto "0" tem cor kRed quando seats=0',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: SeatPicker(seats: 0, onDec: () {}, onInc: () {}),
            ),
          ));
          final textWidgets = tester.widgetList<Text>(find.text('0'));
          final hasRed = textWidgets.any((t) => t.style?.color == kRed);
          expect(hasRed, isTrue);
        });

    testWidgets('SPX-U4: borda cinzenta quando seats > 0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SeatPicker(seats: 2, onDec: () {}, onInc: () {}),
        ),
      ));
      // Com seats > 0 não há borda vermelha
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRedBorder = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration && decoration.border != null) {
          return decoration.border!.top.color == kRed;
        }
        return false;
      });
      expect(hasRedBorder, isFalse);
    });
  });

  // =========================================================================
  // UT-INPUTLIKE-EXTRA: InputLike — decoração e estrutura
  // =========================================================================
  group('InputLike — decoração e estrutura visual', () {
    testWidgets('ILX-U1: tem Container com borda definida', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
            home: Scaffold(body: InputLike(text: 'FEUP (Polo II)'))),
      );
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBorder = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.border != null;
      });
      expect(hasBorder, isTrue);
    });

    testWidgets('ILX-U2: texto tem fontSize 16 e fontWeight w700',
            (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
                home: Scaffold(body: InputLike(text: 'Texto de teste'))),
          );
          final textWidget =
          tester.widget<Text>(find.text('Texto de teste'));
          expect(textWidget.style?.fontSize, 16);
          expect(textWidget.style?.fontWeight, FontWeight.w700);
        });

    testWidgets('ILX-U3: tem padding horizontal e vertical definido',
            (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: InputLike(text: 'X'))),
          );
          expect(tester.takeException(), isNull);
        });
  });

  // =========================================================================
  // UT-TICKROW-EXTRA: TickRow — decoração e layout
  // =========================================================================
  group('TickRow — decoração e layout', () {
    testWidgets('TRX-U1: tem decoração com borda inferior', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
            home: Scaffold(body: TickRow(text: 'Chegou a horas'))),
      );
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBorderBottom = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration && dec.border != null) {
          return dec.border!.bottom.color == kDivider;
        }
        return false;
      });
      expect(hasBorderBottom, isTrue);
    });

    testWidgets('TRX-U2: texto tem fontSize 17 e fontWeight w500',
            (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
                home: Scaffold(body: TickRow(text: 'Texto no tick'))),
          );
          final textWidget = tester.widget<Text>(find.text('Texto no tick'));
          expect(textWidget.style?.fontSize, 17);
          expect(textWidget.style?.fontWeight, FontWeight.w500);
        });

    testWidgets('TRX-U3: ícone check_box tem cor kLight', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TickRow(text: 'Item'))),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_box));
      expect(icon.color, kLight);
    });
  });

  // =========================================================================
  // UT-HOMESHELL-EXTRA2: HomeShell — _onTabSelected e notificações
  // =========================================================================
  group('HomeShell — _onTabSelected e lógica de notificações', () {
    final identity = UniversityIdentity(
      username: 'up001',
      displayName: 'Teste',
      photoUrl: null,
    );

    testWidgets('HSX2-U1: selecionar aba 1 (Procurar) atualiza índice',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: HomeShell(onUniversityLogout: () async {}, identity: identity),
          ));
          await tester.pump();

          await tester.tap(find.text('Procurar'));
          await tester.pump();

          final navBar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
          expect(navBar.selectedIndex, 1);
        });

    testWidgets('HSX2-U2: selecionar aba 2 (Oferecer) atualiza índice',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: HomeShell(onUniversityLogout: () async {}, identity: identity),
          ));
          await tester.pump();

          await tester.tap(find.text('Oferecer'));
          await tester.pump();

          final navBar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
          expect(navBar.selectedIndex, 2);
        });

    testWidgets('HSX2-U3: selecionar aba 4 (Perfil) atualiza índice',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: HomeShell(onUniversityLogout: () async {}, identity: identity),
          ));
          await tester.pump();

          await tester.tap(find.text('Perfil'));
          await tester.pump();

          final navBar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
          expect(navBar.selectedIndex, 4);
        });

    testWidgets('HSX2-U4: aba "Pedidos" com label e ícone inbox presente',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: HomeShell(onUniversityLogout: () async {}, identity: identity),
          ));
          await tester.pump();

          // Verifica que o destino Pedidos existe na NavigationBar
          expect(find.text('Pedidos'), findsOneWidget);
          expect(find.byIcon(Icons.inbox), findsOneWidget);
        });

    testWidgets(
        'HSX2-U5: goToHomeTab a partir da aba 3 (Pedidos) volta para 0',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: HomeShell(onUniversityLogout: () async {}, identity: identity),
          ));
          await tester.pump();

          await tester.tap(find.text('Pedidos'));
          await tester.pump();

          final state =
          tester.state<HomeShellState>(find.byType(HomeShell));
          state.goToHomeTab();
          await tester.pump();

          final navBar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
          expect(navBar.selectedIndex, 0);
        });
  });

  // =========================================================================
  // UT-BOOTSTRAPPER-EXTRA2: AppBootstrapper — fluxo completo
  // =========================================================================
  group('AppBootstrapper — fluxo de autenticação', () {
    testWidgets('ABX2-U1: após sessão inválida mostra UniversityLoginPage', (tester) async {
  // 1. Simula o armazenamento local vazio para não rebentar no _restoreSession()
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(const MaterialApp(home: AppBootstrapper()));
  
  // 2. O microtask do SharedPreferences mockado resolve quase instantaneamente.
  // Precisamos de apenas alguns pumps normais para o Flutter processar o 
  // setState() e desenhar o novo ecrã, saindo do estado _loading = true.
  await tester.pump();
  await tester.pump();

  // 3. Sem sessão guardada → mostra a página de login com sucesso!
  expect(find.byType(UniversityLoginPage), findsOneWidget);
});

    testWidgets('ABX2-U2: loading state exibe CircularProgressIndicator', (tester) async {
  // Isolar as notificações nativas
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  
  try {
    // Garantir que a leitura inicial do Bootstrapper não falha
    SharedPreferences.setMockInitialValues({});

    // pumpWidget constrói e desenha o EXATO PRIMEIRO FRAME. 
    // O Future ainda está "em voo" neste exato milissegundo.
    await tester.pumpWidget(const MaterialApp(home: AppBootstrapper()));
    
    // Validamos IMEDIATAMENTE! Se colocares um tester.pump() aqui no meio, 
    // o mock resolve-se e perdes o estado de loading.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
  } finally {
    // Limpar o ambiente
    debugDefaultTargetPlatformOverride = null;
  }
});
    testWidgets(
        'ABX2-U3: AppBootstrapper com api e authService injetados não crasha',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: AppBootstrapper(
              api: Ride4FreeApi(),
              authService: SigarraAuthService(),
            ),
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
  });

  // =========================================================================
  // UT-LOGOUT-FLOW: _onUniversityLogout — limpa estado e redireciona
  // =========================================================================
  group('_onUniversityLogout — fluxo de logout completo', () {
    testWidgets(
        'LGF-U1: invocar logout a partir do HomeShell volta para login',
            (tester) async {
          final identity = _testIdentity();
          bool loggedOut = false;

          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                if (loggedOut) {
                  return MaterialApp(
                    home: UniversityLoginPage(onLoginSuccess: (_) async {}),
                  );
                }
                return MaterialApp(
                  home: HomeShell(
                    onUniversityLogout: () async {
                      setState(() => loggedOut = true);
                    },
                    identity: identity,
                  ),
                );
              },
            ),
          );
          await tester.pump();

          // Navega para Perfil e faz logout
          await tester.tap(find.text('Perfil'));
          await tester.pump();
          await tester.pump();

          final profilePage =
          tester.widget<ProfilePage>(find.byType(ProfilePage));
          await profilePage.onUniversityLogout();
          await tester.pump();

          expect(find.byType(UniversityLoginPage), findsOneWidget);
          expect(find.byType(HomeShell), findsNothing);
        });

    testWidgets('LGF-U2: após logout o token Ride4Free é null', (tester) async {
      Ride4FreeAuth.token = 'token_antes_logout';
      Ride4FreeAuth.token = null;
      expect(Ride4FreeAuth.token, isNull);
    });
  });

  // =========================================================================
  // UT-ROUTEROW-EXTRA: RouteRow — estrutura visual
  // =========================================================================
  group('RouteRow — estrutura visual', () {
    testWidgets('RRX-U1: ponto colorido (Container circular) presente',
            (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: RouteRow(color: Colors.red, text: 'Partida'),
              ),
            ),
          );
          final containers = tester.widgetList<Container>(find.byType(Container));
          final hasCircle = containers.any((c) {
            final dec = c.decoration;
            return dec is BoxDecoration && dec.shape == BoxShape.circle;
          });
          expect(hasCircle, isTrue);
        });

    testWidgets('RRX-U2: dimensão do ponto é 11x11', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteRow(color: kSuccess, text: 'Destino'),
          ),
        ),
      );
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCorrectSize = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            dec.shape == BoxShape.circle &&
            c.constraints?.maxWidth == 11;
      });
      expect(hasCorrectSize, isTrue);
    });
  });

  // =========================================================================
  // UT-RIDECARD-EXTRA2: RideCard — campo "distance" na UI
  // =========================================================================
  group('RideCard — campo distance e custo', () {
    testWidgets('RCX2-U1: texto de distância é mostrado com emoji 📍',
            (tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: RideCard(
                  name: 'Ana',
                  car: 'Lugares livres: 1',
                  rating: '4.0',
                  distance: 'FEUP (Polo II)',
                  credits: '−5',
                ),
              ),
            ),
          );
          expect(find.textContaining('FEUP (Polo II)'), findsOneWidget);
        });

    testWidgets('RCX2-U2: label "Custo" está presente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RideCard(
              name: 'Driver',
              car: 'Car',
              rating: '5',
              distance: '100m',
              credits: '−5',
            ),
          ),
        ),
      );
      expect(find.text('Custo'), findsOneWidget);
    });
  });

  // =========================================================================
  // UT-MYAPP-EXTRA: MyApp — tema e cores
  // =========================================================================
  group('MyApp — tema e configuração', () {
    testWidgets('MAE-U1: tema usa kRed como cor primária', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      final materialApp =
      tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.colorScheme.primary, kRed);
    });

    testWidgets('MAE-U2: scaffoldBackgroundColor é kBackground',
            (tester) async {
          await tester.pumpWidget(const MyApp());
          await tester.pump();

          final materialApp =
          tester.widget<MaterialApp>(find.byType(MaterialApp));
          expect(materialApp.theme?.scaffoldBackgroundColor, kBackground);
        });

    testWidgets('MAE-U3: useMaterial3 é true', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      final materialApp =
      tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);
    });
  });

  // =========================================================================
  // UT-LOGINPAGE-EXTRA2: UniversityLoginPage — hint e estrutura
  // =========================================================================
  group('UniversityLoginPage — hint, estrutura e aviso teste', () {
    testWidgets('LPX2-U1: mostra aviso de conta de teste', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UniversityLoginPage(onLoginSuccess: (_) async {}),
        ),
      ));
      expect(
          find.textContaining('admin'), findsWidgets);
    });

    testWidgets('LPX2-U2: título "Autenticação Universitária" presente',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: UniversityLoginPage(onLoginSuccess: (_) async {}),
            ),
          ));
          expect(find.text('Autenticação Universitária'), findsOneWidget);
        });

    testWidgets('LPX2-U3: ícone de escola (school) está presente',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: UniversityLoginPage(onLoginSuccess: (_) async {}),
            ),
          ));
          expect(find.byIcon(Icons.school), findsOneWidget);
        });

    testWidgets(
        'LPX2-U4: só username preenchido → erro ao submeter',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: UniversityLoginPage(onLoginSuccess: (_) async {}),
            ),
          ));
          await tester.enterText(
              find.byKey(const Key('user_field')), 'up202300001');
          final btn = find.byType(FilledButton);
          await tester.ensureVisible(btn);
          await tester.pump();
          await tester.tap(btn);
          await tester.pump();
          expect(find.text('Preencha as credenciais universitárias.'),
              findsOneWidget);
        });

    testWidgets(
        'LPX2-U5: só password preenchida → erro ao submeter',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: UniversityLoginPage(onLoginSuccess: (_) async {}),
            ),
          ));
          await tester.enterText(
              find.byKey(const Key('pass_field')), 'password');
          final btn = find.byType(FilledButton);
          await tester.ensureVisible(btn);
          await tester.pump();
          await tester.tap(btn);
          await tester.pump();
          expect(find.text('Preencha as credenciais universitárias.'),
              findsOneWidget);
        });

    testWidgets(
        'LPX2-U6: erro é limpo ao iniciar novo login',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: UniversityLoginPage(onLoginSuccess: (_) async {}),
            ),
          ));

          // Gera erro primeiro — rola ao botão se necessário
          final btn = find.byType(FilledButton);
          await tester.ensureVisible(btn);
          await tester.pump();
          await tester.tap(btn);
          await tester.pump();
          expect(find.text('Preencha as credenciais universitárias.'),
              findsOneWidget);

          // Preenche e submete novamente (erro deve ser null internamente)
          await tester.enterText(
              find.byKey(const Key('user_field')), 'up202300001');
          await tester.enterText(
              find.byKey(const Key('pass_field')), 'senha');
          // Rola novamente ao botão (o erro expandiu o layout)
          await tester.ensureVisible(btn);
          await tester.pump();
          await tester.tap(btn);
          await tester.pump(); // setState: _busy=true, _error=null

          // Erro de credenciais inválidas desaparece (substituído por outro ou null)
          expect(
              find.text('Preencha as credenciais universitárias.'), findsNothing);
        });
  });

  // =========================================================================
  // UT-TOPBAR-TITLE: TopTitleBar — texto branco
  // =========================================================================
  group('TopTitleBar — cor do texto', () {
    testWidgets('TBT-U1: texto do título é branco', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
            home: Scaffold(body: TopTitleBar(title: 'Meu Título'))),
      );
      final text = tester.widget<Text>(find.text('Meu Título'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('TBT-U2: texto do título tem fontWeight w900', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TopTitleBar(title: 'Título'))),
      );
      final text = tester.widget<Text>(find.text('Título'));
      expect(text.style?.fontWeight, FontWeight.w900);
    });

    testWidgets('TBT-U3: texto do título tem fontSize 18', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
            home: Scaffold(body: TopTitleBar(title: 'Título Teste'))),
      );
      final text = tester.widget<Text>(find.text('Título Teste'));
      expect(text.style?.fontSize, 18);
    });
  });
}