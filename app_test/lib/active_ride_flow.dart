import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'main.dart' show kMuted, kRed, kSuccess, TopTitleBar;
import 'rating_widgets.dart';
import 'ride4free_api.dart';

void showRideMessage(BuildContext context, String text) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  });
}

/// Polls active ride state and opens the ride window when needed.
class ActiveRideCoordinator extends StatefulWidget {
  const ActiveRideCoordinator({super.key, required this.child});

  final Widget child;

  @override
  State<ActiveRideCoordinator> createState() => _ActiveRideCoordinatorState();
}

class _ActiveRideCoordinatorState extends State<ActiveRideCoordinator> {
  final _api = Ride4FreeApi();
  Timer? _timer;
  bool _checking = false;
  bool _showingRating = false;
  int? _dismissedRideId;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (Ride4FreeAuth.token == null || _checking || !mounted) return;
    _checking = true;
    try {
      final state = await _api.getActiveRideState();
      if (!mounted) return;

      if (state.pendingRating != null && !_showingRating) {
        final rideId = (state.pendingRating!['id'] as num).toInt();
        final name = state.pendingRating!['rate_target_name'] as String? ?? 'utilizador';
        _showingRating = true;
        try {
          await _showRatingDialog(rideId: rideId, targetName: name);
        } finally {
          _showingRating = false;
        }
      } else if (state.ride != null) {
        final rideId = (state.ride!['id'] as num).toInt();
        final top = ModalRoute.of(context);
        if (top?.settings.name != ActiveRidePage.routeName && _dismissedRideId != rideId) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              settings: const RouteSettings(name: ActiveRidePage.routeName),
              builder: (_) => ActiveRidePage(initialRide: state.ride!),
            ),
          ).then((_) => _dismissedRideId = rideId);
        }
      }
    } catch (_) {
    } finally {
      _checking = false;
    }
  }

  Future<void> _showRatingDialog({required int rideId, required String targetName}) async {
    if (!mounted) return;
    final submitted = await showStructuredRatingDialog(
      context,
      rideId: rideId,
      targetName: targetName,
      api: _api,
    );
    if (submitted && mounted) {
      showRideMessage(context, 'Obrigado pela avaliação!');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Driver: pending join requests for a published offer.
class DriverRideRequestsPage extends StatefulWidget {
  const DriverRideRequestsPage({super.key, required this.offerId, this.destination});

  final int offerId;
  final String? destination;

  @override
  State<DriverRideRequestsPage> createState() => _DriverRideRequestsPageState();
}

class _DriverRideRequestsPageState extends State<DriverRideRequestsPage> {
  final _api = Ride4FreeApi();
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _api.listJoinRequestsForOffer(widget.offerId);
      if (mounted) setState(() => _requests = rows);
    } catch (e) {
      if (mounted) showRideMessage(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(int requestId, bool accept) async {
    try {
      await _api.respondJoinRequest(requestId, accept: accept);
      if (!mounted) return;
      showRideMessage(context, accept ? 'Passageiro aceite.' : 'Pedido recusado.');
      await _load();
    } on Ride4FreeApiException catch (e) {
      if (!mounted) return;
      String msg = 'Erro.';
      try {
        final body = jsonDecode(e.body);
        msg = body['detail']?.toString() ?? msg;
      } catch (_) {}
      showRideMessage(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopTitleBar(
              title: 'Pedidos de boleia',
              onBack: () => Navigator.pop(context),
            ),
            if (widget.destination != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(widget.destination!, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? const Center(child: Text('Sem pedidos pendentes.', style: TextStyle(color: kMuted)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(18),
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = _requests[i];
                            final name = r['passenger_name'] as String? ?? 'Passageiro';
                            final rating = r['rating_display'] as String? ?? '—';
                            final count = r['passenger_count']?.toString() ?? '1';
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                    Text('⭐ $rating · $count lugar(es)', style: const TextStyle(color: kMuted)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _respond((r['id'] as num).toInt(), false),
                                            child: const Text('Recusar'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(backgroundColor: kRed),
                                            onPressed: () => _respond((r['id'] as num).toInt(), true),
                                            child: const Text('Aceitar'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active ride window: pickup confirmation, chat, complete, rating.
class ActiveRidePage extends StatefulWidget {
  const ActiveRidePage({super.key, required this.initialRide});

  static const routeName = 'ActiveRidePage';

  final Map<String, dynamic> initialRide;

  @override
  State<ActiveRidePage> createState() => _ActiveRidePageState();
}

class _ActiveRidePageState extends State<ActiveRidePage> {
  final _api = Ride4FreeApi();
  final _chatController = TextEditingController();
  late Map<String, dynamic> _ride;
  List<Map<String, dynamic>> _messages = [];
  Timer? _timer;
  bool _busy = false;
  bool _showingRating = false;

  int get _rideId => (_ride['id'] as num).toInt();
  bool get _isDriver => _ride['is_driver'] as bool? ?? false;
  bool get _isPassenger => _ride['is_passenger'] as bool? ?? false;
  String get _status => _ride['status'] as String? ?? 'matched';
  bool get _driverIn => (_ride['driver_in_car'] as num? ?? 0) != 0;
  bool get _passengerIn => (_ride['passenger_in_car'] as num? ?? 0) != 0;
  bool get _inProgress => _status == 'in_progress';
  bool get _myInCar => _isDriver ? _driverIn : _passengerIn;
  bool get _otherInCar => _isDriver ? _passengerIn : _driverIn;

  @override
  void initState() {
    super.initState();
    _ride = Map<String, dynamic>.from(widget.initialRide);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (Ride4FreeAuth.token == null) return;
    try {
      final state = await _api.getActiveRideState();
      if (!mounted) return;
      if (state.ride != null) {
        setState(() => _ride = state.ride!);
      }
      if (_inProgress || _status == 'matched') {
        final msgs = await _api.listRideMessages(_rideId);
        if (mounted) setState(() => _messages = msgs);
      }
      if (state.pendingRating != null && mounted && !_showingRating) {
        final pr = state.pendingRating!;
        _showingRating = true;
        try {
          await _promptRating(
            rideId: (pr['id'] as num).toInt(),
            name: pr['rate_target_name'] as String? ?? 'utilizador',
          );
          if (mounted) Navigator.pop(context);
        } finally {
          _showingRating = false;
        }
      }
    } catch (_) {
      if (!silent && mounted) showRideMessage(context, 'Erro ao atualizar viagem.');
    }
  }

  Future<void> _promptRating({required int rideId, required String name}) async {
    await showStructuredRatingDialog(
      context,
      rideId: rideId,
      targetName: name,
      api: _api,
    );
  }

  Future<void> _confirmInCar() async {
    setState(() => _busy = true);
    try {
      final updated = await _api.confirmInCar(_rideId);
      if (mounted) setState(() => _ride = updated);
      if (mounted) showRideMessage(context, 'Confirmado — à espera do outro participante.');
      await _refresh(silent: true);
    } on Ride4FreeApiException catch (e) {
      if (mounted) showRideMessage(context, e.body);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeRide() async {
    setState(() => _busy = true);
    try {
      await _api.completeRide(_rideId);
      if (mounted) showRideMessage(context, 'Viagem terminada.');
      await _refresh();
    } on Ride4FreeApiException catch (e) {
      if (mounted) showRideMessage(context, e.body);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    try {
      await _api.sendRideMessage(_rideId, text);
      await _refresh(silent: true);
    } catch (e) {
      if (mounted) showRideMessage(context, 'Erro ao enviar mensagem.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest = _ride['destination_display'] as String? ?? '';
    final driverName = _ride['driver_name'] as String? ?? 'Condutor';
    final passengerName = _ride['passenger_name'] as String? ?? 'Passageiro';
    final driverRating = _ride['driver_rating_display'] as String? ?? '—';
    final passengerRating = _ride['passenger_rating_display'] as String? ?? '—';
    final vehicle = _ride['vehicle_display'] as String? ?? 'Veículo';
    final seats = _ride['available_seats']?.toString() ?? '?';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopTitleBar(title: 'Viagem ativa', onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(dest, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  if (_isPassenger) ...[
                    _infoCard('Condutor', driverName, '⭐ $driverRating'),
                    _infoCard('Veículo', vehicle, '🪑 $seats lugares na oferta'),
                  ] else ...[
                    _infoCard('Passageiro', passengerName, '⭐ $passengerRating'),
                  ],
                  const SizedBox(height: 16),
                  _statusCard(),
                  const SizedBox(height: 16),
                  if (!_inProgress && !_myInCar)
                    FilledButton(
                      onPressed: _busy ? null : _confirmInCar,
                      style: FilledButton.styleFrom(backgroundColor: kRed, minimumSize: const Size.fromHeight(52)),
                      child: Text(_isDriver ? 'Passageiro no carro' : 'Estou no carro'),
                    ),
                  if (_myInCar && !_otherInCar)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'À espera que o outro confirme que está no carro…',
                        style: TextStyle(color: kMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (_inProgress) ...[
                    FilledButton(
                      onPressed: _busy ? null : _completeRide,
                      style: FilledButton.styleFrom(backgroundColor: kSuccess, minimumSize: const Size.fromHeight(48)),
                      child: const Text('Terminar viagem'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(minHeight: 120, maxHeight: 220),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final mine = false; // could compare sender id if available
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${m['sender_name']}: ${m['body']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: InputDecoration(
                              hintText: 'Mensagem…',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: kRed)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String title, String subtitle) {
    return Card(
      child: ListTile(
        title: Text(label, style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(subtitle, style: const TextStyle(color: kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    String text;
    Color color;
    if (_inProgress) {
      text = 'Viagem em curso';
      color = kSuccess;
    } else if (_driverIn && _passengerIn) {
      text = 'A iniciar…';
      color = kSuccess;
    } else if (_myInCar) {
      text = 'Aguardar confirmação do outro';
      color = kMuted;
    } else {
      text = 'Confirmem que estão no carro para iniciar';
      color = kRed;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}
