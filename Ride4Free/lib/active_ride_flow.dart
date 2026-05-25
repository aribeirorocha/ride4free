// ignore_for_file: deprecated_member_use, unused_element, unused_field

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'main.dart' show HomeShellState, kMuted, kRed, kSuccess, TopTitleBar;
import 'rating_widgets.dart';
import 'ride4free_api.dart';

void showRideMessage(BuildContext context, String text) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  });
}

/// Pops ride screens and selects the Comunidade (home) tab.
void navigateToHomeAfterRide(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  context.findAncestorStateOfType<HomeShellState>()?.goToHomeTab();
}

/// Prevents two rating dialogs (coordinator + active ride page) at once.
bool _rideRatingDialogOpen = false;

Future<bool> promptRideRating({
  required BuildContext context,
  required int rideId,
  required String targetName,
  required Ride4FreeApi api,
}) async {
  if (_rideRatingDialogOpen) return false;
  _rideRatingDialogOpen = true;
  try {
    return await showStructuredRatingDialog(
      context,
      rideId: rideId,
      targetName: targetName,
      api: api,
    );
  } finally {
    _rideRatingDialogOpen = false;
  }
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
    final submitted = await promptRideRating(
      context: context,
      rideId: rideId,
      targetName: targetName,
      api: _api,
    );
    if (submitted && mounted) {
      navigateToHomeAfterRide(context);
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
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
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
          final submitted = await _promptRating(
            rideId: (pr['id'] as num).toInt(),
            name: pr['rate_target_name'] as String? ?? 'utilizador',
          );
          if (submitted && mounted) {
            navigateToHomeAfterRide(context);
            showRideMessage(context, 'Obrigado pela avaliação!');
          }
        } finally {
          _showingRating = false;
        }
      }
    } catch (_) {
      if (!silent && mounted) showRideMessage(context, 'Erro ao atualizar viagem.');
    }
  }

  Future<bool> _promptRating({required int rideId, required String name}) async {
    return promptRideRating(
      context: context,
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

    final canChat = _inProgress || _status == 'matched';
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
                    _infoCard('Veículo', vehicle, ''),
                    _infoCard('Lugares','🪑 $seats lugares','')
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
                      child: Text(_isDriver ? 'Passageiro no carro' : 'Iniciar viagem'),
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
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      
      // A BOLA FLUTUANTE DO CHAT ENTRA AQUI
      floatingActionButton: canChat
          ? FloatingActionButton(
              backgroundColor: kRed,
              shape: const CircleBorder(),
              elevation: 4,
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ActiveRideChatSheet(
                    rideId: _rideId,
                    api: _api,
                  ),
                );
              },
            )
          : null, // Se a viagem já terminou, o botão desaparece
    );
  }

  Widget _infoCard(String label, String title, String subtitle) {
    // 1. Escolher um ícone automaticamente com base na palavra (Condutor, Veículo, etc.)
    IconData getIcon() {
      final l = label.toLowerCase();
      if (l.contains('condutor')) return Icons.person_pin;
      if (l.contains('passageiro')) return Icons.person;
      if (l.contains('veículo')) return Icons.directions_car;
      if (l.contains('lugares')) return Icons.chair_alt;
      return Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Espaço entre cartões
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1), // Borda fina
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Sombra super leve
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 2. O Ícone Circular Profissional
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: kRed.withOpacity(0.1), // Fundo transparente vermelho
              shape: BoxShape.circle,
            ),
            child: Icon(getIcon(), color: kRed, size: 24),
          ),
          const SizedBox(width: 16),
          
          // 3. Os Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: kMuted, 
                    fontSize: 11, 
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5, // Dá um ar mais sofisticado
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title, 
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                // Só mostra o subtítulo se ele existir
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: const TextStyle(
                      color: kMuted, 
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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

class _ActiveRideChatSheet extends StatefulWidget {
  const _ActiveRideChatSheet({required this.rideId, required this.api});

  final int rideId;
  final Ride4FreeApi api;

  @override
  State<_ActiveRideChatSheet> createState() => _ActiveRideChatSheetState();
}

class _ActiveRideChatSheetState extends State<_ActiveRideChatSheet> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Timer? _timer;
  int? _myId;

  @override
  void initState() {
    super.initState();
    _loadMyId();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _loadMyId() async {
    try {
      final user = await widget.api.me();
      if (mounted) setState(() => _myId = user.id);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      // ⚠️ Chama a API da Viagem Ativa (não a dos pedidos!)
      final msgs = await widget.api.listRideMessages(widget.rideId);
      if (mounted) {
        final wasAtBottom = _scrollController.hasClients && 
            _scrollController.position.pixels == _scrollController.position.maxScrollExtent;
        
        setState(() => _messages = msgs);

        if (wasAtBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      // ⚠️ Envia a mensagem para a Viagem Ativa
      await widget.api.sendRideMessage(widget.rideId, text);
      await _refresh();
      _scrollToBottom();
    } catch (e) {
      if (mounted) showRideMessage(context, 'Erro ao enviar mensagem.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chat da Viagem',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const Divider(height: 20),
                  ],
                ),
              ),
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Text('Diz olá! Começa a conversa.', 
                        style: TextStyle(color: kMuted, fontWeight: FontWeight.w500)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final bool isMe = _myId != null && m['sender_user_id'] == _myId;
                          
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? kRed : const Color(0xFFF1F1F1),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      m['sender_name'] ?? 'Utilizador',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ),
                                  Text(
                                    m['body'] ?? '',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isMe ? Colors.white : Colors.black87,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Escreve uma mensagem...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: kRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kRed.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}