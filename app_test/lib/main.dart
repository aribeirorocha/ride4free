import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'profile_rating_button.dart';
import 'ride4free_api.dart';

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
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: const [
            SearchRidePage(),
            OfferRidePage(),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 66,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: ''),
          NavigationDestination(icon: Icon(Icons.directions_car), label: ''),
          NavigationDestination(icon: Icon(Icons.person), label: ''),
        ],
      ),
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

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (Ride4FreeAuth.token == null) {
      _showMessage(context, 'Inicie sessão no perfil.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _api.createDriverOffer(
        destination: _destController.text,
        availableSeats: _seats,
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
              const _InputLike(text: 'Residencia Universitaria'),
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
      final list = await _api.listDriversForDestination(_destController.text);
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
      await _api.createPassengerRequest(destination: _destController.text, passengerCount: 1);
      if (mounted) _showMessage(context, 'Pedido de passageiro registado.');
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text('Raio de Tolerancia', style: TextStyle(fontWeight: FontWeight.w700)),
              Spacer(),
              Text('200m', style: TextStyle(color: kRed, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 6, 18, 10),
          child: Slider(value: 0.12, onChanged: null),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SizedBox(
            height: 130,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const _ConferenceMap(),
            ),
          ),
        ),
        Expanded(
          child: _drivers.isEmpty
              ? const Center(child: Text('Procure condutores para o destino acima.', style: TextStyle(color: kMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  itemCount: _drivers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
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
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _api = Ride4FreeApi();
  bool _busy = false;
  Ride4FreeUser? _user;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      final r = await _api.register(email: _email.text, password: _password.text, name: _name.text.isEmpty ? 'Utilizador' : _name.text);
      Ride4FreeAuth.token = r.token;
      setState(() => _user = r.user);
      if (mounted) _showMessage(context, 'Conta criada e sessão iniciada.');
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      final r = await _api.login(email: _email.text, password: _password.text);
      Ride4FreeAuth.token = r.token;
      setState(() => _user = r.user);
      if (mounted) _showMessage(context, 'Sessão iniciada.');
    } catch (e) {
      if (mounted) _showMessage(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await _api.logout();
      setState(() => _user = null);
      if (mounted) _showMessage(context, 'Sessão terminada.');
    } catch (e) {
      Ride4FreeAuth.token = null;
      setState(() => _user = null);
      if (mounted) _showMessage(context, 'Sessão terminada (local).');
    } finally {
      if (mounted) setState(() => _busy = false);
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
              if (_user != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_user!.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(_user!.email, style: const TextStyle(color: kMuted)),
                  trailing: TextButton(onPressed: _busy ? null : _logout, child: const Text('Sair')),
                )
              else ...[
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password (mín. 6)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nome (registo)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _login,
                        style: FilledButton.styleFrom(backgroundColor: kRed),
                        child: Text(_busy ? '…' : 'Entrar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _register,
                        child: Text(_busy ? '…' : 'Registar'),
                      ),
                    ),
                  ],
                ),
              ],
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

class _ConferenceMap extends StatelessWidget {
  const _ConferenceMap();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(41.1496, -8.6109),
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.conference_tool',
        ),
        const MarkerLayer(
          markers: [
            Marker(
              point: LatLng(41.1496, -8.6109),
              width: 36,
              height: 36,
              child: Icon(Icons.location_pin, color: kRed, size: 36),
            ),
          ],
        ),
      ],
    );
  }
}