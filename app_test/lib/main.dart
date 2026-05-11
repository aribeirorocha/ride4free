import 'dart:convert';
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'ride4free_api.dart';
import 'session/university_session_store.dart';
import 'sigarra/sigarra_auth_service.dart';
import 'location_service.dart';

void main() => runApp(const MyApp());

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
    final email = '${identity.username}@up.pt';
    final password = 'up_${identity.username}_session';
    try {
      final login = await _api.login(email: email, password: password);
      Ride4FreeAuth.token = login.token;
      return;
    } catch (_) {}

    try {
      final register = await _api.register(
        email: email,
        password: password,
        name: identity.displayName,
      );
      Ride4FreeAuth.token = register.token;
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

    return HomeShell(
      onUniversityLogout: _onUniversityLogout,
      identity: _identity!,
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
      setState(() => _error = 'Preencha as credenciais universitarias.');
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
        setState(() => _error = 'Credenciais invalidas. Tente novamente.');
        return;
      }
      await widget.onLoginSuccess(identity);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Nao foi possivel autenticar no Sigarra.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Autenticacao Universitaria',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No primeiro acesso, entre com as suas credenciais da universidade.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const Key('user_field'),
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Numero mecanografico / utilizador',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('pass_field'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(color: kRed, fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _busy ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: kRed,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(_busy ? 'A autenticar...' : 'Entrar'),
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
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

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
            ProfilePage(
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
          NavigationDestination(icon: Icon(Icons.groups), label: ''),
          NavigationDestination(icon: Icon(Icons.search), label: ''),
          NavigationDestination(icon: Icon(Icons.directions_car), label: ''),
          NavigationDestination(icon: Icon(Icons.person), label: ''),
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
      await _api.bookDriverOffer(offerId);
      if (mounted) _showMessage(context, 'Boleia reservada com sucesso.');
      await _loadSection();
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro ao reservar boleia: $e');
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
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro ao reservar passageiro: $e');
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
          return ProfileCard(
            title: d['driver_name'] as String? ?? 'Condutor',
            // Aqui vais ler o campo 'description' que a API agora retorna
            subtitle: "Partida: ${d['departure_time'] ?? 'Horário a definir'}",
            description: "Lugares: ${d['available_seats']}",
            statusLabel: (d['booked'] as bool? ?? false) ? 'Reservado' : 'Disponível',
            actionText: (d['booked'] as bool? ?? false) ? null : 'Reservar boleia',
            onAction: () => _bookDriver((d['id'] as num).toInt()),
          );
        },
      );
    }

    if (_section == 1) {
      if (_passengers.isEmpty) {
        return const Center(
          child: Text('Sem passageiros disponiveis.', style: TextStyle(color: kMuted)),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        itemCount: _passengers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        // Dentro do ListView.separated para Condutores (_section == 0)
        itemBuilder: (context, i) {
          final d = _drivers[i];
          return ProfileCard(
            title: d['driver_name'] as String? ?? 'Condutor',
            // Se a tua API devolver um campo 'departure_time', usa-o aqui:
            subtitle: "Hora de Partida: ${d['departure_time'] ?? '08:15'}", 
            description: d['profile_description'] as String? ?? 'Sem descrição.',
            statusLabel: (d['booked'] as bool? ?? false)
                ? 'Reservado'
                : 'Disponível',
            actionText: (d['booked'] as bool? ?? false) ? null : 'Reservar boleia',
            onAction: () => _bookDriver((d['id'] as num).toInt()),
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
  String? _timeError; // Para guardar a mensagem de erro
  bool _isValidTime(String input) {
  final RegExp timeRegExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
  return timeRegExp.hasMatch(input);
}
  int _seats = 3;
  final _destController = TextEditingController(text: 'FEUP (Polo II)');
  final _api = Ride4FreeApi();
  bool _busy = false;
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;
 

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (mounted) setState(() => _originLatLng = loc);
  }

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
  // 1. Validar se a hora escrita no TextField está correta
  if (!_isValidTime(_timeController.text)) {
    _showMessage(context, 'Por favor, insira uma hora válida (HH:mm).');
    return;
  }

  // 2. Validar se os pontos no mapa foram selecionados (segurança extra)
  if (_originLatLng == null || _destinationLatLng == null) {
    _showMessage(context, 'Selecione o ponto de partida e de chegada no mapa.');
    return;
  }

  setState(() => _busy = true);
  try {
    await _api.createDriverOffer(
      destination: "Ponto selecionado no mapa", // Texto fixo já que usas o mapa
      availableSeats: _seats,
      departureTime: _timeController.text,
      description: "Boleia universitária rápida",
      originLat: _originLatLng?.latitude,
      originLng: _originLatLng?.longitude,
      destinationLat: _destinationLatLng?.latitude,
      destinationLng: _destinationLatLng?.longitude,
    );
    
    if (mounted) _showMessage(context, 'Viagem publicada!');
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
      final rc = m['request_count'] as int? ?? 0;
      final total = m['total_passenger_slots'] as int? ?? 0;
      final requests = (m['requests'] as List?) ?? [];
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            children: [
              _label('PONTO DE PARTIDA'),
              const SizedBox(height: 6),
              if (_originLatLng == null)
                const Text(
                  'Toque no mapa para definir o ponto de partida',
                  style: TextStyle(color: kMuted, fontWeight: FontWeight.w600),
                )
              else
                Text(
                  'Partida definida ✓ (${_originLatLng!.latitude.toStringAsFixed(4)}, ${_originLatLng!.longitude.toStringAsFixed(4)})',
                  style: const TextStyle(color: kSuccess, fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _ConferenceMap(
                    userLocation: _originLatLng,
                    onTap: (latlng) => setState(() => _originLatLng = latlng),
                  ),
                ),
              ),
              _label('PONTO DE CHEGADA'),
              const SizedBox(height: 6),
              if (_destinationLatLng == null)
                const Text('Toque no mapa para definir o ponto de chegada',
                    style: TextStyle(color: kMuted, fontWeight: FontWeight.w600))
              else
                Text(
                  'Chegada definida ✓ (${_destinationLatLng!.latitude.toStringAsFixed(4)}, ${_destinationLatLng!.longitude.toStringAsFixed(4)})',
                  style: const TextStyle(color: kSuccess, fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _ConferenceMap(
                    userLocation: _destinationLatLng,
                    onTap: (latlng) => setState(() => _destinationLatLng = latlng),
                  ),
                ),
              ), 
              const SizedBox(height: 14),
              Row(
                children: [
                 Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('HORA'),
                          TextField(
                            key: const Key('destination_field'), 
                            controller: _destController,
                            keyboardType: TextInputType.datetime,
                            decoration: InputDecoration(
                              hintText: '08:30',
                              errorText: _timeError, // Mostra o erro aqui em baixo a vermelho
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  _timeError = 'Obrigatório';
                                } else if (!_isValidTime(value)) {
                                  _timeError = 'Formato inválido';
                                } else {
                                  _timeError = null; // Tudo OK!
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('LUGARES'),
                        SeatPicker(
                          seats: _seats,
                          onDec: () {
                            if (_seats > 0) setState(() => _seats--);
                          },
                          onInc: () => setState(() => _seats++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              RewardPanel(valid: canPublish, rewardText: '+${_seats * 10} Créditos'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: canPublish ? _publish : null,
                style: FilledButton.styleFrom(
                  backgroundColor: canPublish ? kRed : const Color(0xFFD5D5D5),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_busy ? 'A enviar…' : 'Publicar Viagem', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _seePassengers,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: kRed, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Ver passageiros para este destino', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w700),
  );
}

class SearchRidePage extends StatefulWidget {
  const SearchRidePage({super.key});

  @override
  State<SearchRidePage> createState() => _SearchRidePageState();
}

class _SearchRidePageState extends State<SearchRidePage> {
  final _destController = TextEditingController(text: 'FEUP (Polo II)');
  final _api = Ride4FreeApi();
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = false;
  LatLng? _userLocation;
  LatLng? _pickupLatLng;
  double _radiusMeters = 500; // default 500m
  // Label legível da localização atual do passageiro (reverse geocoding)
  // ignore: unused_field
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
    // Reverse geocoding com Nominatim para mostrar nome da rua
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

  @override
  void dispose() {
    _destController.dispose();
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

  Future<void> _registerRequest() async {
    if (Ride4FreeAuth.token == null) {
      _showMessage(context, 'Inicie sessão no perfil.');
      return;
    }
    try {
      await _api.createPassengerRequest(
        destination: _destController.text,
        passengerCount: 1,
        originLat: (_pickupLatLng ?? _userLocation)?.latitude,
        originLng: (_pickupLatLng ?? _userLocation)?.longitude,
      );
      if (mounted) _showMessage(context, 'Pedido de passageiro registado.');
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const TopTitleBar(title: 'Boleias Encontradas'),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const RouteRow(color: kSuccess, text: 'De: Residencia Universitaria'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Para:', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _destController,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _loading ? null : _search,
                      style: FilledButton.styleFrom(backgroundColor: kSuccess),
                      child: Text(_loading ? '…' : 'Procurar condutores'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _registerRequest,
                      child: const Text('Pedir boleia'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 18),

          // Slider funcional
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Text('Raio de Tolerancia', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${_radiusMeters.toInt()}m', style: const TextStyle(color: kRed, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: Slider(
              value: _radiusMeters,
              min: 100,
              max: 2000,
              divisions: 19,
              label: '${_radiusMeters.toInt()}m',
              onChanged: (v) => setState(() => _radiusMeters = v),
              onChangeEnd: (v) {
                setState(() => _radiusMeters = v);
                if (_drivers.isNotEmpty) _search();
              },
            ),
          ),

          // Mapa ligado ao estado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _pickupLatLng == null
                ? const Text(
              'Toque no mapa para definir o ponto de pickup (ou usa o GPS automaticamente)',
              style: TextStyle(color: kMuted, fontWeight: FontWeight.w600),
            )
                : Text(
              'Pickup definido ✓ (${_pickupLatLng!.latitude.toStringAsFixed(4)}, ${_pickupLatLng!.longitude.toStringAsFixed(4)})',
              style: const TextStyle(color: kSuccess, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),

// Mapa com onTap para pickup
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SizedBox(
              height: 130,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _ConferenceMap(
                  userLocation: _pickupLatLng ?? _userLocation,
                  radiusMeters: _radiusMeters,
                  onTap: (latlng) => setState(() {
                    _pickupLatLng = latlng;
                    _search();
                  }),
                  driverOrigins: _drivers
                      .where((d) => d['origin_lat'] != null)
                      .map((d) => LatLng(
                    (d['origin_lat'] as num).toDouble(),
                    (d['origin_lng'] as num).toDouble(),
                  ))
                      .toList(),
                ),
              ),
            ),
          ),
          // Lista de condutores
          if (_drivers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Procure condutores para o destino acima.', style: TextStyle(color: kMuted)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              itemCount: _drivers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final d = _drivers[i];
                final name = d['driver_name'] as String? ?? '?';
                final seats = d['available_seats']?.toString() ?? '?';
                return RideCard(
                  name: name,
                  car: 'Lugares livres: $seats',
                  rating: '—',
                  distance: d['destination_display'] as String? ?? '',
                  credits: '30',
                );
              },
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: FilledButton(
              onPressed: _registerRequest,
              style: FilledButton.styleFrom(
                backgroundColor: kRed,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Reservar Boleia', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.onUniversityLogout,
    required this.identity,
  });

  final Future<void> Function() onUniversityLogout;
  final UniversityIdentity identity;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = Ride4FreeApi();
  bool _busy = false;

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
        _showMessage(context, 'Sessao universitaria terminada.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopTitleBar(title: 'Perfil'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            children: [
              Text('API: ${Ride4FreeConfig.baseUrl}', style: const TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: widget.identity.photoUrl == null
                      ? null
                      : NetworkImage(widget.identity.photoUrl!),
                  child: widget.identity.photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  widget.identity.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'UP: ${widget.identity.username}',
                  style: const TextStyle(color: kMuted),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _logoutUniversity,
                icon: const Icon(Icons.logout),
                label: const Text('Terminar sessão universitária'),
              ),
              /* 
              const SizedBox(height: 10),
              const SizedBox(height: 16),
              const Divider(),
              const Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF2232FC),
                    child: Text('MA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Miguel Antunes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text('Excelente passageiro', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Center(child: Text('★★★★★', style: TextStyle(fontSize: 44, color: Color(0xFFF3BC41), letterSpacing: 2))),
              const SizedBox(height: 16),
              const TickRow(text: 'Chegou a horas'),
              const TickRow(text: 'Nao sujou o carro'),
              const TickRow(text: 'Foi respeitador'),
              const TickRow(text: 'Boa conversa'),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kSuccess, width: 2),
                  color: const Color(0xFFF8FFF7),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: const Column(
                  children: [
                    Text('RECOMPENSA TOTAL', style: TextStyle(color: kSuccess, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('+50 Pontos', style: TextStyle(color: Color(0xFF22412A), fontWeight: FontWeight.w900, fontSize: 34)),
                    SizedBox(height: 4),
                    Text('Bonus de conduta perfeita aplicado!', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: kRed,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Submeter Avaliacao', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 18),
              const Text('RATE PROFILES', style: TextStyle(color: kRed, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              const ProfileRatingButton(),
              */
            ],
          ),
        ),
      ],
    );
  }
}

class TopTitleBar extends StatelessWidget {
  final String title;
  // ignore: use_key_in_widget_constructors
  const TopTitleBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      width: double.infinity,
      color: kRed,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.arrow_back, color: Colors.white),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
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

  // ignore: use_key_in_widget_constructors
  const RideCard({required this.name, required this.car, required this.rating, required this.distance, required this.credits});

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
              Text(credits, style: const TextStyle(color: kRed, fontWeight: FontWeight.w800, fontSize: 30)),
              const Text('Créditos', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
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

  const ProfileCard({super.key, 
    required this.title,
    required this.subtitle,
    required this.description,
    this.statusLabel,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFFFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kDivider, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: kDarkText, fontWeight: FontWeight.w600)),
          if (statusLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              statusLabel!,
              style: TextStyle(
                color: statusLabel!.startsWith('Disponivel') ? kSuccess : kSuccess,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(onPressed: onAction, child: Text(actionText!)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConferenceMap extends StatefulWidget {
  final LatLng? userLocation;
  final List<LatLng> driverOrigins;
  final double radiusMeters;
  final void Function(LatLng)? onTap; // para o modo condutor

  const _ConferenceMap({
    this.userLocation,
    this.driverOrigins = const [],
    this.radiusMeters = 500,
    this.onTap,
  });

  @override
  State<_ConferenceMap> createState() => _ConferenceMapState();
}

class _ConferenceMapState extends State<_ConferenceMap> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.userLocation ?? const LatLng(41.1496, -8.6109),
        initialZoom: 13,
        onTap: widget.onTap != null ? (_, latlng) => widget.onTap!(latlng) : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.conference_tool',
        ),

        // Círculo de raio à volta do passageiro
        if (widget.userLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.userLocation!,
                radius: widget.radiusMeters,
                useRadiusInMeter: true,
                color: kRed,
                borderColor: kRed,
                borderStrokeWidth: 2,
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            // Marcador do passageiro / posição selecionada
            if (widget.userLocation != null)
              Marker(
                point: widget.userLocation!,
                width: 36,
                height: 36,
                child: const Icon(Icons.my_location, color: kRed, size: 36),
              ),

            // Marcadores dos condutores disponíveis
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
    );
  }
}