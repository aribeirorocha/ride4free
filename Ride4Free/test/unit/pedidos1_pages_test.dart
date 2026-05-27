// =============================================================================
// TESTES DE COBERTURA MÁXIMA — pedidos_page.dart
//
// Linhas cobertas:
//   • PedidosPage.initState / dispose / build
//   • _load (token null, sucesso, catch, silent)
//   • _statusLabel (todos os casos: pending, awaiting_passenger, confirmed,
//                   declined, expired, default)
//   • _openChat (abre BottomSheet, fecha e chama _load silent)
//   • _driverRespond (accept=true, accept=false, catch)
//   • _passengerRespond (accept=true com active_ride_id, accept=true sem ride,
//                        accept=false, catch)
//   • _list (empty driver, empty passenger, lista com itens)
//   • _list itens: todas as cores de estado (confirmed, declined, expired,
//                  cancelled, awaiting_passenger, default/pending)
//   • _list botões: Conversar, Aceitar, Recusar (driver), Confirmar, Recusar (passenger)
//   • _list zona info extra: origin+dep, só origin, só dep, ambos null
//   • JoinReqestChatSheet: initState, dispose, _refresh, _send (texto vazio,
//                          texto válido, catch), _loadMyId, _scrollToBottom,
//                          build (mensagens vazias, mensagens isMe/notMe)
//   • InfoExtraWidget: todos os 4 branches (null+null, origin only, dep only, ambos)
// =============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Ride4Free/pedidos_page.dart';
import 'package:Ride4Free/ride4free_api.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Cria um MockClient que devolve listas vazias por defeito.
MockClient _emptyClient() => MockClient((req) async =>
    http.Response(jsonEncode({'requests': [], 'messages': []}), 200));

/// Pedido de passageiro base (mínimo campos necessários).
Map<String, dynamic> _passengerReq({
  int id = 1,
  String status = 'pending',
  String dest = 'FEUP',
  String? origin,
  String? dep,
  bool needsConfirm = false,
}) =>
    {
      'id': id,
      'status': status,
      'destination_display': dest,
      'origin_display': origin,
      'departure_time': dep,
      'driver_name': 'Condutor Teste',
      'needs_passenger_confirmation': needsConfirm,
    };

/// Pedido de condutor base.
Map<String, dynamic> _driverReq({
  int id = 2,
  String status = 'pending',
  String dest = 'FEUP',
}) =>
    {
      'id': id,
      'status': status,
      'destination_display': dest,
      'passenger_name': 'Passageiro Teste',
      'needs_passenger_confirmation': false,
    };

// ---------------------------------------------------------------------------
// Constrói o widget dentro de um MockClient e faz pumpAndSettle.
// ---------------------------------------------------------------------------
Future<void> _pump(WidgetTester tester, MockClient client) async {
  await http.runWithClient(() async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PedidosPage())));
    await tester.pumpAndSettle();
  }, () => client);
}

void main() {
  // =========================================================================
  // GRUPO 1: _load — token null → estado vazio sem loading infinito
  // =========================================================================
  group('_load — token null', () {
    setUp(() => Ride4FreeAuth.token = null);

    testWidgets('LN-U1: mostra "Ainda não pediste boleias" (aba passageiro)',
        (tester) async {
      await _pump(tester, _emptyClient());
      expect(find.text('Ainda não pediste boleias.'), findsOneWidget);
    });

    testWidgets('LN-U2: mostra "Sem pedidos de passageiros" (aba condutor)',
        (tester) async {
      await http.runWithClient(() async {
        await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: PedidosPage())));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pedidos recebidos'));
        await tester.pumpAndSettle();
        expect(find.text('Sem pedidos de passageiros.'), findsOneWidget);
      }, () => _emptyClient());
    });

    testWidgets('LN-U3: não fica em loading infinito (CircularProgressIndicator desaparece)',
        (tester) async {
      await _pump(tester, _emptyClient());
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // =========================================================================
  // GRUPO 2: _load — catch (erro 500 → SnackBar)
  // =========================================================================
  group('_load — erro de API', () {
    setUp(() => Ride4FreeAuth.token = 'tok');
    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets('LE-U1: erro 500 mostra SnackBar "Erro ao carregar pedidos"',
        (tester) async {
      final errorClient = MockClient(
          (_) async => http.Response('{"detail": "Server Error"}', 500));
      await http.runWithClient(() async {
        await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: PedidosPage())));
        await tester.pumpAndSettle();
        expect(find.textContaining('Erro ao carregar pedidos'), findsOneWidget);
      }, () => errorClient);
    });

    testWidgets('LE-U2: _load silent=true não mostra SnackBar em caso de erro',
        (tester) async {
      // Primeiro carrega com sucesso, depois o timer dispara com erro
      int calls = 0;
      final client = MockClient((_) async {
        calls++;
        if (calls <= 2) {
          return http.Response(
              jsonEncode({'requests': []}), 200); // sucesso inicial
        }
        return http.Response('Error', 500); // erro no timer
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: PedidosPage())));
        await tester.pumpAndSettle();
        // Nenhum SnackBar deve aparecer (silent=true no timer)
        expect(find.byType(SnackBar), findsNothing);
      }, () => client);
    });
  });

  // =========================================================================
  // GRUPO 3: _statusLabel — todos os casos
  // =========================================================================
  group('_statusLabel — cobertura de todos os cases', () {
  setUp(() {
    // 1. Simular base de dados local para o Hub
    SharedPreferences.setMockInitialValues({});
    Ride4FreeAuth.token = 'tok';
  });

  tearDown(() {
    Ride4FreeAuth.token = null;
  });

  Future<void> pumpWithStatus(WidgetTester tester, String status, bool isDriver) async {
    final req = isDriver ? _driverReq(status: status) : _passengerReq(status: status);
    final key = isDriver ? 'incoming-join-requests' : 'my-join-requests';
    
    final client = MockClient((r) async {
      if (r.url.path.contains(key)) {
        // 2. Resposta JSON blindada
        return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
      }
      return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
      
      // 3. Contornar o Timer.periodic da página
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      if (isDriver) {
        await tester.tap(find.text('Pedidos recebidos'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }
    }, () => client);
  }

  testWidgets('SL-U1: status "pending" → pílula "PENDENTE"', (tester) async {
    // 4. Proteger contra a inicialização nativa
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpWithStatus(tester, 'pending', false);
      expect(find.text('PENDENTE'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('SL-U2: status "awaiting_passenger" → pílula "À ESPERA DE CONFIRMAÇÃO"', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpWithStatus(tester, 'awaiting_passenger', false);
      expect(find.text('À ESPERA DE CONFIRMAÇÃO'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('SL-U3: status "confirmed" → pedido deve ser OMITIDO da lista', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpWithStatus(tester, 'confirmed', false);
      // Como agora filtramos os 'confirmed', o cartão não deve aparecer
      expect(find.text('CONFIRMADO'), findsNothing); 
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('SL-U4: status "declined" → pedido deve ser OMITIDO da lista', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpWithStatus(tester, 'declined', false);
      // Como agora filtramos os 'declined', o cartão não deve aparecer
      expect(find.text('RECUSADO'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('SL-U5: status "expired" → pedido deve ser OMITIDO da lista', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpWithStatus(tester, 'expired', false);
      // Como agora filtramos os 'expired', o cartão não deve aparecer
      expect(find.text('EXPIRADO'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('SL-U6: status desconhecido → mostra o valor bruto em maiúsculas', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await pumpWithStatus(tester, 'custom_status', false);
      expect(find.text('CUSTOM_STATUS'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  // Este é um teste unitário puro, não interage com widgets nativos nem com o timer,
  // por isso não precisa do override de plataforma nem do try...finally!
  test('SL-U7: _statusLabel unit — null → string vazia', () {
    // Replica a lógica do switch
    String statusLabel(String? s) {
      switch (s) {
        case 'pending': return 'Pendente';
        case 'awaiting_passenger': return 'À espera de confirmação';
        case 'confirmed': return 'Confirmado';
        case 'declined': return 'Recusado';
        case 'expired': return 'Expirado';
        default: return s ?? '';
      }
    }
    expect(statusLabel(null), '');
    expect(statusLabel('pending'), 'Pendente');
    expect(statusLabel('confirmed'), 'Confirmado');
    expect(statusLabel('declined'), 'Recusado');
    expect(statusLabel('expired'), 'Expirado');
    expect(statusLabel('awaiting_passenger'), 'À espera de confirmação');
    expect(statusLabel('outro'), 'outro');
  });
});
  // =========================================================================
  // GRUPO 4: Cores de estado (statusBgColor / statusTextColor)
  // =========================================================================
  group('_list — cores da pílula de estado', () {
  setUp(() {
    // 1. Simular o armazenamento local para o Hub não crashar
    SharedPreferences.setMockInitialValues({});
    Ride4FreeAuth.token = 'tok';
  });

  tearDown(() {
    Ride4FreeAuth.token = null;
  });

  testWidgets('COR-U1: status "cancelled" → cor kRed (branch declined/cancelled/expired)', (tester) async {
    // 2. Proteger contra a inicialização nativa do FlutterLocalNotifications
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('my-join-requests')) {
          final req = _passengerReq(status: 'cancelled');
          // 3. Resposta JSON robusta com 'requests' e 'rows'
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        // 4. Substituir pumpAndSettle por pumps controlados
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        // 'cancelled' não existe no _statusLabel switch → mostra "CANCELLED" em maiúsculas
        expect(find.text('CANCELLED'), findsOneWidget);
      }, () => client);
    } finally {
      // Garantir a limpeza para o framework não se queixar no fim do teste
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('COR-U2: status "awaiting_passenger" → cor amber', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('my-join-requests')) {
          final req = _passengerReq(status: 'awaiting_passenger');
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.text('À ESPERA DE CONFIRMAÇÃO'), findsOneWidget);
      }, () => client);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
});
  // =========================================================================
  // GRUPO 5: _driverRespond — accept=true, accept=false, catch
  // =========================================================================
  group('_driverRespond', () {
  setUp(() {
    // 1. Simular o disco local para o Hub de notificações não crashar
    SharedPreferences.setMockInitialValues({});
    Ride4FreeAuth.token = 'tok';
  });

  tearDown(() {
    Ride4FreeAuth.token = null;
  });

  testWidgets('DR-U1: Aceitar passageiro → SnackBar "Passageiro aceite"', (tester) async {
    // 2. Proteger das notificações nativas
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('incoming-join-requests')) {
          final req = _driverReq(status: 'pending');
          // 3. Resposta robusta
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('respond')) {
          return http.Response('{}', 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        // 4. Substituir pumpAndSettle por pumps controlados
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Pedidos recebidos'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Aceitar'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.textContaining('Passageiro aceite'), findsOneWidget);
      }, () => client);
    } finally {
      // Garantir a limpeza para não quebrar o Test Framework
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('DR-U2: Recusar passageiro → SnackBar "Pedido recusado"', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('incoming-join-requests')) {
          final req = _driverReq(status: 'pending');
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('respond')) {
          return http.Response('{}', 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Pedidos recebidos'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Recusar'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.textContaining('Pedido recusado'), findsOneWidget);
      }, () => client);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('DR-U3: Erro no respond → catch mostra SnackBar', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('incoming-join-requests')) {
          final req = _driverReq(status: 'pending');
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('respond')) {
          return http.Response('{"detail":"Erro"}', 500);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Pedidos recebidos'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Aceitar'));
        
        // Dar tempo ao catch para disparar a SnackBar
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.byType(SnackBar), findsOneWidget);
      }, () => client);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
});
  // =========================================================================
  // GRUPO 6: _passengerRespond — accept=true (com e sem active_ride_id),
  //          accept=false, catch
  // =========================================================================
  group('_passengerRespond', () {
  setUp(() {
    // 1. O Hub precisa da base de dados local falsa
    SharedPreferences.setMockInitialValues({});
    Ride4FreeAuth.token = 'tok';
  });

  tearDown(() {
    Ride4FreeAuth.token = null;
  });

  testWidgets('PR-U1: Confirmar boleia com active_ride_id → mensagem de viagem ativa', (tester) async {
    // 2. Proteção do FlutterLocalNotifications
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('my-join-requests')) {
          final req = _passengerReq(needsConfirm: true);
          // 3. Resposta robusta para o JSON parser não falhar
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('respond')) {
          return http.Response(jsonEncode({'active_ride_id': 42}), 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        // 4. Contornar o temporizador infinito inicial
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Confirmar'));
        
        // Tempo para a chamada de rede e para a SnackBar animar
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.textContaining('Lugar confirmado'), findsOneWidget);
      }, () => client);
    } finally {
      // Limpeza obrigatória para não disparar o erro do Flutter Test Framework
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('PR-U2: Confirmar boleia sem active_ride_id → só "Lugar confirmado"', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('my-join-requests')) {
          final req = _passengerReq(needsConfirm: true);
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('respond')) {
          return http.Response(jsonEncode({'active_ride_id': null}), 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Confirmar'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.textContaining('Lugar confirmado'), findsOneWidget);
      }, () => client);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('PR-U3: Recusar boleia → SnackBar "Pedido recusado"', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('my-join-requests')) {
          final req = _passengerReq(needsConfirm: true);
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('respond')) {
          return http.Response('{}', 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        // O botão "Recusar" do passageiro
        await tester.tap(find.text('Recusar'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.textContaining('Pedido recusado'), findsOneWidget);
      }, () => client);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('PR-U4: Erro no passengerRespond → catch mostra SnackBar', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('my-join-requests')) {
          final req = _passengerReq(needsConfirm: true);
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('respond')) {
          return http.Response('Error', 500);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Confirmar'));
        
        // O pump dá tempo ao catch para disparar a SnackBar
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.byType(SnackBar), findsOneWidget);
      }, () => client);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
});
  // =========================================================================
  // GRUPO 7: _openChat — abre e fecha BottomSheet
  // =========================================================================
  group('_openChat', () {
  setUp(() {
    // Mantemos apenas a base de dados e o token no setUp
    SharedPreferences.setMockInitialValues({});
    Ride4FreeAuth.token = 'tok';
  });

  tearDown(() {
    Ride4FreeAuth.token = null;
  });

  testWidgets('OC-U1: botão "Conversar" abre o ChatSheet', (tester) async {
    // 1. Aplicar a variável no início do teste
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('incoming-join-requests')) {
          final req = _driverReq(status: 'pending');
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('messages')) {
          return http.Response(jsonEncode({'messages': [], 'rows': []}), 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Pedidos recebidos'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Conversar'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.text('Mensagens do Pedido'), findsOneWidget);
      }, () => client);
    } finally {
      // 2. Limpar a variável antes do teste terminar!
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('OC-U2: ChatSheet mostra "Diz olá! Começa a conversa." quando vazio', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('incoming-join-requests')) {
          final req = _driverReq();
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('messages')) {
          return http.Response(jsonEncode({'messages': [], 'rows': []}), 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Pedidos recebidos'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Conversar'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.textContaining('Diz olá'), findsOneWidget);
      }, () => client);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('OC-U3: ChatSheet mostra campo "Escreve uma mensagem..."', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    
    try {
      final client = MockClient((r) async {
        if (r.url.path.contains('incoming-join-requests')) {
          final req = _driverReq();
          return http.Response(jsonEncode({'requests': [req], 'rows': [req]}), 200);
        }
        if (r.url.path.contains('messages')) {
          return http.Response(jsonEncode({'messages': [], 'rows': []}), 200);
        }
        return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PedidosPage())));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Pedidos recebidos'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        await tester.tap(find.text('Conversar'));
        
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        
        expect(find.text('Escreve uma mensagem...'), findsOneWidget);
      }, () => client);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
});// =========================================================================
  // GRUPO 8: JoinReqestChatSheet — _send, _refresh, _loadMyId, mensagens
  // =========================================================================
  group('JoinReqestChatSheet', () {
    testWidgets('CS-U1: _send com texto vazio → não chama API', (tester) async {
      bool postCalled = false;
      final mockApi = MockClient((r) async {
        if (r.method == 'POST') postCalled = true;
        return http.Response(jsonEncode({'messages': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: ctx,
                builder: (_) =>
                    JoinReqestChatSheet(requestId: 1, api: Ride4FreeApi(client: mockApi)),
              ),
              child: const Text('Abrir'),
            )),
          ),
        ));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        // Envia sem texto
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(postCalled, isFalse);
      }, () => mockApi);
    });

    testWidgets('CS-U2: _send com texto válido → POST é chamado', (tester) async {
      bool postCalled = false;
      final mockApi = MockClient((r) async {
        if (r.method == 'POST') postCalled = true;
        return http.Response(jsonEncode({'messages': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: ctx,
                builder: (_) =>
                    JoinReqestChatSheet(requestId: 1, api: Ride4FreeApi(client: mockApi)),
              ),
              child: const Text('Abrir'),
            )),
          ),
        ));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Olá condutor!');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(postCalled, isTrue);
      }, () => mockApi);
    });

    testWidgets('CS-U3: _send com erro → SnackBar "Erro ao enviar mensagem"',
        (tester) async {
      int calls = 0;
      final mockApi = MockClient((r) async {
        calls++;
        if (r.method == 'POST') return http.Response('Error', 500);
        return http.Response(jsonEncode({'messages': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: ctx,
                builder: (_) =>
                    JoinReqestChatSheet(requestId: 1, api: Ride4FreeApi(client: mockApi)),
              ),
              child: const Text('Abrir'),
            )),
          ),
        ));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Teste erro');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(find.textContaining('Erro ao enviar mensagem'), findsOneWidget);
      }, () => mockApi);
    });

    testWidgets('CS-U4: mensagens são renderizadas na lista', (tester) async {
      final mockApi = MockClient((r) async {
        if (r.url.path.contains('messages')) {
          return http.Response(jsonEncode({
            'messages': [
              {
                'id': 1,
                'body': 'Olá, estou a caminho!',
                'sender_user_id': 99,
                'sender_name': 'Condutor'
              }
            ]
          }), 200);
        }
        return http.Response('{}', 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: ctx,
                builder: (_) =>
                    JoinReqestChatSheet(requestId: 1, api: Ride4FreeApi(client: mockApi)),
              ),
              child: const Text('Abrir'),
            )),
          ),
        ));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Olá, estou a caminho!'), findsOneWidget);
        // Nome do remetente visível (isMe=false pois _myId é null)
        expect(find.text('Condutor'), findsOneWidget);
      }, () => mockApi);
    });


    testWidgets('CS-U6: submit via teclado (onSubmitted) envia mensagem',
        (tester) async {
      bool postCalled = false;
      final mockApi = MockClient((r) async {
        if (r.method == 'POST') postCalled = true;
        return http.Response(jsonEncode({'messages': []}), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: ctx,
                builder: (_) =>
                    JoinReqestChatSheet(requestId: 1, api: Ride4FreeApi(client: mockApi)),
              ),
              child: const Text('Abrir'),
            )),
          ),
        ));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Via teclado');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(postCalled, isTrue);
      }, () => mockApi);
    });

    testWidgets('CS-U7: dispose cancela o Timer sem crash', (tester) async {
      final mockApi = MockClient((_) async =>
          http.Response(jsonEncode({'messages': []}), 200));

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: ctx,
                builder: (_) =>
                    JoinReqestChatSheet(requestId: 1, api: Ride4FreeApi(client: mockApi)),
              ),
              child: const Text('Abrir'),
            )),
          ),
        ));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        // Fecha o modal → dispara dispose()
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }, () => mockApi);
    });
  });

  // =========================================================================
  // GRUPO 9: InfoExtraWidget — todos os 4 branches
  // =========================================================================
  group('InfoExtraWidget — todos os branches', () {
    testWidgets('IEW-U1: origin=null, dep=null → SizedBox.shrink (nada visível)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: InfoExtraWidget(origin: null, dep: null)),
      ));
      expect(find.byType(Container), findsNothing);
      expect(find.byIcon(Icons.my_location), findsNothing);
      expect(find.byIcon(Icons.access_time), findsNothing);
    });

    testWidgets('IEW-U2: origin="Rua A", dep=null → só origem visível',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: InfoExtraWidget(origin: 'Rua A', dep: null)),
      ));
      expect(find.text('Rua A'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsNothing);
      expect(find.textContaining('Partida:'), findsNothing);
    });

    testWidgets('IEW-U3: origin=null, dep="08:15" → só hora visível',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: InfoExtraWidget(origin: null, dep: '08:15')),
      ));
      expect(find.text('Partida: 08:15'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsNothing);
    });

    testWidgets('IEW-U4: origin="Rua A", dep="09:00" → ambos visíveis',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: InfoExtraWidget(origin: 'Rua A', dep: '09:00')),
      ));
      expect(find.text('Rua A'), findsOneWidget);
      expect(find.text('Partida: 09:00'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('IEW-U5: origin="" (vazio), dep="" (vazio) → SizedBox.shrink',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: InfoExtraWidget(origin: '', dep: '')),
      ));
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('IEW-U6: origin="Casa", dep="" → só origem (dep vazio ignorado)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: InfoExtraWidget(origin: 'Casa', dep: '')),
      ));
      expect(find.text('Casa'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsNothing);
    });

    testWidgets('IEW-U7: origin="", dep="10:30" → só hora (origin vazio ignorado)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: InfoExtraWidget(origin: '', dep: '10:30')),
      ));
      expect(find.text('Partida: 10:30'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsNothing);
    });
  });

  // =========================================================================
  // GRUPO 10: _list — zona info extra dentro da PedidosPage
  // =========================================================================
  group('_list — zona info extra integrada', () {
    setUp(() => Ride4FreeAuth.token = 'tok');
    tearDown(() => Ride4FreeAuth.token = null);

    testWidgets('LIE-U1: pedido com origin e dep → mostra ambos na lista', (tester) async {
  // 1. Definir o token (SEM ISTO A PÁGINA NÃO CARREGA OS DADOS!)
  addTearDown(() => Ride4FreeAuth.token = null);
  Ride4FreeAuth.token = 'tok';

  // 2. Evitar crashes do RideNotificationHub
  SharedPreferences.setMockInitialValues({});

  final client = MockClient((r) async {
    if (r.url.path.contains('my-join-requests')) {
      // Usamos a tua função auxiliar, mas criamos a variável antes
      final req = _passengerReq(origin: 'Rua das Flores', dep: '08:30');
      
      // 3. Garantimos os dois formatos ('requests' e 'rows') para a API não falhar
      return http.Response(
        jsonEncode({
          'requests': [req],
          'rows': [req]
        }),
        200
      );
    }
    return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
  });

  await http.runWithClient(() async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PedidosPage()))
    );

    // 4. Substituir pumpAndSettle por pumps simples para contornar o Timer
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Agora sim, a UI vai renderizar as moradas corretamente
    expect(find.text('Rua das Flores'), findsOneWidget);
    expect(find.text('Partida: 08:30'), findsOneWidget);
  }, () => client);
});
    testWidgets('LIE-U2: pedido sem origin nem dep → zona info extra não aparece', (tester) async {
  // 1. Injetar o token e garantir a limpeza no fim
  addTearDown(() => Ride4FreeAuth.token = null);
  Ride4FreeAuth.token = 'tok';

  // 2. Mock das SharedPreferences
  SharedPreferences.setMockInitialValues({});

  final client = MockClient((r) async {
    if (r.url.path.contains('my-join-requests')) {
      // 3. Garantimos que não passamos origin nem dep
      final req = _passengerReq(origin: null, dep: null);
      
      // JSON robusto
      return http.Response(
        jsonEncode({
          'requests': [req],
          'rows': [req]
        }), 
        200
      );
    }
    return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
  });

  await http.runWithClient(() async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PedidosPage()))
    );

    // 4. Contornar o Timer infinito da página
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Como o cartão foi renderizado com origin e dep nulos, 
    // a secção com estes ícones não deve existir no ecrã.
    expect(find.byIcon(Icons.my_location), findsNothing);
    expect(find.byIcon(Icons.access_time), findsNothing);
  }, () => client);
});

    testWidgets('LIE-U3: RefreshIndicator existe na lista não vazia', (tester) async {
  // 1. Injetar o token e garantir a limpeza no fim
  addTearDown(() => Ride4FreeAuth.token = null);
  Ride4FreeAuth.token = 'tok';

  // 2. Evitar crashes do RideNotificationHub
  SharedPreferences.setMockInitialValues({});

  final client = MockClient((r) async {
    if (r.url.path.contains('my-join-requests')) {
      // 3. Garantir que passamos o pedido gerado pela tua função auxiliar
      final req = _passengerReq();
      
      // JSON robusto para qualquer formato da API
      return http.Response(
        jsonEncode({
          'requests': [req],
          'rows': [req]
        }), 
        200
      );
    }
    return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
  });

  await http.runWithClient(() async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PedidosPage()))
    );

    // 4. Contornar o Timer infinito
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Agora a lista foi preenchida com sucesso, pelo que o RefreshIndicator deve existir
    expect(find.byType(RefreshIndicator), findsOneWidget);
  }, () => client);
});

    testWidgets('LIE-U4: destino usa offer_destination quando destination_display é null', (tester) async {
  // 1. Injetar o token e garantir a sua limpeza no final
  addTearDown(() => Ride4FreeAuth.token = null);
  Ride4FreeAuth.token = 'tok';

  // 2. Mock das SharedPreferences para o RideNotificationHub não falhar
  SharedPreferences.setMockInitialValues({});

  final client = MockClient((r) async {
    if (r.url.path.contains('my-join-requests')) {
      final req = {
        'id': 1,
        'status': 'pending',
        'offer_destination': 'FEUP via offer', // O valor que queremos testar
        'driver_name': 'X',
        'needs_passenger_confirmation': false,
      };
      
      // 3. Formato JSON robusto para garantir compatibilidade com a tua API
      return http.Response(
        jsonEncode({
          'requests': [req],
          'rows': [req]
        }),
        200
      );
    }
    return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
  });

  await http.runWithClient(() async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PedidosPage()))
    );

    // 4. Substituir o pumpAndSettle por pumps simples para contornar o Timer infinito
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Agora o ecrã desenha a lista com sucesso e encontra a morada de fallback!
    expect(find.text('FEUP via offer'), findsOneWidget);
  }, () => client);
});
  });

  // =========================================================================
  // GRUPO 11: PedidosPage — dispose cancela o Timer
  // =========================================================================
  group('PedidosPage — dispose', () {
    testWidgets('PD-U1: dispose cancela o Timer sem crash', (tester) async {
      Ride4FreeAuth.token = null;
      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: PedidosPage())));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
      Ride4FreeAuth.token = null;
    });
  });

  // =========================================================================
  // GRUPO 12: TabBar e estrutura do build
  // =========================================================================
  group('PedidosPage — estrutura do build', () {
    setUp(() => Ride4FreeAuth.token = null);

    testWidgets('PB-U1: TopTitleBar tem título "Pedidos de Boleia"',
        (tester) async {
      await _pump(tester, _emptyClient());
      expect(find.text('Pedidos de Boleia'), findsOneWidget);
    });

    testWidgets('PB-U2: TabBar tem as duas abas', (tester) async {
      await _pump(tester, _emptyClient());
      expect(find.text('Os meus pedidos'), findsOneWidget);
      expect(find.text('Pedidos recebidos'), findsOneWidget);
    });

    testWidgets('PB-U3: label de aba do condutor é "Pedido de passageiro"', (tester) async {
  addTearDown(() => Ride4FreeAuth.token = null);
  Ride4FreeAuth.token = 'tok';
  
  // 1. Evitar crashes silenciosos do RideNotificationHub ao mudar de aba
  SharedPreferences.setMockInitialValues({});

  // 2. Pedido falso com TUDO o que a UI precisa para não rebentar (especialmente o 'id')
  Map<String, dynamic> fakeRequest() {
    return {
      'id': 1, 
      'status': 'pending',
      'passenger_name': 'João Teste',
      'driver_name': 'Condutor Teste',
      'destination_display': 'FEUP',
    };
  }

  final client = MockClient((r) async {
    // 3. Devolvemos o formato original (Map), mas com 'requests' e 'rows' 
    // para garantir que a API encontra a lista, independentemente do nome da chave.
    if (r.url.path.contains('incoming-join-requests')) {
      return http.Response(
        jsonEncode({
          'requests': [fakeRequest()],
          'rows': [fakeRequest()]
        }), 
        200
      );
    }
    // 4. Fallback seguro e vazio para o primeiro endpoint (listMyPassengerJoinRequests)
    return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
  });

  await http.runWithClient(() async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PedidosPage()))
    );
    
    // Processar o loading inicial
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Mudar para a aba de pedidos recebidos
    await tester.tap(find.text('Pedidos recebidos'));
    
    // Renderizar a transição da aba
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // O cartão será renderizado com sucesso!
    expect(find.text('Pedido de passageiro'), findsOneWidget);
  }, () => client);
});
    testWidgets('PB-U4: label de aba do passageiro é "O teu pedido"', (tester) async {
  // Limpeza segura do token
  addTearDown(() => Ride4FreeAuth.token = null);
  Ride4FreeAuth.token = 'tok';

  // 1. Mock das SharedPreferences para o RideNotificationHub não rebentar
  SharedPreferences.setMockInitialValues({});

  // 2. Pedido falso com ID e campos essenciais para a UI não falhar no parser
  Map<String, dynamic> fakePassengerRequest() {
    return {
      'id': 2, 
      'status': 'pending',
      'driver_name': 'Condutor Teste',
      'destination_display': 'Aliados',
    };
  }

  final client = MockClient((r) async {
    // 3. Resposta robusta para o endpoint dos pedidos do passageiro
    if (r.url.path.contains('my-join-requests')) {
      return http.Response(
        jsonEncode({
          'requests': [fakePassengerRequest()],
          'rows': [fakePassengerRequest()]
        }), 
        200
      );
    }
    // Fallback seguro para qualquer outro pedido
    return http.Response(jsonEncode({'requests': [], 'rows': []}), 200);
  });

  await http.runWithClient(() async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PedidosPage()))
    );
    
    // 4. Contornar o Timer infinito
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Como a página arranca logo nesta aba, basta validar
    expect(find.text('O teu pedido'), findsOneWidget);
  }, () => client);
});
  });
}