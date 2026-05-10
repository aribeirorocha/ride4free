import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'profile_rating_button.dart';
import 'ride4free_api.dart';
import 'session/university_session_store.dart';
import 'sigarra/sigarra_auth_service.dart';
import 'location_service.dart';

void main() => runApp(const MyApp());

void _showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  final _sessionStore = UniversitySessionStore();
  final _api = Ride4FreeApi();
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
      return UniversityLoginPage(onLoginSuccess: _onLoginSuccess);
    }

    return HomeShell(
      onUniversityLogout: _onUniversityLogout,
      identity: _identity!,
    );
  }
}

class UniversityLoginPage extends StatefulWidget {
  const UniversityLoginPage({super.key, required this.onLoginSuccess});

  final Future<void> Function(UniversityIdentity identity) onLoginSuccess;

  @override
  State<UniversityLoginPage> createState() => _UniversityLoginPageState();
}

class _UniversityLoginPageState extends State<UniversityLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = SigarraAuthService();
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
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Numero mecanografico / utilizador',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
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
  State<CommunityBoardPage> createState() => _CommunityBoardPageState();
}

class _CommunityBoardPageState extends State<CommunityBoardPage> {
  final _api = Ride4FreeApi();
  int _section = 0; // 0 = drivers, 1 = passengers, 2 = database
  bool _loading = false;
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _passengers = [];
  Map<String, dynamic>? _schema;

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
        const _TopTitleBar(title: 'Comunidade Ride4Free'),
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 30, 5, 10),
          child: Column(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, icon: Icon(Icons.drive_eta), label: Text('Condutores')),
                  ButtonSegment(value: 1, icon: Icon(Icons.people), label: Text('Passageiros')),
                  ButtonSegment(value: 2, icon: Icon(Icons.storage), label: Text('BD')),
                ],
                selected: {_section},
                onSelectionChanged: (selection) {
                  setState(() => _section = selection.first);
                  _loadSection();
                },
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _loading ? null : _loadSection,
                style: FilledButton.styleFrom(backgroundColor: kRed),
                child: Text(_loading ? 'A carregar…' : 'Atualizar secao'),
              ),
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
          child: Text('Sem condutores disponiveis. Carregue em "Atualizar secao".', style: TextStyle(color: kMuted)),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        itemCount: _drivers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final d = _drivers[i];
          return _ProfileCard(
            title: d['driver_name'] as String? ?? 'Condutor',
            subtitle: d['driver_email'] as String? ?? '',
            description: d['profile_description'] as String? ?? 'Sem descricao.',
            statusLabel: (d['booked'] as bool? ?? false)
                ? 'Reservado por ${d['booked_by_name'] ?? 'utilizador'}'
                : 'Disponivel',
            actionText: (d['booked'] as bool? ?? false) ? null : 'Reservar boleia',
            onAction: (d['booked'] as bool? ?? false)
                ? null
                : () => _bookDriver((d['id'] as num).toInt()),
          );
        },
      );
    }

    if (_section == 1) {
      if (_passengers.isEmpty) {
        return const Center(
          child: Text('Sem passageiros disponiveis. Carregue em "Atualizar secao".', style: TextStyle(color: kMuted)),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        itemCount: _passengers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final p = _passengers[i];
          return _ProfileCard(
            title: p['passenger_name'] as String? ?? 'Passageiro',
            subtitle: p['passenger_email'] as String? ?? '',
            description: p['profile_description'] as String? ?? 'Sem descricao.',
            statusLabel: (p['booked'] as bool? ?? false)
                ? 'Reservado por ${p['booked_by_name'] ?? 'utilizador'}'
                : 'Disponivel',
            actionText: (p['booked'] as bool? ?? false) ? null : 'Reservar passageiro',
            onAction: (p['booked'] as bool? ?? false)
                ? null
                : () => _bookPassenger((p['id'] as num).toInt()),
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
    setState(() => _busy = true);
    try {
      await _api.createDriverOffer(
        destination: _destController.text,
        availableSeats: _seats,
        originLat: _originLatLng?.latitude,
        originLng: _originLatLng?.longitude,
        destinationLat: _destinationLatLng?.latitude,
        destinationLng: _destinationLatLng?.longitude,
      );
      if (mounted) _showMessage(context, 'Viagem publicada (API local).');
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
        const _TopTitleBar(title: 'Oferecer Boleia'),
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
              _label('DESTINO'),
              TextField(
                controller: _destController,
                decoration: _fieldDecoration(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('HORA'),
                        const _InputLike(text: '08:15'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('LUGARES'),
                        _SeatPicker(
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
              _RewardPanel(valid: canPublish, rewardText: '+${_seats * 10} Creditos'),
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

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E2E2), width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E2E2), width: 2)),
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
          const _TopTitleBar(title: 'Boleias Encontradas'),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _RouteRow(color: kSuccess, text: 'De: Residencia Universitaria'),
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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final d = _drivers[i];
                final name = d['driver_name'] as String? ?? '?';
                final seats = d['available_seats']?.toString() ?? '?';
                return _RideCard(
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
        const _TopTitleBar(title: 'Avaliar Passageiro'),
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
              const _TickRow(text: 'Chegou a horas'),
              const _TickRow(text: 'Nao sujou o carro'),
              const _TickRow(text: 'Foi respeitador'),
              const _TickRow(text: 'Boa conversa'),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _TopTitleBar extends StatelessWidget {
  final String title;
  const _TopTitleBar({required this.title});

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

class _InputLike extends StatelessWidget {
  final String text;
  const _InputLike({required this.text});

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

class _SeatPicker extends StatelessWidget {
  final int seats;
  final VoidCallback onDec;
  final VoidCallback onInc;

  const _SeatPicker({required this.seats, required this.onDec, required this.onInc});

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

class _RewardPanel extends StatelessWidget {
  final bool valid;
  final String rewardText;
  const _RewardPanel({required this.valid, required this.rewardText});

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
            Text('Indique pelo menos 1 lugar disponivel para ganhar creditos.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
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

class _RouteRow extends StatelessWidget {
  final Color color;
  final String text;
  const _RouteRow({required this.color, required this.text});

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

class _RideCard extends StatelessWidget {
  final String name;
  final String car;
  final String rating;
  final String distance;
  final String credits;

  const _RideCard({required this.name, required this.car, required this.rating, required this.distance, required this.credits});

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
              const Text('Creditos', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TickRow extends StatelessWidget {
  final String text;
  const _TickRow({required this.text});

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

class _ProfileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String? statusLabel;
  final String? actionText;
  final VoidCallback? onAction;

  const _ProfileCard({
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
          Text(subtitle, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
          if (statusLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              statusLabel!,
              style: TextStyle(
                color: statusLabel!.startsWith('Disponivel') ? kSuccess : kRed,
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
                color: kRed.withOpacity(0.1),
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