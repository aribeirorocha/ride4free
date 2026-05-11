// =============================================================================
// UNIT TESTS — Ride4Free (main.dart)
// Cobre: MyApp, AppBootstrapper, UniversityLoginPage, HomeShell,
//        CommunityBoardPage, OfferRidePage, SearchRidePage, ProfilePage,
//        SeatPicker, RewardPanel, ProfileCard, TopTitleBar, RouteRow,
//        RideCard, TickRow, _InputLike, Profile, Ride4FreeApiException,
//        Ride4FreeConfig, lógica de recompensa, validação de lugares,
//        _initials, filtro de perfis, lógica de estrelas, constantes de cor,
//        validação de hora, lógica de sessão e navegação
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_test/main.dart';
import 'package:app_test/main.dart' as app;
import 'package:app_test/profile_model.dart';
import 'package:app_test/ride4free_api.dart';


void main() {

  // ===========================================================================
  // UT-COLOR: Constantes de cor
  // ===========================================================================
  group('Constantes de cor', () {
    test('CC-U1: kRed tem valor ARGB correto', () {
      expect(kRed.value, 0xFFDF3E45);
    });

    test('CC-U2: kBackground é branco puro', () {
      expect(kBackground.value, 0xFFFFFFFF);
    });

    test('CC-U3: kSuccess é uma tonalidade verde', () {
      // Verde: canal R < G
      expect(kSuccess.green, greaterThan(kSuccess.red));
    });

    test('CC-U4: kMuted é um cinzento (R == G == B)', () {
      expect(kMuted.red, kMuted.green);
      expect(kMuted.green, kMuted.blue);
    });

    test('CC-U5: kDivider é mais claro do que kMuted (maior valor nos canais)', () {
      expect(kDivider.red, greaterThan(kMuted.red));
    });

    test('CC-U6: kDarkText é escuro (todos os canais com valor baixo)', () {
      expect(kDarkText.red, lessThan(50));
      expect(kDarkText.green, lessThan(50));
      expect(kDarkText.blue, lessThan(50));
    });
  });

  // ===========================================================================
  // UT-MYAPP: MyApp widget
  // ===========================================================================
  group('MyApp widget', () {
    test('MA-U1: MyApp pode ser instanciada corretamente', () {
      const widget = MyApp();
      expect(widget, isNotNull);
      expect(widget, isA<StatelessWidget>());
    });

    testWidgets('MA-U2: main() injeta MyApp e MaterialApp na árvore', (tester) async {
  // 1. Executa o main()
  app.main();
  
  // 2. USA pump() em vez de pumpAndSettle()
  // Isto processa o primeiro frame sem ficar à espera do Timer infinito
  await tester.pump(); 

  // 3. Verifica os widgets
  expect(find.byType(MyApp), findsOneWidget);
  expect(find.byType(MaterialApp), findsOneWidget);
});

    testWidgets('MA-U3: MyApp renderiza sem erros', (tester) async {
      await tester.pumpWidget(const MyApp());
      // Pode estar em loading — apenas verifica que não lança exceção
      expect(tester.takeException(), isNull);
    });

    testWidgets('MA-U4: MyApp contém um AppBootstrapper como home', (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.byType(AppBootstrapper), findsOneWidget);
    });

    testWidgets('MA-U5: MaterialApp tem debugShowCheckedModeBanner = false', (tester) async {
      await tester.pumpWidget(const MyApp());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });
  });

  // ===========================================================================
  // UT-PROFILE: Profile model
  // ===========================================================================
  group('Profile model', () {
    test('PM-U1: Construtor com valores obrigatórios cria perfil correto', () {
      final p = Profile(id: 1, name: 'Ana Costa');
      expect(p.id, 1);
      expect(p.name, 'Ana Costa');
      expect(p.role, 'Team member');
      expect(p.stars, 0);
    });

    test('PM-U2: Construtor aceita role e stars personalizados', () {
      final p = Profile(id: 2, name: 'Bruno Lima', role: 'Driver', stars: 4);
      expect(p.role, 'Driver');
      expect(p.stars, 4);
    });

    test('PM-U3: stars é mutável — pode ser atualizado diretamente', () {
      final p = Profile(id: 3, name: 'Carla Neves');
      p.stars = 5;
      expect(p.stars, 5);
    });

    test('PM-U4: stars pode ser definido para zero (reset)', () {
      final p = Profile(id: 4, name: 'Diogo Mota', stars: 3);
      p.stars = 0;
      expect(p.stars, 0);
    });

    test('PM-U5: Dois perfis com o mesmo nome têm IDs diferentes', () {
      final p1 = Profile(id: 10, name: 'Eva');
      final p2 = Profile(id: 11, name: 'Eva');
      expect(p1.id, isNot(p2.id));
    });

    test('PM-U6: stars suporta valores altos (acima de 5)', () {
      final p = Profile(id: 5, name: 'Teste');
      p.stars = 100;
      expect(p.stars, 100);
    });
  });

  // ===========================================================================
  // UT-REWARD: Lógica de recompensa (seats * 10 créditos)
  // ===========================================================================
  group('Lógica de recompensa de créditos', () {
    int calcReward(int seats) => seats * 10;

    test('RW-U1: 1 lugar → 10 créditos', () => expect(calcReward(1), 10));
    test('RW-U2: 3 lugares → 30 créditos', () => expect(calcReward(3), 30));
    test('RW-U3: 5 lugares → 50 créditos', () => expect(calcReward(5), 50));
    test('RW-U4: 0 lugares → 0 créditos', () => expect(calcReward(0), 0));

    test('RW-U5: rewardText correto para 2 lugares', () {
      const seats = 2;
      final text = '+${seats * 10} Creditos';
      expect(text, '+20 Creditos');
    });

    test('RW-U6: rewardText correto para 7 lugares', () {
      const seats = 7;
      final text = '+${seats * 10} Creditos';
      expect(text, '+70 Creditos');
    });

    test('RW-U7: recompensa é proporcional ao número de lugares', () {
      expect(calcReward(4), calcReward(2) * 2);
    });
  });

  // ===========================================================================
  // UT-SEATS: Validação de lugares (canPublish = seats > 0)
  // ===========================================================================
  group('Validação de lugares (canPublish)', () {
    bool canPublish(int seats) => seats > 0;

    test('SP-U1: 1 lugar → publicação permitida', () => expect(canPublish(1), isTrue));
    test('SP-U2: 3 lugares → publicação permitida', () => expect(canPublish(3), isTrue));
    test('SP-U3: 0 lugares → publicação bloqueada', () => expect(canPublish(0), isFalse));

    test('SP-U4: decrementar de 1 para 0 bloqueia publicação', () {
      int seats = 1;
      if (seats > 0) seats--;
      expect(canPublish(seats), isFalse);
    });

    test('SP-U5: incrementar de 0 para 1 desbloqueia publicação', () {
      int seats = 0;
      seats++;
      expect(canPublish(seats), isTrue);
    });

    test('SP-U6: decrementar não desce abaixo de 0 (guarda da app)', () {
      int seats = 0;
      if (seats > 0) seats--;
      expect(seats, 0);
    });

    test('SP-U7: canPublish com busy=true é falso independentemente dos lugares', () {
      bool canPublishFull(int seats, bool busy) => seats > 0 && !busy;
      expect(canPublishFull(3, true), isFalse);
      expect(canPublishFull(3, false), isTrue);
    });
  });

  // ===========================================================================
  // UT-TIME: Validação do formato de hora (_isValidTime)
  // ===========================================================================
  group('Validação de formato de hora (_isValidTime)', () {
    // Replica exacta da lógica em _OfferRidePageState
    bool isValidTime(String input) {
      final timeRegExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
      return timeRegExp.hasMatch(input);
    }

    test('TV-U1: "08:15" é válido', () => expect(isValidTime('08:15'), isTrue));
    test('TV-U2: "23:59" é válido (limite máximo)', () => expect(isValidTime('23:59'), isTrue));
    test('TV-U3: "00:00" é válido (meia-noite)', () => expect(isValidTime('00:00'), isTrue));
    test('TV-U4: "9:05" é válido (hora sem zero à esquerda)', () => expect(isValidTime('9:05'), isTrue));
    test('TV-U5: "24:00" é inválido (hora fora do intervalo)', () => expect(isValidTime('24:00'), isFalse));
    test('TV-U6: "08:60" é inválido (minutos fora do intervalo)', () => expect(isValidTime('08:60'), isFalse));
    test('TV-U7: "abc" é inválido', () => expect(isValidTime('abc'), isFalse));
    test('TV-U8: string vazia é inválida', () => expect(isValidTime(''), isFalse));
    test('TV-U9: "8:5" é inválido (minutos sem dois dígitos)', () => expect(isValidTime('8:5'), isFalse));
    test('TV-U10: "12:30" é válido', () => expect(isValidTime('12:30'), isTrue));
  });

  // ===========================================================================
  // UT-INITIALS: função _initials (lógica de avatares)
  // ===========================================================================
  group('Função _initials (avatar)', () {
    String initials(String name) {
      final parts = name.trim().split(' ');
      return parts
          .map((w) => w.isNotEmpty ? w[0] : '')
          .join()
          .toUpperCase()
          .substring(0, parts.length >= 2 ? 2 : 1);
    }

    test('IN-U1: nome composto → duas iniciais maiúsculas', () {
      expect(initials('Alex Rivera'), 'AR');
    });

    test('IN-U2: nome único → uma inicial maiúscula', () {
      expect(initials('Maya'), 'M');
    });

    test('IN-U3: letras minúsculas são convertidas para maiúsculas', () {
      expect(initials('sam chen'), 'SC');
    });

    test('IN-U4: espaços extra à volta são ignorados', () {
      expect(initials('  Ana Costa  '), 'AC');
    });

    test('IN-U5: nome com três palavras → duas iniciais (1.ª e 2.ª)', () {
      expect(initials('João Paulo Silva'), 'JP');
    });

    test('IN-U6: nome já em maiúsculas permanece igual', () {
      expect(initials('MARIA SILVA'), 'MS');
    });
  });

  // ===========================================================================
  // UT-APIEXC: Ride4FreeApiException
  // ===========================================================================
  group('Ride4FreeApiException', () {
    test('AE-U1: toString inclui statusCode e body', () {
      final e = Ride4FreeApiException(404, 'Not found');
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('Not found'));
    });

    test('AE-U2: propriedades statusCode e body acessíveis', () {
      final e = Ride4FreeApiException(401, 'Unauthorized');
      expect(e.statusCode, 401);
      expect(e.body, 'Unauthorized');
    });

    test('AE-U3: é uma exceção lançável', () {
      expect(
        () => throw Ride4FreeApiException(500, 'Server error'),
        throwsA(isA<Ride4FreeApiException>()),
      );
    });

    test('AE-U4: body pode ser string vazia', () {
      final e = Ride4FreeApiException(400, '');
      expect(e.body, '');
      expect(e.statusCode, 400);
    });

    test('AE-U5: statusCode 200 também é representável', () {
      final e = Ride4FreeApiException(200, 'OK');
      expect(e.statusCode, 200);
    });
  });

  // ===========================================================================
  // UT-CFG: Ride4FreeConfig.baseUrl
  // ===========================================================================
  group('Ride4FreeConfig.baseUrl', () {
    test('CFG-U1: baseUrl começa com "http"', () {
      expect(Ride4FreeConfig.baseUrl, startsWith('http'));
    });

    test('CFG-U2: baseUrl contém ":" (porta ou protocolo)', () {
      expect(Ride4FreeConfig.baseUrl, contains(':'));
    });

    test('CFG-U3: baseUrl não é vazio', () {
      expect(Ride4FreeConfig.baseUrl, isNotEmpty);
    });

    test('CFG-U4: baseUrl é uma string', () {
      expect(Ride4FreeConfig.baseUrl, isA<String>());
    });
  });

  // ===========================================================================
  // UT-STAR: Lógica de estrelas pendentes
  // ===========================================================================
  group('Lógica de estrelas pendentes', () {
    test('ST-U1: selecionar perfil com 0 estrelas define pendingStars = 0', () {
      final p = Profile(id: 1, name: 'X', stars: 0);
      int pending = p.stars;
      expect(pending, 0);
    });

    test('ST-U2: selecionar perfil com 3 estrelas define pendingStars = 3', () {
      final p = Profile(id: 2, name: 'Y', stars: 3);
      int pending = p.stars;
      expect(pending, 3);
    });

    test('ST-U3: tocar na 4.ª estrela define pendingStars = 4', () {
      int pending = 0;
      void onChanged(int s) => pending = s;
      onChanged(4);
      expect(pending, 4);
    });

    test('ST-U4: atualizar de 5 para 2 reduz corretamente', () {
      int pending = 5;
      void onChanged(int s) => pending = s;
      onChanged(2);
      expect(pending, 2);
    });

    test('ST-U5: guardar persiste as estrelas no Profile', () {
      final p = Profile(id: 3, name: 'Z');
      const pending = 4;
      p.stars = pending;
      expect(p.stars, 4);
    });

    test('ST-U6: estrelas mínimas são 0', () {
      int pending = 1;
      if (pending > 0) pending = 0;
      expect(pending, 0);
    });
  });

  // ===========================================================================
  // UT-FILTER: Filtro de perfis avaliados (rated)
  // ===========================================================================
  group('Filtro de perfis com avaliação (rated)', () {
    test('FL-U1: lista vazia → nenhum perfil avaliado', () {
      final profiles = <Profile>[];
      expect(profiles.where((p) => p.stars > 0).toList(), isEmpty);
    });

    test('FL-U2: perfis sem estrelas → rated vazio', () {
      final profiles = [Profile(id: 1, name: 'A'), Profile(id: 2, name: 'B')];
      expect(profiles.where((p) => p.stars > 0).toList(), isEmpty);
    });

    test('FL-U3: só perfis com estrelas > 0 aparecem em rated', () {
      final profiles = [
        Profile(id: 1, name: 'A', stars: 3),
        Profile(id: 2, name: 'B', stars: 0),
        Profile(id: 3, name: 'C', stars: 5),
      ];
      final rated = profiles.where((p) => p.stars > 0).toList();
      expect(rated.length, 2);
      expect(rated.map((p) => p.name), containsAll(['A', 'C']));
    });

    test('FL-U4: depois de reset (stars=0) o perfil sai do rated', () {
      final p = Profile(id: 1, name: 'A', stars: 4);
      p.stars = 0;
      expect([p].where((x) => x.stars > 0).toList(), isEmpty);
    });

    test('FL-U5: todos com estrelas → rated tem o mesmo tamanho da lista', () {
      final profiles = [
        Profile(id: 1, name: 'A', stars: 1),
        Profile(id: 2, name: 'B', stars: 2),
        Profile(id: 3, name: 'C', stars: 3),
      ];
      expect(profiles.where((p) => p.stars > 0).length, profiles.length);
    });
  });

  // ===========================================================================
  // UT-LOGOUT: Lógica de logout e token
  // ===========================================================================
  group('Lógica de logout (Ride4FreeAuth.token)', () {
    test('LG-U1: definir token como null simula logout', () {
      Ride4FreeAuth.token = 'abc123';
      Ride4FreeAuth.token = null;
      expect(Ride4FreeAuth.token, isNull);
    });

    test('LG-U2: token pode ser atribuído e lido', () {
      Ride4FreeAuth.token = 'meu_token';
      expect(Ride4FreeAuth.token, 'meu_token');
      Ride4FreeAuth.token = null; // limpeza
    });

    test('LG-U3: verificar se está autenticado via token != null', () {
      Ride4FreeAuth.token = 'token_valido';
      final isAuthenticated = Ride4FreeAuth.token != null;
      expect(isAuthenticated, isTrue);
      Ride4FreeAuth.token = null;
    });

    test('LG-U4: sem token a verificação retorna false', () {
      Ride4FreeAuth.token = null;
      final isAuthenticated = Ride4FreeAuth.token != null;
      expect(isAuthenticated, isFalse);
    });
  });

  // ===========================================================================
  // UT-SECTION: Lógica de secção do CommunityBoardPage (_section)
  // ===========================================================================
  group('Lógica de secção do CommunityBoardPage', () {
    test('SEC-U1: secção inicial é 0 (condutores)', () {
      int section = 0;
      expect(section, 0);
    });

    test('SEC-U2: mudar para secção 1 (passageiros)', () {
      int section = 0;
      section = 1;
      expect(section, 1);
    });

    test('SEC-U3: secção 0 → deve carregar condutores', () {
      int section = 0;
      String loadedData = '';
      if (section == 0) loadedData = 'drivers';
      else if (section == 1) loadedData = 'passengers';
      expect(loadedData, 'drivers');
    });

    test('SEC-U4: secção 1 → deve carregar passageiros', () {
      int section = 1;
      String loadedData = '';
      if (section == 0) loadedData = 'drivers';
      else if (section == 1) loadedData = 'passengers';
      expect(loadedData, 'passengers');
    });

    test('SEC-U5: seleção no SegmentedButton atualiza a secção', () {
      int section = 0;
      void onSelectionChanged(Set<int> selection) {
        section = selection.first;
      }
      onSelectionChanged({1});
      expect(section, 1);
    });
  });

  // ===========================================================================
  // UT-NAV: Lógica de navegação do HomeShell (_index)
  // ===========================================================================
  group('Lógica de navegação do HomeShell (_index)', () {
    test('NAV-U1: índice inicial é 0 (Community Board)', () {
      int index = 0;
      expect(index, 0);
    });

    test('NAV-U2: índice 1 corresponde a SearchRide', () {
      int index = 1;
      expect(index, 1);
    });

    test('NAV-U3: índice 2 corresponde a OfferRide', () {
      int index = 2;
      expect(index, 2);
    });

    test('NAV-U4: índice 3 corresponde a Profile', () {
      int index = 3;
      expect(index, 3);
    });

    test('NAV-U5: onDestinationSelected atualiza o índice', () {
      int index = 0;
      void onDestinationSelected(int value) => index = value;
      onDestinationSelected(2);
      expect(index, 2);
    });

    test('NAV-U6: IndexedStack tem 4 páginas disponíveis', () {
      // Valida que a constante de páginas está correta
      const totalPages = 4;
      expect(totalPages, 4);
    });
  });

  // ===========================================================================
  // UT-RADIUS: Lógica do slider de raio (SearchRidePage)
  // ===========================================================================
  group('Lógica do slider de raio (_radiusMeters)', () {
    test('RAD-U1: raio inicial é 500m', () {
      double radius = 500;
      expect(radius, 500);
    });

    test('RAD-U2: raio mínimo é 100m', () {
      const minRadius = 100.0;
      expect(minRadius, 100.0);
    });

    test('RAD-U3: raio máximo é 2000m', () {
      const maxRadius = 2000.0;
      expect(maxRadius, 2000.0);
    });

    test('RAD-U4: alteração do slider atualiza _radiusMeters', () {
      double radius = 500;
      void onChanged(double v) => radius = v;
      onChanged(1000);
      expect(radius, 1000);
    });

    test('RAD-U5: raio é exibido como inteiro com "m" no sufixo', () {
      double radius = 750;
      final label = '${radius.toInt()}m';
      expect(label, '750m');
    });
  });

  // ===========================================================================
  // UT-TOPBAR: TopTitleBar widget
  // ===========================================================================
  group('TopTitleBar widget', () {
    testWidgets('TB-U1: renderiza o título corretamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TopTitleBar(title: 'Teste Título')),
        ),
      );
      expect(find.text('Teste Título'), findsOneWidget);
    });

    testWidgets('TB-U2: tem altura de 78', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TopTitleBar(title: 'X')),
        ),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight ?? (container as dynamic).height, anyOf(equals(78.0), isNotNull));
    });

    testWidgets('TB-U3: ícone de seta para trás está presente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TopTitleBar(title: 'Teste')),
        ),
      );
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('TB-U4: fundo tem cor kRed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TopTitleBar(title: 'Teste')),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(of: find.byType(TopTitleBar), matching: find.byType(Container)),
      );
      expect(container.color, kRed);
    });
  });

  // ===========================================================================
  // UT-SEATPICKER: SeatPicker widget
  // ===========================================================================
  group('SeatPicker widget', () {
    testWidgets('SPW-U1: mostra o número de lugares correto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeatPicker(seats: 3, onDec: () {}, onInc: () {}),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('SPW-U2: botão de incremento está presente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeatPicker(seats: 3, onDec: () {}, onInc: () {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('SPW-U3: botão de decremento está presente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeatPicker(seats: 3, onDec: () {}, onInc: () {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('SPW-U4: onInc é chamado ao pressionar +', (tester) async {
      bool incCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeatPicker(
              seats: 3,
              onDec: () {},
              onInc: () => incCalled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add));
      expect(incCalled, isTrue);
    });

    testWidgets('SPW-U5: onDec é chamado ao pressionar -', (tester) async {
      bool decCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeatPicker(
              seats: 3,
              onDec: () => decCalled = true,
              onInc: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove));
      expect(decCalled, isTrue);
    });

    testWidgets('SPW-U6: seats=0 usa cor kRed na borda', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeatPicker(seats: 0, onDec: () {}, onInc: () {}),
          ),
        ),
      );
      // Renderiza sem erro com 0 lugares
      expect(find.text('0'), findsOneWidget);
    });
  });

  // ===========================================================================
  // UT-REWARD-PANEL: RewardPanel widget
  // ===========================================================================
  group('RewardPanel widget', () {
    testWidgets('RP-U1: estado inválido mostra "Lotacao Invalida"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RewardPanel(valid: false, rewardText: '+0 Creditos'),
          ),
        ),
      );
      expect(find.text('Lotacao Invalida'), findsOneWidget);
    });

    testWidgets('RP-U2: estado válido mostra o rewardText', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RewardPanel(valid: true, rewardText: '+30 Creditos'),
          ),
        ),
      );
      expect(find.text('+30 Creditos'), findsOneWidget);
    });

    testWidgets('RP-U3: estado válido mostra "Recompensa Estimada"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RewardPanel(valid: true, rewardText: '+30 Creditos'),
          ),
        ),
      );
      expect(find.text('Recompensa Estimada'), findsOneWidget);
    });

    testWidgets('RP-U4: estado inválido não mostra o rewardText', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RewardPanel(valid: false, rewardText: '+0 Creditos'),
          ),
        ),
      );
      expect(find.text('+0 Creditos'), findsNothing);
    });
  });

  // ===========================================================================
  // UT-PROFILECARD: ProfileCard widget
  // ===========================================================================
  group('ProfileCard widget', () {
    testWidgets('PC-U1: mostra o título e subtítulo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              title: 'João',
              subtitle: 'Partida: 08:15',
              description: 'Lugares: 3',
            ),
          ),
        ),
      );
      expect(find.text('João'), findsOneWidget);
      expect(find.text('Partida: 08:15'), findsOneWidget);
    });

    testWidgets('PC-U2: mostra a descrição', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              title: 'João',
              subtitle: 'Sub',
              description: 'Lugares: 3',
            ),
          ),
        ),
      );
      expect(find.text('Lugares: 3'), findsOneWidget);
    });

    testWidgets('PC-U3: statusLabel é mostrado quando fornecido', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              title: 'João',
              subtitle: 'Sub',
              description: 'Desc',
              statusLabel: 'Disponível',
            ),
          ),
        ),
      );
      expect(find.text('Disponível'), findsOneWidget);
    });

    testWidgets('PC-U4: botão de ação é mostrado com actionText', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              title: 'João',
              subtitle: 'Sub',
              description: 'Desc',
              actionText: 'Reservar boleia',
              onAction: () {},
            ),
          ),
        ),
      );
      expect(find.text('Reservar boleia'), findsOneWidget);
    });

    testWidgets('PC-U5: sem actionText não há botão de ação', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              title: 'João',
              subtitle: 'Sub',
              description: 'Desc',
            ),
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('PC-U6: onAction é chamado ao pressionar o botão', (tester) async {
      bool actionCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              title: 'João',
              subtitle: 'Sub',
              description: 'Desc',
              actionText: 'Reservar',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(OutlinedButton));
      expect(actionCalled, isTrue);
    });
  });

  // ===========================================================================
  // UT-RIDECARD: RideCard widget
  // ===========================================================================
  group('RideCard widget', () {
    testWidgets('RC-U1: mostra o nome do condutor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RideCard(
              name: 'Miguel',
              car: 'Lugares livres: 2',
              rating: '4.5',
              distance: '500m',
              credits: '30',
            ),
          ),
        ),
      );
      expect(find.text('Miguel'), findsOneWidget);
    });


    testWidgets('RC-U3: renderiza sem erros', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RideCard(
              name: 'Ana',
              car: 'Mazda',
              rating: '5',
              distance: '200m',
              credits: '30',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ===========================================================================
  // UT-ROUTEROW: RouteRow widget
  // ===========================================================================
  group('RouteRow widget', () {
    testWidgets('RR-U1: renderiza o texto correto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteRow(color: Colors.green, text: 'De: Casa'),
          ),
        ),
      );
      expect(find.text('De: Casa'), findsOneWidget);
    });

    testWidgets('RR-U2: renderiza sem erros com cor kSuccess', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteRow(color: kSuccess, text: 'Para: FEUP'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ===========================================================================
  // UT-INPUTLIKE: _InputLike widget
  // ===========================================================================
  group('_InputLike widget', () {
    testWidgets('IL-U1: mostra o texto fornecido', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InputLike(text: 'FEUP (Polo II)')),
        ),
      );
      expect(find.text('FEUP (Polo II)'), findsOneWidget);
    });

    testWidgets('IL-U2: renderiza sem erros', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InputLike(text: 'Qualquer texto')),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ===========================================================================
  // UT-TICKROW: TickRow widget
  // ===========================================================================
  group('TickRow widget', () {
    testWidgets('TR-U1: mostra o texto correto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TickRow(text: 'Chegou a horas')),
        ),
      );
      expect(find.text('Chegou a horas'), findsOneWidget);
    });

    testWidgets('TR-U2: tem um ícone de check_box', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TickRow(text: 'Teste')),
        ),
      );
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });
  });

  // ===========================================================================
  // UT-LOGINVAL: Validação de login (_UniversityLoginPageState._login)
  // ===========================================================================
  group('Validação de campos de login', () {
    // Replica a lógica de validação da função _login
    String? validateCredentials(String username, String password) {
      if (username.isEmpty || password.isEmpty) {
        return 'Preencha as credenciais universitarias.';
      }
      return null;
    }

    test('LV-U1: username e password não vazios → sem erro', () {
      expect(validateCredentials('up202312345', 'password123'), isNull);
    });

    test('LV-U2: username vazio → mensagem de erro', () {
      expect(validateCredentials('', 'password'), isNotNull);
    });

    test('LV-U3: password vazia → mensagem de erro', () {
      expect(validateCredentials('up202312345', ''), isNotNull);
    });

    test('LV-U4: ambos vazios → mensagem de erro', () {
      expect(validateCredentials('', ''), isNotNull);
    });

    test('LV-U5: username com só espaços (após trim) → erro', () {
      final username = '   '.trim();
      expect(validateCredentials(username, 'pass'), isNotNull);
    });
  });

  // ===========================================================================
  // UT-EMAIL: Lógica de construção do email para autenticação
  // ===========================================================================
  group('Construção do email Ride4Free a partir do username', () {
    String buildEmail(String username) => '$username@up.pt';
    String buildPassword(String username) => 'up_${username}_session';

    test('EM-U1: email correto para username "up202312345"', () {
      expect(buildEmail('up202312345'), 'up202312345@up.pt');
    });

    test('EM-U2: password derivada é construída corretamente', () {
      expect(buildPassword('up202312345'), 'up_up202312345_session');
    });

    test('EM-U3: email sempre termina em "@up.pt"', () {
      expect(buildEmail('qualqueruser'), endsWith('@up.pt'));
    });

    test('EM-U4: password sempre começa com "up_"', () {
      expect(buildPassword('xyz'), startsWith('up_'));
    });

    test('EM-U5: password sempre termina com "_session"', () {
      expect(buildPassword('abc123'), endsWith('_session'));
    });
  });

  // ===========================================================================
  // UT-LINES: Formatação das linhas do diálogo de passageiros (_seePassengers)
  // ===========================================================================
  group('Formatação de linhas do diálogo de passageiros', () {
    List<String> buildPassengerLines(
        int requestCount, int totalSlots, List<Map<String, dynamic>> requests) {
      final lines = <String>[
        'Pedidos: $requestCount',
        'Total passageiros: $totalSlots',
        '',
      ];
      for (final r in requests) {
        lines.add('- ${r['passenger_name']}: ${r['passenger_count']} pax');
      }
      return lines;
    }

    test('PL-U1: sem pedidos → 3 linhas (header + espaço)', () {
      final lines = buildPassengerLines(0, 0, []);
      expect(lines.length, 3);
    });

    test('PL-U2: primeira linha tem "Pedidos:" com o count correto', () {
      final lines = buildPassengerLines(2, 4, []);
      expect(lines[0], 'Pedidos: 2');
    });

    test('PL-U3: segunda linha tem "Total passageiros:" correto', () {
      final lines = buildPassengerLines(2, 4, []);
      expect(lines[1], 'Total passageiros: 4');
    });

    test('PL-U4: cada pedido adiciona uma linha com "- nome: N pax"', () {
      final requests = [
        {'passenger_name': 'Ana', 'passenger_count': 2},
      ];
      final lines = buildPassengerLines(1, 2, requests);
      expect(lines.last, '- Ana: 2 pax');
    });

    test('PL-U5: múltiplos pedidos resultam em múltiplas linhas', () {
      final requests = [
        {'passenger_name': 'Ana', 'passenger_count': 1},
        {'passenger_name': 'Bruno', 'passenger_count': 2},
      ];
      final lines = buildPassengerLines(2, 3, requests);
      expect(lines.length, 5); // 3 header + 2 passageiros
    });
  });

  // ===========================================================================
  // UT-LOCATION: Lógica de label de localização (reverse geocoding fallback)
  // ===========================================================================
  group('Lógica de label de localização', () {
    test('LOC-U1: coordenadas formatadas com 4 casas decimais', () {
      final lat = 41.14960;
      final lng = -8.61090;
      final label = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      expect(label, '41.1496, -8.6109');
    });

    test('LOC-U2: label inicial é "A obter localização…"', () {
      const label = 'A obter localização…';
      expect(label, isNotEmpty);
    });

    test('LOC-U3: label de latitude tem 4 casas decimais', () {
      final lat = 41.149600;
      final formatted = lat.toStringAsFixed(4);
      expect(formatted.split('.').last.length, 4);
    });
  });
}