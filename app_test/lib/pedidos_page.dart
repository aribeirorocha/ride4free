import 'dart:async';

import 'package:flutter/material.dart';

import 'active_ride_flow.dart' show showRideMessage;
import 'main.dart' show kMuted, kRed, kSuccess, TopTitleBar;
import 'ride4free_api.dart';

/// Ecrã dedicado: Pedidos de boleia (passageiro / condutor).
class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> with SingleTickerProviderStateMixin {
  final _api = Ride4FreeApi();
  late final TabController _tabs;
  List<Map<String, dynamic>> _passenger = [];
  List<Map<String, dynamic>> _driver = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (Ride4FreeAuth.token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!silent) setState(() => _loading = true);
    try {
      final p = await _api.listMyPassengerJoinRequests();
      final d = await _api.listDriverIncomingJoinRequests();
      if (mounted) setState(() {
        _passenger = p;
        _driver = d;
      });
    } catch (e) {
      if (mounted && !silent) showRideMessage(context, 'Erro ao carregar pedidos: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'awaiting_passenger':
        return 'À espera da tua confirmação';
      case 'confirmed':
        return 'Confirmado';
      case 'declined':
        return 'Recusado';
      case 'expired':
        return 'Expirado';
      default:
        return status ?? '';
    }
  }

  Future<void> _openChat(int requestId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _JoinRequestChatSheet(requestId: requestId, api: _api),
    );
    await _load(silent: true);
  }

  Future<void> _driverRespond(int requestId, bool accept) async {
    try {
      await _api.respondJoinRequest(requestId, accept: accept);
      if (!mounted) return;
      showRideMessage(context, accept ? 'Passageiro aceite. Aguarda confirmação.' : 'Pedido recusado.');
      await _load();
    } catch (e) {
      if (mounted) showRideMessage(context, '$e');
    }
  }

  Future<void> _passengerRespond(int requestId, bool accept) async {
    try {
      final result = await _api.passengerRespondJoinRequest(requestId, accept: accept);
      if (!mounted) return;
      showRideMessage(context, accept ? 'Lugar confirmado!' : 'Pedido recusado.');
      if (accept && result['active_ride_id'] != null) {
        showRideMessage(context, 'Viagem ativa — consulta o separador principal.');
      }
      await _load();
    } catch (e) {
      if (mounted) showRideMessage(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopTitleBar(title: 'Pedidos de Boleia'),
        TabBar(
          controller: _tabs,
          labelColor: kRed,
          unselectedLabelColor: kMuted,
          indicatorColor: kRed,
          tabs: const [
            Tab(text: 'Os meus pedidos'),
            Tab(text: 'Pedidos recebidos'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _list(_passenger, isDriver: false),
                    _list(_driver, isDriver: true),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _list(List<Map<String, dynamic>> items, {required bool isDriver}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          isDriver ? 'Sem pedidos de passageiros.' : 'Ainda não pediste boleias.',
          style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final r = items[i];
          final id = (r['id'] as num).toInt();
          final dest = r['destination_display'] as String? ?? r['offer_destination'] as String? ?? '—';
          final origin = r['origin_display'] as String?;
          final dep = r['departure_time'] as String? ?? r['offer_departure_time'] as String?;
          final status = r['status'] as String?;
          final name = isDriver
              ? (r['passenger_name'] as String? ?? 'Passageiro')
              : (r['driver_name'] as String? ?? 'Condutor');
          final needsConfirm = r['needs_passenger_confirmation'] == true;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text(dest, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
                  if (origin != null && origin.isNotEmpty)
                    Text('Origem: $origin', style: const TextStyle(fontSize: 12, color: kMuted)),
                  if (dep != null && dep.isNotEmpty)
                    Text('Partida: $dep', style: const TextStyle(fontSize: 12, color: kMuted)),
                  const SizedBox(height: 6),
                  Text(_statusLabel(status),
                      style: TextStyle(
                        color: status == 'confirmed' ? kSuccess : kRed,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openChat(id),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Conversar'),
                  ),
                  if (isDriver && status == 'pending') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _driverRespond(id, false),
                            child: const Text('Recusar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: kRed),
                            onPressed: () => _driverRespond(id, true),
                            child: const Text('Aceitar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!isDriver && needsConfirm) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _passengerRespond(id, false),
                            child: const Text('Recusar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: kSuccess),
                            onPressed: () => _passengerRespond(id, true),
                            child: const Text('Confirmar lugar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JoinRequestChatSheet extends StatefulWidget {
  const _JoinRequestChatSheet({required this.requestId, required this.api});

  final int requestId;
  final Ride4FreeApi api;

  @override
  State<_JoinRequestChatSheet> createState() => _JoinRequestChatSheetState();
}

class _JoinRequestChatSheetState extends State<_JoinRequestChatSheet> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final msgs = await widget.api.listJoinRequestMessages(widget.requestId);
      if (mounted) setState(() => _messages = msgs);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await widget.api.sendJoinRequestMessage(widget.requestId, text);
      await _refresh();
    } catch (e) {
      if (mounted) showRideMessage(context, 'Erro ao enviar mensagem.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        builder: (_, scroll) => Material(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Chat do pedido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${m['sender_name']}: ${m['body']}'),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Mensagem…',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(onPressed: _send, icon: const Icon(Icons.send, color: kRed)),
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
