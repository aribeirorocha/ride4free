// ignore_for_file: duplicate_ignore, unused_element_parameter, unused_element, deprecated_member_use

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:Ride4Free/ride4free_session_sync.dart';

import 'ride4free_api.dart';
import 'session/university_session_store.dart';
import 'sigarra/sigarra_auth_service.dart';
import 'location_service.dart';
import 'active_ride_flow.dart';
import 'pedidos_page.dart';
import 'rating_widgets.dart';

void main() {
  runApp(const MyApp());
}

void _showMessage(BuildContext context, String text) {

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );
    }
  });
}

const kRed = Color(0xFFDF3E45);
const kBackground = Color(0xFFFFFFFF);
const kCard = Color(0xFFFDFDFD);
const kDivider = Color(0xFFE8E8E8);
const kMuted = Color(0xFF7D7D7D);
const kSuccess = Color(0xFF62B86B);
const kDarkText = Color(0xFF1E1E1E);
const kLight = Color(0xFFD5D5D5);
const kLighter = Color(0x00000000);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        colorScheme: const ColorScheme.light(primary: kRed),
      ),
      home: const AppBootstrapper(),
    );
  }
}

class AppBootstrapper extends StatefulWidget {
  final Ride4FreeApi? api; 
  final SigarraAuthService? authService;
  const AppBootstrapper({super.key, this.api, this.authService});
  

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  final _sessionStore = UniversitySessionStore();
  late final Ride4FreeApi _api = widget.api ?? Ride4FreeApi();
  late final SigarraAuthService _auth = widget.authService ?? SigarraAuthService();
  bool _loading = true;
  bool _authenticated = false;
  UniversityIdentity? _identity;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final isLoggedIn = await _sessionStore.isLoggedIn();
    final identity = await _sessionStore.identity();
    if (isLoggedIn && identity != null) {
      await _ensureRide4FreeSession(identity);
    }
    if (!mounted) return;
    setState(() {
      _authenticated = isLoggedIn && identity != null;
      _identity = identity;
      _loading = false;
    });
  }

  Future<void> _onLoginSuccess(UniversityIdentity identity) async {
    await _sessionStore.markLoggedIn(identity);
    await _ensureRide4FreeSession(identity);
    if (!mounted) return;
    setState(() {
      _authenticated = true;
      _identity = identity;
    });
  }

  Future<void> _onUniversityLogout() async {
    await _sessionStore.clear();
    Ride4FreeAuth.token = null;
    if (!mounted) return;
    setState(() {
      _authenticated = false;
      _identity = null;
    });
  }

  Future<void> _ensureRide4FreeSession(UniversityIdentity identity) async {
    final ({String email, String apiPassword}) creds = TesterAuth.isTesterUsername(identity.username)
        ? TesterAuth.apiCredentials(identity.username)
        : (email: '${identity.username}@fe.up.pt', apiPassword: 'pass_${identity.username}');
    try {
      await syncRide4FreeApiSession(
        email: creds.email,
        password: creds.apiPassword,
        displayName: identity.displayName,
        api: _api,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

  if (!_authenticated) {
    return UniversityLoginPage(
      onLoginSuccess: _onLoginSuccess,
     authService: _auth, 
    );
  }

    return ActiveRideCoordinator(
      child: HomeShell(
        onUniversityLogout: _onUniversityLogout,
        identity: _identity!,
      ),
    );
  }
}

class UniversityLoginPage extends StatefulWidget {
  const UniversityLoginPage({
    super.key, 
    required this.onLoginSuccess, 
    this.authService // Adiciona isto
  });

  final Future<void> Function(UniversityIdentity identity) onLoginSuccess;
  final SigarraAuthService? authService;

  @override
  State<UniversityLoginPage> createState() => _UniversityLoginPageState();
}

class _UniversityLoginPageState extends State<UniversityLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final _auth = widget.authService ?? SigarraAuthService();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Preencha as credenciais universitárias.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final identity = await _auth.login(username: username, password: password);
      if (!mounted) return;
      if (identity == null) {
        setState(() => _error = 'Credenciais inválidas. Tente novamente.');
        return;
      }
      await widget.onLoginSuccess(identity);
    } catch (e) {
      if (!mounted) return;
      final hint = TesterAuth.isTesterUsername(username)
          ? ' Conta teste: confirme que o backend está a correr.'
          : '';
      setState(() => _error = 'Não foi possível concluir o login.$hint ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Ícone e Cabeçalho ---
                  Container(
                    height: 80,
                    width: 80,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school, size: 40, color: kRed),
                  ),
                  
                  const Text(
                    'Autenticação Universitária',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No primeiro acesso, entre com as suas credenciais da Universidade do Porto (Sigarra).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontSize: 14, height: 1.4),
                  ),
                  
                  // Aviso de conta de teste (suave)
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 32),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Conta de teste: admin ou tester | Password: test01',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),

                  // --- Campos de Input ---
                  TextField(
                    key: const Key('user_field'),
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Número mecanográfico',
                      prefixIcon: const Icon(Icons.person_outline, color: kRed),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      floatingLabelStyle: const TextStyle(color: kRed, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    key: const Key('pass_field'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: kRed),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      floatingLabelStyle: const TextStyle(color: kRed, fontWeight: FontWeight.w700),
                    ),
                  ),
                  
                  // --- Mensagem de Erro ---
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: kRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: kRed, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // --- Botão Principal ---
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: kRed.withOpacity(0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ]
                    ),
                    child: FilledButton(
                      onPressed: _busy ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: kRed,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)
                        ),
                      ),
                      child: _busy 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          )
                        : const Text(
                            'Entrar', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.onUniversityLogout,
    required this.identity,
  });

  final Future<void> Function() onUniversityLogout;
  final UniversityIdentity identity;

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;

  void goToHomeTab() {
    if (_index != 0) setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            const CommunityBoardPage(),
            const SearchRidePage(),
            const OfferRidePage(),
            const PedidosPage(),
            ProfilePage(
              isActive: _index == 4,
              onUniversityLogout: widget.onUniversityLogout,
              identity: widget.identity,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 66,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.groups), label: 'Comunidade'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Procurar'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Oferecer'),
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class CommunityBoardPage extends StatefulWidget {
  const CommunityBoardPage({super.key});

  @override
  State<CommunityBoardPage> createState() => CommunityBoardPageState();
}

class CommunityBoardPageState extends State<CommunityBoardPage> {
  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);

      if (diff.inMinutes < 1) return 'Agora mesmo';
      if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'Há ${diff.inHours}h';
      if (diff.inDays == 1) return 'Ontem';
      return 'Há ${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
  final _api = Ride4FreeApi();
  Timer? _refreshTimer;
  int _section = 0; // 0 = drivers, 1 = passengers, 2 = database
  bool _loading = false;
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _passengers = [];
  Map<String, dynamic>? _schema;
  @override
  void initState() {
    super.initState();
    
    // 1. Carrega os dados mal a página abre
    _loadSection();

    // 2. Inicia o Timer para atualizar a cada35 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_loading) { 
        _loadSection(); 
      }
    });
  }
  @override
  void dispose() {
    _refreshTimer?.cancel(); // Desliga o Timer
    super.dispose();
  }
  Future<void> _bookDriver(int offerId) async {
    if (Ride4FreeAuth.token == null) {
      _showMessage(context, 'Inicie sessão no perfil.');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _api.requestJoinRide(offerId: offerId);
      if (mounted) {
        _showMessage(
          context,
          'Pedido enviado (−5 créditos). Saldo: ${result.creditsBalance} créditos.',
        );
      }
      await _loadSection();
    } on Ride4FreeApiException catch (e) {
      if (mounted) {
        String msg = 'Erro ao reservar boleia.';
        try {
          final body = jsonDecode(e.body);
          // Se o backend devolver o erro específico de reservar a própria boleia:
          if (body['detail'] == 'You cannot book your own ride') {
            msg = 'Não podes reservar a tua própria boleia!';
          } else {
            // Para outros erros do backend, mostra só o texto limpo
            msg = body['detail'] ?? msg;
          }
        } catch (_) {}
        _showMessage(context, msg);
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro inesperado.');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ignore: unused_element
  Future<void> _bookPassenger(int requestId) async {
    if (Ride4FreeAuth.token == null) {
      _showMessage(context, 'Inicie sessão no perfil.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.bookPassengerRequest(requestId);
      if (mounted) _showMessage(context, 'Passageiro associado a esta viagem.');
      await _loadSection();
    } on Ride4FreeApiException catch (e) {
      if (mounted) {
        String msg = 'Erro ao associar passageiro.';
        try {
          final body = jsonDecode(e.body);
          if (body['detail'] == 'You cannot book your own ride' || 
              body['detail'] == 'You cannot book your own request') {
            msg = 'Não podes dar boleia a ti próprio!';
          } else {
            msg = body['detail'] ?? msg;
          }
        } catch (_) {}
        _showMessage(context, msg);
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro inesperado.');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSection() async {
    if (Ride4FreeAuth.token == null) {
      _showMessage(context, 'Inicie sessão no perfil.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_section == 0) {
        final rows = await _api.listAvailableDrivers();
        if (mounted) setState(() => _drivers = rows);
      } else if (_section == 1) {
        final rows = await _api.listAvailablePassengers();
        if (mounted) setState(() => _passengers = rows);
      } else {
        final rows = await _api.getDatabaseSchema();
        if (mounted) setState(() => _schema = rows);
      }
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopTitleBar(title: 'Comunidade Ride4Free'),
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 30, 5, 10),
          child: Column(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, icon: Icon(Icons.drive_eta), label: Text('Condutores')),
                  ButtonSegment(value: 1, icon: Icon(Icons.people), label: Text('Passageiros')),
                  //ButtonSegment(value: 2, icon: Icon(Icons.storage), label: Text('BD')),
                ],
                selected: {_section},
                onSelectionChanged: (selection) {
                  setState(() => _section = selection.first);
                  _loadSection();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildSectionBody()),
      ],
    );
  }

  Widget _buildSectionBody() {
    if (_section == 0) {
      if (_drivers.isEmpty) {
        return const Center(
          child: Text('À procura de condutores...', style: TextStyle(color: kLighter)),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        itemCount: _drivers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final d = _drivers[i];
          
          // Extraímos as moradas gravadas
          final origin = d['description'] as String? ?? 'Local a definir';
          final dest = d['destination_display'] as String? ?? 'Destino a definir';
          final time = d['departure_time'] ?? 'Horário a definir';
          final timeStr = _timeAgo(d['created_at'] as String?);
          
          final rating = d['rating_display'] as String? ?? '—';
          return ProfileCard(
            title: d['driver_name'] as String? ?? 'Condutor',
            subtitle: "📍 De: $origin\n🏁 Para: $dest\n⏰ Partida: $time\n⭐ $rating",
            description: "Lugares disponíveis: ${d['available_seats']}",
            statusLabel: (d['booked'] as bool? ?? false) ? 'Reservado' : 'Disponível',
            actionText: (d['booked'] as bool? ?? false) ? null : 'Pedir boleia',
            onAction: () => _bookDriver((d['id'] as num).toInt()),
            timeAgoText: timeStr,
          );
        },
      );
    }

    if (_section == 1) {
      if (_passengers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.directions_walk, size: 64, color: kDivider),
              SizedBox(height: 16),
              Text('Sem passageiros à procura no momento.', 
                  style: TextStyle(color: kMuted, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        itemCount: _passengers.length, // ✅ BUG CORRIGIDO: Usa a lista certa!
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = _passengers[i]; // ✅ BUG CORRIGIDO: Usa a variável certa!
          
          final dest = p['destination_display'] as String? ?? 'Destino a definir';
          final count = p['passenger_count']?.toString() ?? '1';
          final status = p['status'] as String? ?? 'open';
          final isBooked = status == 'fulfilled';
          final timeStr = _timeAgo(p['created_at'] as String?);

          return ProfileCard(
            title: p['passenger_name'] as String? ?? 'Passageiro',
            // Design muito mais limpo com Emojis e espaçamento
            subtitle: "📍 Precisa de ir para: $dest",
            description: "🚶‍♂️ Necessita de $count lugar(es)",
            
            // Lógica de cores e texto melhorada
            statusLabel: isBooked ? '✓ Boleia Encontrada' : ' A aguardar condutor ...',
            
            // O botão agora faz sentido para quem está a ler!
            actionText: isBooked ? null : 'Dar boleia a esta pessoa',
            onAction: () => _bookPassenger((p['id'] as num).toInt()),
            timeAgoText: timeStr,
          );
        },
      );
    }

    final tables = (_schema?['tables'] as Map<String, dynamic>?) ?? {};
    if (tables.isEmpty) {
      return const Center(
        child: Text('Schema indisponivel. Carregue em "Atualizar secao".', style: TextStyle(color: kMuted)),
      );
    }
    final tableNames = tables.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      itemCount: tableNames.length,
      itemBuilder: (context, i) {
        final tableName = tableNames[i];
        final cols = (tables[tableName] as List<dynamic>).cast<Map<String, dynamic>>();
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tableName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...cols.map(
                      (c) => Text(
                    '- ${c['name']} (${c['type']})${(c['primary_key'] as bool? ?? false) ? ' [PK]' : ''}',
                    style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OfferRidePage extends StatefulWidget {
  const OfferRidePage({super.key});

  @override
  State<OfferRidePage> createState() => _OfferRidePageState();
}

class _OfferRidePageState extends State<OfferRidePage> {
  final TextEditingController _timeController = TextEditingController(text: '08:15');
  String? _timeError; 
  bool _isValidTime(String input) {
  final RegExp timeRegExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
  return timeRegExp.hasMatch(input);
}
  int _seats = 3;
  final _destController = TextEditingController(text: '');
  final _vehicleController = TextEditingController(); 
  final _api = Ride4FreeApi();
  bool _busy = false;
  int? _lastPublishedOfferId;
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;
  String? _originAddress;
  String? _destinationAddress;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (mounted) setState(() => _originLatLng = loc);
  }
  Future<void> _getAddressFromLatLng(LatLng loc, bool isOrigin) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${loc.latitude}&lon=${loc.longitude}&format=json',
      );
      final r = await http.get(uri, headers: {'User-Agent': 'Ride4Free/1.0'});
      
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        
        final roadName = address?['road'] as String?
            ?? address?['pedestrian'] as String?
            ?? address?['suburb'] as String?
            ?? data['display_name'] as String?
            ?? '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';

        setState(() {
          if (isOrigin) {
            _originAddress = roadName;
          } else {
            _destinationAddress = roadName;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  Future<void> _openRideRequests() async {
    if (_lastPublishedOfferId == null) {
      _showMessage(context, 'Publique uma viagem primeiro.');
      return;
    }
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DriverRideRequestsPage(
          offerId: _lastPublishedOfferId!,
          destination: _destinationAddress,
        ),
      ),
    );
    if (accepted == true && mounted) {
      final state = await _api.getActiveRideState();
      if (state.ride != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: ActiveRidePage.routeName),
            builder: (_) => ActiveRidePage(initialRide: state.ride!),
          ),
        );
      }
    }
  }

  Future<void> _publish() async {
    if (!_isValidTime(_timeController.text)) {
      _showMessage(context, 'Por favor, insira uma hora válida (HH:mm).');
      return;
    }

    if (_originLatLng == null || _destinationLatLng == null) {
      _showMessage(context, 'Selecione o ponto de partida e de chegada no mapa.');
      return;
    }

    setState(() => _busy = true);
    try {
      final offerId = await _api.createDriverOffer(
        destination: _destinationAddress ?? "Destino definido no mapa",
        availableSeats: _seats,
        departureTime: _timeController.text,
        description: _originAddress ?? "Partida definida no mapa",
        vehicleInfo: _vehicleController.text.trim().isEmpty ? null : _vehicleController.text.trim(),
        originLat: _originLatLng?.latitude,
        originLng: _originLatLng?.longitude,
        destinationLat: _destinationLatLng?.latitude,
        destinationLng: _destinationLatLng?.longitude,
        
      );

      if (mounted) {
        setState(() => _lastPublishedOfferId = offerId);
        _showMessage(context, 'Viagem publicada! Veja os pedidos de boleia.');
      }
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _seePassengers() async {
    if (Ride4FreeAuth.token == null) {
      _showMessage(context, 'Inicie sessão no perfil.');
      return;
    }
    setState(() => _busy = true);
    try {
      final m = await _api.listPassengersForDestination(_destController.text);
      if (!mounted) return;
      final rc = m['request_count'] as int? ?? m['rows']?.length ?? 0;
      final total = m['total_passenger_slots'] as int? ?? m['total_passengers'] as int? ?? 0;
      final requests = (m['requests'] as List?) ?? (m['rows'] as List?) ?? [];
      final lines = <String>['Pedidos: $rc', 'Total passageiros: $total', ''];
      for (final r in requests) {
        final map = r as Map<String, dynamic>;
        lines.add('- ${map['passenger_name']}: ${map['passenger_count']} pax');
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Passageiros para o mesmo destino'),
          content: SingleChildScrollView(child: Text(lines.join('\n'))),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = _seats > 0 && !_busy;
    
    return Column(
      children: [
        const TopTitleBar(title: 'Oferecer Boleia'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
            children: [
              
              // --- BLOCO 1: TRAJETO (MAPAS) ---
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trip_origin, size: 18, color: kRed),
                        const SizedBox(width: 8),
                        Expanded(child: _label('Ponto de Partida')),
                      ],
                    ),
                    _addressStatus(_originLatLng != null, _originAddress),
                    const SizedBox(height: 10),
                    _mapBox(
                      child: _ConferenceMap(
                        userLocation: _originLatLng,
                        radiusMeters: 10,
                        onTap: (latlng) {
                          setState(() {
                            _originLatLng = latlng;
                            _originAddress = 'A obter rua...';
                          });
                          _getAddressFromLatLng(latlng, true);
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 18, color: kSuccess),
                        const SizedBox(width: 8),
                        Expanded(child: _label('Ponto de Chegada')),
                      ],
                    ),
                    _addressStatus(_destinationLatLng != null, _destinationAddress),
                    const SizedBox(height: 10),
                    _mapBox(
                      child: _ConferenceMap(
                        userLocation: _destinationLatLng,
                        radiusMeters: 10,
                        onTap: (latlng) {
                          setState(() {
                            _destinationLatLng = latlng;
                            _destinationAddress = 'A obter rua...';
                          });
                          _getAddressFromLatLng(latlng, false);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- BLOCO 2: DETALHES (HORA E LUGARES) ---
              _sectionCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Hora'),
                          TextField(
                            controller: _timeController,
                            keyboardType: TextInputType.datetime,
                            decoration: InputDecoration(
                              hintText: 'HH:MM',
                              errorText: _timeError,
                              prefixIcon: Icon(Icons.access_time, color: kRed, size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Lugares'),
                          SeatPicker(
                            seats: _seats,
                            onDec: () { if (_seats > 0) setState(() => _seats--); },
                            onInc: () => setState(() => _seats++),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- BLOCO 3: VEÍCULO ---
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Teu Veículo'),
                    TextField(
                      controller: _vehicleController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Renault Clio Preto',
                        prefixIcon: Icon(Icons.directions_car, color: kRed, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- BLOCO FINAL: RECOMPENSA E BOTÃO ---
              RewardPanel(valid: canPublish, rewardText: '+${_seats * 10} Créditos'),
              const SizedBox(height: 24),
              
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: kRed.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ]
                ),
                child: FilledButton(
                  onPressed: canPublish ? _publish : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: kRed,
                    minimumSize: const Size.fromHeight(60), // Mais alto e tátil
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _busy 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text(
                        'Publicar Viagem', 
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)
                      ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Podes gerir os teus pedidos na aba "Pedidos".',
                  style: TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPERS VISUAIS (Adicionar estes métodos abaixo do build) ---

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _addressStatus(bool defined, String? address) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: Text(
        defined ? (address ?? "Localização definida") : "Toca no mapa para definir...",
        style: TextStyle(
          color: defined ? Colors.black87 : kMuted,
          fontWeight: defined ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _mapBox({required Widget child}) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: child,
      ),
    );
  }
  }


  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11, 
        color: kMuted, 
        fontWeight: FontWeight.w800, 
        letterSpacing: 0.8
      ),
    ),
  );


class SearchRidePage extends StatefulWidget {
  const SearchRidePage({super.key});

  @override
  State<SearchRidePage> createState() => _SearchRidePageState();
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.isActive = false,
    required this.onUniversityLogout,
    required this.identity,
  });

  final bool isActive;
  final Future<void> Function() onUniversityLogout;
  final UniversityIdentity identity;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _SearchRidePageState extends State<SearchRidePage> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _timeController = TextEditingController();
  final _api = Ride4FreeApi();
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = false;
  LatLng? _userLocation;
  
  // Variáveis para o Ponto de Recolha
  LatLng? _pickupLatLng;
  String? _pickupAddress;
  
  double _radiusMeters = 500; // default 500m
  int _tabIndex = 0; // 0 = Procurar, 1 = Pedir Boleia
  int _neededSeats = 1;

  String _locationLabel = 'A obter localização…';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (!mounted || loc == null) return;
    setState(() => _userLocation = loc);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?lat=${loc.latitude}&lon=${loc.longitude}&format=json',
      );
      final r = await http.get(uri, headers: {'User-Agent': 'Ride4Free/1.0'});
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        final road = address?['road'] as String?
            ?? address?['pedestrian'] as String?
            ?? address?['suburb'] as String?
            ?? data['display_name'] as String?
            ?? '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';
        setState(() => _locationLabel = road);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationLabel =
        '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}');
      }
    }
  }

  // NOVA FUNÇÃO: Obter morada exata quando se clica no mapa
  Future<void> _getAddressFromLatLng(LatLng loc) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${loc.latitude}&lon=${loc.longitude}&format=json',
      );
      final r = await http.get(uri, headers: {'User-Agent': 'Ride4Free/1.0'});
      
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        
        final roadName = address?['road'] as String?
            ?? address?['pedestrian'] as String?
            ?? address?['suburb'] as String?
            ?? data['display_name'] as String?;

        setState(() {
          _pickupAddress = roadName;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (Ride4FreeAuth.token == null) {
      _showMessage(context, 'Inicie sessão no perfil.');
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _api.listDriversForDestination(
        _destController.text,
        lat: (_pickupLatLng ?? _userLocation)?.latitude,
        lng: (_pickupLatLng ?? _userLocation)?.longitude,
        radiusM: _radiusMeters.toInt(),
      );
      if (mounted) setState(() => _drivers = list);
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reserveDriver(Map<String, dynamic> d) async {
    if (Ride4FreeAuth.token == null) {
      _showMessage(context, 'Inicie sessão no perfil.');
      return;
    }
    final offerId = d['id'];
    if (offerId == null) {
      _showMessage(context, 'Oferta inválida.');
      return;
    }
    setState(() => _loading = true);
    try {
      final origin = _originController.text.trim().isNotEmpty
          ? _originController.text.trim()
          : (_pickupAddress ?? _locationLabel);
      final result = await _api.requestJoinRide(
        offerId: (offerId as num).toInt(),
        passengerCount: _neededSeats,
        originDisplay: origin,
        destinationDisplay: _destController.text.trim(),
        departureTime: _timeController.text.trim().isEmpty ? null : _timeController.text.trim(),
      );
      if (mounted) {
        _showMessage(
          context,
          'Pedido enviado (−5 créditos). Saldo: ${result.creditsBalance}. Ver Pedidos para conversar.',
        );
      }
    } on Ride4FreeApiException catch (e) {
      if (mounted) _showMessage(context, e.body);
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registerRequest() async {
    if (Ride4FreeAuth.token == null) {
      _showMessage(context, 'Inicie sessão no perfil.');
      return;
    }
    if (_destController.text.trim().isEmpty) {
      _showMessage(context, 'Por favor, indique um destino.');
      return;
    }
    
    setState(() => _loading = true);
    try {
      final origin = _originController.text.trim().isNotEmpty
          ? _originController.text.trim()
          : (_pickupAddress ?? _locationLabel);
      await _api.createPassengerRequest(
        destination: _destController.text,
        passengerCount: _neededSeats,
        originLat: (_pickupLatLng ?? _userLocation)?.latitude,
        originLng: (_pickupLatLng ?? _userLocation)?.longitude,
        originDisplay: origin,
        departureTime: _timeController.text.trim().isEmpty ? null : _timeController.text.trim(),
      );
      if (mounted) {
        _showMessage(context, 'Pedido publicado! Consulta o separador Pedidos.');
        setState(() => _neededSeats = 1);
      }
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- HELPERS VISUAIS PREMIUM ---
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11, 
        color: kMuted, 
        fontWeight: FontWeight.w800, 
        letterSpacing: 0.8
      ),
    ),
  );

  Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _addressStatus(bool defined, String? address, String fallback) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2, bottom: 8),
      child: Text(
        defined ? (address ?? "Localização definida") : fallback,
        style: TextStyle(
          color: defined ? Colors.black87 : kMuted,
          fontWeight: defined ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _mapBox({required Widget child}) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopTitleBar(title: 'Procurar Boleia'),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, icon: Icon(Icons.search), label: Text('Procurar')),
              ButtonSegment(value: 1, icon: Icon(Icons.waving_hand), label: Text('Pedir Boleia')),
            ],
            selected: {_tabIndex},
            onSelectionChanged: (selection) {
              setState(() => _tabIndex = selection.first);
            },
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _tabIndex == 0 
              ? _buildSearchTab() 
              : _buildRequestTab(),
        ),
      ],
    );
  }

  // --- ABA 1: PROCURAR CONDUTORES ---
  Widget _buildSearchTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      children: [
        
        // BLOCO 1: DESTINO
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Para onde queres ir?'),
              TextField(
                controller: _destController,
                decoration: InputDecoration(
                  hintText: 'Ex: FEUP (Polo II)',
                  prefixIcon: const Icon(Icons.flag, color: kRed, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _search,
                style: FilledButton.styleFrom(
                  backgroundColor: kSuccess,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.search),
                label: Text(
                  _loading ? 'A procurar…' : 'Procurar condutores',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)
                ),
              ),
            ],
          ),
        ),

        // BLOCO 2: MAPA E RAIO
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label('Raio de Tolerancia'),
                  Text('${_radiusMeters.toInt()}m', style: const TextStyle(color: kRed, fontWeight: FontWeight.w800)),
                ],
              ),
              Slider(
                value: _radiusMeters,
                min: 100,
                max: 2000,
                divisions: 19,
                activeColor: kRed,
                inactiveColor: kRed.withOpacity(0.2),
                onChanged: (v) => setState(() => _radiusMeters = v),
                onChangeEnd: (v) {
                  setState(() => _radiusMeters = v);
                  if (_drivers.isNotEmpty) _search();
                },
              ),
              const Divider(height: 24, color: kDivider),
              _label('O teu ponto de partida'),
              _addressStatus(_pickupLatLng != null, _pickupAddress, 'A usar o GPS. Toca no mapa para alterar.'),
              _mapBox(
                child: _ConferenceMap(
                  userLocation: _pickupLatLng ?? _userLocation,
                  radiusMeters: _radiusMeters,
                  onTap: (latlng) {
                    setState(() {
                      _pickupLatLng = latlng;
                      _pickupAddress = 'A obter rua...';
                    });
                    _search(); 
                    _getAddressFromLatLng(latlng);
                  },
                  driverOrigins: _drivers
                      .where((d) => d['origin_lat'] != null)
                      .map((d) => LatLng(
                    (d['origin_lat'] as num).toDouble(),
                    (d['origin_lng'] as num).toDouble(),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),

        // LISTA DE RESULTADOS
        if (_drivers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhum condutor encontrado neste raio.', 
                style: TextStyle(color: kMuted, fontWeight: FontWeight.w600)
              )
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Boleias Encontradas'.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted, letterSpacing: 0.5)
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _drivers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = _drivers[i];
              return RideCard(
                name: d['driver_name'] as String? ?? 'Condutor',
                car: 'Lugares livres: ${d['available_seats'] ?? '?'}',
                rating: d['rating_display'] as String? ?? '—',
                distance: d['destination_display'] as String? ?? '',
                credits: '−5',
                onReserve: _loading ? null : () => _reserveDriver(d),
              );
            },
          ),
        ],
      ],
    );
  }

  // --- ABA 2: PEDIR BOLEIA ---
  Widget _buildRequestTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      children: [
        
        // BLOCO 1: TRAJETO
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Origem'),
              TextField(
                controller: _originController,
                decoration: InputDecoration(
                  hintText: 'Ex: Rua de Cedofeita',
                  prefixIcon: const Icon(Icons.trip_origin, color: kRed, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _label('Destino'),
              TextField(
                controller: _destController,
                decoration: InputDecoration(
                  hintText: 'Ex: FEUP (Polo II)',
                  prefixIcon: const Icon(Icons.flag, color: kSuccess, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        // BLOCO 2: DATA E LUGARES
        _sectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Data / Hora'),
                    TextField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        hintText: 'HH:MM',
                        prefixIcon: const Icon(Icons.schedule, color: kRed, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Lugares'),
                    SeatPicker(
                      seats: _neededSeats,
                      onDec: () {
                        if (_neededSeats > 1) setState(() => _neededSeats--);
                      },
                      onInc: () => setState(() => _neededSeats++),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // BLOCO 3: MAPA DE PICKUP
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('O teu ponto de pickup'),
              _addressStatus(_pickupLatLng != null, _pickupAddress, '📍 A usar: $_locationLabel'),
              _mapBox(
                child: _ConferenceMap(
                  userLocation: _pickupLatLng ?? _userLocation,
                  radiusMeters: 0, 
                  onTap: (latlng) {
                    setState(() {
                      _pickupLatLng = latlng;
                      _pickupAddress = 'A obter rua...';
                    });
                    _getAddressFromLatLng(latlng);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // BOTÃO PUBLICAR
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: kRed.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
            ]
          ),
          child: FilledButton.icon(
            onPressed: _loading ? null : _registerRequest,
            style: FilledButton.styleFrom(
              backgroundColor: kRed,
              minimumSize: const Size.fromHeight(60), // Tamanho Premium
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.campaign, color: Colors.white),
            label: Text(
              _loading ? 'A publicar...' : 'Pedir Boleia', 
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)
            ),
          ),
        ),
      ],
    );
  }
}
class _ProfilePageState extends State<ProfilePage> {
  final _api = Ride4FreeApi();
  final _vehicleController = TextEditingController();
  bool _busy = false;
  bool _loadingProfile = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _transactions = [];
  int _creditsBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (Ride4FreeAuth.token == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }
    setState(() => _loadingProfile = true);
    try {
      final profile = await _api.getUserProfile();
      var balance = (profile['credits_balance'] as num?)?.toInt() ?? 0;
      var transactions = <Map<String, dynamic>>[];
      try {
        final credits = await _api.getCredits();
        balance = credits.balance;
        transactions = credits.transactions;
      } catch (_) {}
      final reviews = await _api.getUserReviews(profile['id'] as int);
      if (!mounted) return;
      _vehicleController.text = profile['vehicle_info'] as String? ?? '';
      setState(() {
        _profile = profile;
        _creditsBalance = balance;
        _transactions = transactions;
        _reviews = reviews;
      });
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro ao carregar perfil: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _saveVehicle() async {
    final v = _vehicleController.text.trim();
    if (v.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _api.updateVehicleInfo(v);
      if (mounted) _showMessage(context, 'Veículo guardado.');
      await _loadProfile();
    } catch (e) {
      if (mounted) _showMessage(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await _api.logout();
      if (mounted) _showMessage(context, 'Sessão terminada.');
    } catch (e) {
      Ride4FreeAuth.token = null;
      if (mounted) _showMessage(context, 'Sessão terminada (local).');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logoutUniversity() async {
    setState(() => _busy = true);
    try {
      await _logout();
    } finally {
      await widget.onUniversityLogout();
      if (mounted) {
        _showMessage(context, 'Sessão universitária terminada.');
      }
    }
  }

  // --- HELPERS VISUAIS PREMIUM ---

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w800, letterSpacing: 0.8),
    ),
  );

  Widget _sectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _statItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopTitleBar(title: 'Perfil'),
        Expanded(
          child: _loadingProfile
              ? const Center(child: CircularProgressIndicator(color: kRed))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    
                    // --- 1. HEADER (Estilo Instagram) ---
                    Center(
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: kRed.withOpacity(0.2), width: 4),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: kRed.withOpacity(0.1),
                              backgroundImage: widget.identity.photoUrl != null
                                  ? NetworkImage(widget.identity.photoUrl!)
                                  : null,
                              child: widget.identity.photoUrl == null
                                  ? const Icon(Icons.person, size: 40, color: kRed)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.identity.displayName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.identity.username} · Universidade do Porto',
                            style: const TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    // --- 2. CAIXA DE ESTATÍSTICAS RÁPIDAS ---
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statItem('⭐', _profile?['rating_display']?.toString() ?? '—', 'Avaliação'),
                          Container(width: 1.5, height: 40, color: Colors.grey.withOpacity(0.15)),
                          _statItem('🪙', '$_creditsBalance', 'Créditos'),
                        ],
                      ),
                    ),

                    // --- 4. HISTÓRICO DE CRÉDITOS (Estilo Lista Uber) ---
                    if (_transactions.isNotEmpty) ...[
                      _label('Histórico de Créditos'),
                      _sectionCard(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transactions.length > 15 ? 15 : _transactions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: kDivider),
                          itemBuilder: (context, i) {
                            final t = _transactions[i];
                            final amt = (t['amount_delta'] as num?) ?? 0;
                            final isPos = amt >= 0;
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isPos ? kSuccess.withOpacity(0.12) : kRed.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPos ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isPos ? kSuccess : kRed,
                                  size: 18,
                                ),
                              ),
                              title: Text(t['description'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                              subtitle: Text(t['created_at'] as String? ?? '', style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                              trailing: Text(
                                '${isPos ? '+' : ''}$amt',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isPos ? kSuccess : kRed),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // --- 5. AVALIAÇÕES RECEBIDAS (Estilo Uber) ---
                    if (_reviews.isNotEmpty) ...[
                      _label('Avaliações Recebidas'),
                      _sectionCard(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length > 10 ? 10 : _reviews.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: kDivider),
                          itemBuilder: (context, i) {
                            final r = _reviews[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        r['rater_name'] as String? ?? 'Utilizador', 
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)
                                      ),
                                      StarDisplay(stars: (r['stars'] as num?)?.toInt() ?? 0, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${r['created_at'] ?? ''}', style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // --- 6. BOTÃO DE LOGOUT ---
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _logoutUniversity,
                      icon: const Icon(Icons.logout, color: kRed),
                      label: const Text('Terminar Sessão', style: TextStyle(color: kRed, fontWeight: FontWeight.w800, fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: kRed, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
class TopTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  // ignore: use_key_in_widget_constructors
  const TopTitleBar({required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      width: double.infinity,
      color: kRed,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center, // Garante que tudo o que está dentro do Stack tende a centrar
        children: [
          // 1. O Título fica no centro exato do ecrã
          Text(
            title, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          
          // 2. Se houver botão de voltar, ele é encostado à esquerda de forma independente
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}
class InputLike extends StatelessWidget {
  final String text;
  // ignore: use_key_in_widget_constructors
  const InputLike({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2E2), width: 2),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

class SeatPicker extends StatelessWidget {
  final int seats;
  final VoidCallback onDec;
  final VoidCallback onInc;

  // ignore: use_key_in_widget_constructors
  const SeatPicker({required this.seats, required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: seats > 0 ? const Color(0xFFE2E2E2) : kRed, width: 2),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onDec, icon: const Icon(Icons.remove, color: kRed)),
          Expanded(child: Text('$seats', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: seats > 0 ? kDarkText : kRed))),
          IconButton(onPressed: onInc, icon: const Icon(Icons.add, color: kRed)),
        ],
      ),
    );
  }
}

class RewardPanel extends StatelessWidget {
  final bool valid;
  final String rewardText;
  // ignore: use_key_in_widget_constructors
  const RewardPanel({required this.valid, required this.rewardText});

  @override
  Widget build(BuildContext context) {
    if (!valid) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAFA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kRed, width: 2),
        ),
        child: const Column(
          children: [
            Text('Lotacao Invalida', style: TextStyle(color: kRed, fontWeight: FontWeight.w800, fontSize: 17)),
            SizedBox(height: 4),
            Text('Indique pelo menos 1 lugar disponivel para ganhar créditos.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FFF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kSuccess, width: 2),
      ),
      child: Column(
        children: [
          const Text('Recompensa Estimada', style: TextStyle(color: kSuccess, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Text(rewardText, style: const TextStyle(color: Color(0xFF2E6440), fontWeight: FontWeight.w900, fontSize: 26)),
          const SizedBox(height: 4),
          const Text('Valido para 1 viagem como passageiro', style: TextStyle(fontWeight: FontWeight.w600, color: kDarkText)),
        ],
      ),
    );
  }
}

class RouteRow extends StatelessWidget {
  final Color color;
  final String text;
  // ignore: use_key_in_widget_constructors
  const RouteRow({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 11, height: 11, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 18, color: Color(0xFF5A5A5A), fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class RideCard extends StatelessWidget {
  final String name;
  final String car;
  final String rating;
  final String distance;
  final String credits;
  final VoidCallback? onReserve;

  const RideCard({
    super.key,
    required this.name,
    required this.car,
    required this.rating,
    required this.distance,
    required this.credits,
    this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFFFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kSuccess, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('$car - ⭐ $rating', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('📍 a $distance de si', style: const TextStyle(color: kSuccess, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(width: 1, height: 52, color: kDivider),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(credits, style: const TextStyle(color: kRed, fontWeight: FontWeight.w800, fontSize: 28)),
              const Text('Custo', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
              if (onReserve != null) ...[
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: onReserve,
                  style: FilledButton.styleFrom(
                    backgroundColor: kRed,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Reservar Boleia', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class TickRow extends StatelessWidget {
  final String text;
  const TickRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kDivider))),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500))),
          const Icon(Icons.check_box, color: kLight),
        ],
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String? statusLabel;
  final String? actionText;
  final VoidCallback? onAction;
  final String? timeAgoText;

  const ProfileCard({
    super.key, 
    required this.title,
    required this.subtitle,
    required this.description,
    this.statusLabel,
    this.actionText,
    this.onAction,
    this.timeAgoText,
  });

  @override
  Widget build(BuildContext context) {
    // Lógica visual simples para ver se está disponível ou não
    final isAvailable = statusLabel?.contains('Dispon') == true || 
                        statusLabel?.contains('aguardar') == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22), // Cantos bem redondos
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Sombra super suave
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Avatar, Nome, Status e Tempo ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: kRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: kRed, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    if (statusLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? kSuccess.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: isAvailable ? kSuccess : Colors.grey[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (timeAgoText != null && timeAgoText!.isNotEmpty)
                Text(
                  timeAgoText!,
                  style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: kDivider),
          ),
          
          // --- BODY: Moradas e Horários ---
          Text(
            subtitle, 
            style: const TextStyle(
              color: Colors.black87, 
              fontWeight: FontWeight.w600, 
              fontSize: 14, 
              height: 1.5, // Maior espaçamento entre as linhas da morada
            ),
          ),
          const SizedBox(height: 14),
          
          // --- ZONA DE INFORMAÇÃO EXTRA (Lugares) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: kMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description, 
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          // --- FOOTER: Botão de Ação ---
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: kRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  actionText!, 
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _ConferenceMap extends StatefulWidget {
  final LatLng? userLocation;
  final double radiusMeters;
  final void Function(LatLng)? onTap;
  final List<LatLng> driverOrigins;

  const _ConferenceMap({
    super.key,
    this.userLocation,
    this.radiusMeters = 500,
    this.onTap,
    this.driverOrigins = const [],
  });

  @override
  State<_ConferenceMap> createState() => _ConferenceMapState();
}
class _ConferenceMapState extends State<_ConferenceMap> {
  // 1. Criar o controlador da câmara do mapa
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // Usamos um Stack para colocar os botões a flutuar por cima do mapa
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.userLocation ?? const LatLng(41.1780, -8.5980),
            initialZoom: 15.0,
            onTap: widget.onTap != null ? (_, latlng) => widget.onTap!(latlng) : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.conference_tool',
            ),
            if (widget.userLocation != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.userLocation!,
                    radius: widget.radiusMeters,
                    useRadiusInMeter: true,
                    color: kRed.withOpacity(0.1),
                    borderColor: kRed,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (widget.userLocation != null)
                  Marker(
                    point: widget.userLocation!,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.my_location, color: kRed, size: 36),
                  ),
                ...widget.driverOrigins.map(
                  (loc) => Marker(
                    point: loc,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.directions_car, color: kSuccess, size: 36),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Os Botões de Zoom (+ e -)
        Positioned(
          right: 12, // Distância da margem direita
          bottom: 12, // Distância da margem inferior
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão Zoom In (+)
              FloatingActionButton.small(
                heroTag: null, // heroTag null evita erros se houver dois mapas no ecrã
                backgroundColor: kCard,
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, currentZoom + 1.0);
                },
                child: const Icon(Icons.add, color: kDarkText),
              ),
              const SizedBox(height: 8),
              
              // Botão Zoom Out (-)
              FloatingActionButton.small(
                heroTag: null,
                backgroundColor: kCard,
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, currentZoom - 1.0);
                },
                child: const Icon(Icons.remove, color: kDarkText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
