// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';

import 'active_ride_flow.dart' show showRideMessage;
import 'main.dart' show kMuted, kRed, kSuccess, kDivider, TopTitleBar;
import 'ride4free_api.dart';
import 'ride_notification_service.dart';

/// Ecrã dedicado: Pedidos de boleia (passageiro / condutor).
class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> with SingleTickerProviderStateMixin {
  final _api = Ride4FreeApi();
  final _hub = RideNotificationHub.instance;
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
    _hub.addListener(_onHubChanged);
  }

  void _onHubChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant PedidosPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _hub.markPedidosTabSeen();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hub.removeListener(_onHubChanged);
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
      if (mounted) {
        setState(() {
          _passenger = p;
          _driver = d;
        });
        await _hub.refresh();
      }
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
        return 'À espera de confirmação';
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

  Future<void> _openChat(int requestId, {String? lastMessageAt}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => JoinReqestChatSheet(requestId: requestId, api: _api),
    );
    await _hub.markRequestSeen(requestId, lastMessageAt: lastMessageAt);
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
        separatorBuilder: (_, _) => const SizedBox(height: 16),
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
          final lastMsg = (r['last_message_body'] as String?)?.trim();
          final lastMsgAt = r['last_message_at'] as String?;
          final unread = _hub.isRequestUnread(r, isDriverView: isDriver);

          // Lógica de Cores Premium para a Pílula de Estado
          Color statusBgColor = Colors.grey.withOpacity(0.15);
          Color statusTextColor = Colors.grey[700]!;
          if (status == 'confirmed') {
            statusBgColor = kSuccess.withOpacity(0.15);
            statusTextColor = kSuccess;
          } else if (status == 'declined' || status == 'cancelled' || status == 'expired') {
            statusBgColor = kRed.withOpacity(0.15);
            statusTextColor = kRed;
          } else if (status == 'awaiting_passenger') {
            statusBgColor = Colors.amber.withOpacity(0.15);
            statusTextColor = Colors.amber[800]!;
          }

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER: Avatar, Nome e Estado ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(color: kRed.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.person, color: kRed, size: 24),
                        ),
                        if (unread)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: const BoxDecoration(
                              color: kRed,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDriver ? 'Pedido de passageiro' : 'O teu pedido',
                            style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    // Pílula de Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        _statusLabel(status).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: kDivider),
                ),

                // --- BODY: Destino Principal ---
                const Text(
                  'DESTINO',
                  style: TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  dest,
                  style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),

                // --- ZONA DE INFORMAÇÃO EXTRA (Caixa Cinzenta Igual à Comunidade) ---
                if ((origin != null && origin.isNotEmpty) || (dep != null && dep.isNotEmpty))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        if (origin != null && origin.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.my_location, size: 16, color: kMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  origin,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        if (origin != null && origin.isNotEmpty && dep != null && dep.isNotEmpty)
                          const SizedBox(height: 8), // Espaço entre origem e hora
                        if (dep != null && dep.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: kMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Partida: $dep',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                if (lastMsg != null && lastMsg.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: unread ? kRed.withOpacity(0.06) : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                      border: unread ? Border.all(color: kRed.withOpacity(0.2)) : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: unread ? kRed : kMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lastMsg,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: unread ? Colors.black87 : kMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // --- FOOTER: Botões de Ação ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(id, lastMessageAt: lastMsgAt),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Conversar', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: kDivider, width: 1.5), // Borda elegante
                    ),
                  ),
                ),
                
                if (isDriver && status == 'pending') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _driverRespond(id, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: kDivider, width: 1.5),
                          ),
                          child: const Text('Recusar', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: kRed,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _driverRespond(id, true),
                          child: const Text('Aceitar', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (!isDriver && needsConfirm) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _passengerRespond(id, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: kDivider, width: 1.5),
                          ),
                          child: const Text('Recusar', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _passengerRespond(id, true),
                          child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class JoinReqestChatSheet extends StatefulWidget {
  const JoinReqestChatSheet({super.key, required this.requestId, required this.api});

  final int requestId;
  final Ride4FreeApi api;

  @override
  State<JoinReqestChatSheet> createState() => JoinReqestChatSheetState();
}

class JoinReqestChatSheetState extends State<JoinReqestChatSheet> {
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
      final msgs = await widget.api.listJoinRequestMessages(widget.requestId);
      if (mounted) {
        final wasAtBottom = _scrollController.hasClients &&
            _scrollController.position.pixels == _scrollController.position.maxScrollExtent;

        setState(() => _messages = msgs);

        if (msgs.isNotEmpty) {
          final last = msgs.last;
          await RideNotificationHub.instance.markRequestSeen(
            widget.requestId,
            lastMessageAt: last['created_at'] as String?,
          );
        }

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
      await widget.api.sendJoinRequestMessage(widget.requestId, text);
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
              // --- HEADER & DRAG HANDLE ---
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
                      'Mensagens do Pedido',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const Divider(height: 20),
                  ],
                ),
              ),

              // --- LISTA DE MENSAGENS ---
              Expanded(
                child: _messages.isEmpty
                    ? Center(
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

              // --- CAMPO DE INPUT (UBER STYLE) ---
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
class InfoExtraWidget extends StatelessWidget {
  final String? origin;
  final String? dep;

  const InfoExtraWidget({super.key, required this.origin, required this.dep});

  @override
  Widget build(BuildContext context) {
    // Aqui colocas o código da "Zona de Informação Extra" que me enviaste antes
    if ((origin == null || origin!.isEmpty) && (dep == null || dep!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (origin != null && origin!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.my_location, size: 16, color: Color(0xFF7D7D7D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(origin!, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13)),
                ),
              ],
            ),
          if (origin != null && origin!.isNotEmpty && dep != null && dep!.isNotEmpty)
            const SizedBox(height: 8),
          if (dep != null && dep!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF7D7D7D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Partida: $dep', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 13)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}