import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ride4free_api.dart';

/// Tracks unread ride requests/messages and shows local phone notifications.
class RideNotificationHub extends ChangeNotifier {
  RideNotificationHub._();
  static final RideNotificationHub instance = RideNotificationHub._();

  final _api = Ride4FreeApi();
  final _localNotifications = FlutterLocalNotificationsPlugin();
  Timer? _pollTimer;
  bool _initialized = false;
  bool _firstPoll = true;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Last known fingerprint per join-request id (status + last message time).
  final Map<int, String> _fingerprints = {};
  /// Message timestamps the user has already seen (per request).
  final Map<int, String> _seenMessageAt = {};
  /// Request ids the user opened on the Pedidos tab.
  final Set<int> _seenRequestIds = {};

  static const _prefsKey = 'ride_notification_state_v1';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadState();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await _setupLocalNotifications();
    }
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'ride_requests',
        'Pedidos de boleia',
        description: 'Novos pedidos e mensagens de boleia',
        importance: Importance.high,
      ),
    );
  }

  void startPolling() {
    if (Ride4FreeAuth.token == null) return;
    _pollTimer?.cancel();
    refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => refresh());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refresh() async {
    if (Ride4FreeAuth.token == null) {
      _setUnread(0);
      return;
    }
    try {
      final passenger = await _api.listMyPassengerJoinRequests();
      final driver = await _api.listDriverIncomingJoinRequests();
      await _processLists(passenger: passenger, driver: driver);
    } catch (_) {}
  }

  Future<void> _processLists({
    required List<Map<String, dynamic>> passenger,
    required List<Map<String, dynamic>> driver,
  }) async {
    final newAlerts = <RideAlert>[];
    var unread = 0;
    final skipAlerts = _firstPoll;
    if (_firstPoll) _firstPoll = false;

    void checkItem(Map<String, dynamic> r, {required bool isDriverView}) {
      final id = (r['id'] as num).toInt();
      final status = r['status'] as String? ?? '';
      final lastMsgAt = r['last_message_at'] as String?;
      final lastMsgBody = r['last_message_body'] as String?;
      final lastSender = (r['last_message_sender_id'] as num?)?.toInt();
      final passengerId = (r['passenger_user_id'] as num?)?.toInt();
      final driverId = (r['driver_user_id'] as num?)?.toInt();
      final fingerprint = '$status|${lastMsgAt ?? ''}';

      final isNewRequest = isDriverView &&
          status == 'pending' &&
          !_seenRequestIds.contains(id);

      final needsPassengerAction = !isDriverView &&
          r['needs_passenger_confirmation'] == true &&
          !_seenRequestIds.contains(id);

      final messageFromOther = lastSender != null &&
          ((isDriverView && lastSender == passengerId) ||
              (!isDriverView && lastSender == driverId));

      final hasUnreadMessage = messageFromOther &&
          lastMsgAt != null &&
          lastMsgAt.isNotEmpty &&
          _seenMessageAt[id] != lastMsgAt;

      if (isNewRequest || needsPassengerAction || hasUnreadMessage) {
        unread++;
      }

      final prev = _fingerprints[id];
      if (!skipAlerts && prev != null && prev != fingerprint) {
        if (isNewRequest) {
          newAlerts.add(RideAlert.fromRequest(r, isDriver: isDriverView, isMessage: false));
        } else if (hasUnreadMessage && lastMsgBody != null && lastMsgBody.isNotEmpty) {
          newAlerts.add(RideAlert.fromRequest(r, isDriver: isDriverView, isMessage: true, body: lastMsgBody));
        } else if (needsPassengerAction) {
          newAlerts.add(RideAlert.fromRequest(r, isDriver: isDriverView, isMessage: false));
        }
      }

      _fingerprints[id] = fingerprint;
    }

    for (final r in driver) {
      checkItem(r, isDriverView: true);
    }
    for (final r in passenger) {
      checkItem(r, isDriverView: false);
    }

    _setUnread(unread);
    await _persistState();

    if (!skipAlerts) {
      for (final alert in newAlerts) {
        await _showPhoneNotification(alert);
      }
    }
  }

  void _setUnread(int count) {
    if (_unreadCount == count) return;
    _unreadCount = count;
    notifyListeners();
  }

  /// Call when the user opens the Pedidos tab — clears the nav badge.
  Future<void> markPedidosTabSeen() async {
    _seenRequestIds.addAll(_fingerprints.keys);
    for (final entry in _fingerprints.entries) {
      final parts = entry.value.split('|');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        _seenMessageAt[entry.key] = parts[1];
      }
    }
    _setUnread(0);
    await _persistState();
  }

  /// Call when the user opens a request's chat.
  Future<void> markRequestSeen(int requestId, {String? lastMessageAt}) async {
    _seenRequestIds.add(requestId);
    if (lastMessageAt != null && lastMessageAt.isNotEmpty) {
      _seenMessageAt[requestId] = lastMessageAt;
    }
    await refresh();
  }

  bool isRequestUnread(Map<String, dynamic> r, {required bool isDriverView}) {
    final id = (r['id'] as num).toInt();
    final status = r['status'] as String? ?? '';
    final lastMsgAt = r['last_message_at'] as String?;
    final lastSender = (r['last_message_sender_id'] as num?)?.toInt();
    final passengerId = (r['passenger_user_id'] as num?)?.toInt();
    final driverId = (r['driver_user_id'] as num?)?.toInt();
    final messageFromOther = lastSender != null &&
        ((isDriverView && lastSender == passengerId) ||
            (!isDriverView && lastSender == driverId));

    if (isDriverView && status == 'pending' && !_seenRequestIds.contains(id)) {
      return true;
    }
    if (!isDriverView && r['needs_passenger_confirmation'] == true && !_seenRequestIds.contains(id)) {
      return true;
    }
    if (messageFromOther &&
        lastMsgAt != null &&
        lastMsgAt.isNotEmpty &&
        _seenMessageAt[id] != lastMsgAt) {
      return true;
    }
    return false;
  }

  Future<void> _showPhoneNotification(RideAlert alert) async {
    if (kIsWeb) return;
    const androidDetails = AndroidNotificationDetails(
      'ride_requests',
      'Pedidos de boleia',
      channelDescription: 'Novos pedidos e mensagens de boleia',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const iosDetails = DarwinNotificationDetails();
    await _localNotifications.show(
      alert.notificationId,
      alert.title,
      alert.body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      _seenRequestIds
        ..clear()
        ..addAll((m['seen_requests'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()));
      _seenMessageAt.clear();
      final seenMsgs = m['seen_messages'] as Map<String, dynamic>? ?? {};
      seenMsgs.forEach((k, v) => _seenMessageAt[int.parse(k)] = v as String);
      _fingerprints.clear();
      final fps = m['fingerprints'] as Map<String, dynamic>? ?? {};
      fps.forEach((k, v) => _fingerprints[int.parse(k)] = v as String);
    } catch (_) {}
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'seen_requests': _seenRequestIds.toList(),
        'seen_messages': _seenMessageAt.map((k, v) => MapEntry(k.toString(), v)),
        'fingerprints': _fingerprints.map((k, v) => MapEntry(k.toString(), v)),
      }),
    );
  }

  void reset() {
    stopPolling();
    _fingerprints.clear();
    _seenMessageAt.clear();
    _seenRequestIds.clear();
    _firstPoll = true;
    _setUnread(0);
    _initialized = false;
  }
}

class RideAlert {
  RideAlert({
    required this.notificationId,
    required this.title,
    required this.body,
  });

  final int notificationId;
  final String title;
  final String body;

  factory RideAlert.fromRequest(
    Map<String, dynamic> r, {
    required bool isDriver,
    required bool isMessage,
    String? body,
  }) {
    final id = (r['id'] as num).toInt();
    final dest = r['destination_display'] as String? ??
        r['offer_destination'] as String? ??
        'destino';
    if (isMessage) {
      final name = isDriver
          ? (r['passenger_name'] as String? ?? 'Passageiro')
          : (r['driver_name'] as String? ?? 'Condutor');
      return RideAlert(
        notificationId: id + 100000,
        title: 'Nova mensagem — $name',
        body: body ?? '',
      );
    }
    if (isDriver) {
      final passenger = r['passenger_name'] as String? ?? 'Passageiro';
      final preview = (r['last_message_body'] as String?)?.trim();
      return RideAlert(
        notificationId: id,
        title: 'Novo pedido de boleia',
        body: preview != null && preview.isNotEmpty
            ? '$passenger → $dest: $preview'
            : '$passenger pediu boleia para $dest',
      );
    }
    return RideAlert(
      notificationId: id,
      title: 'Atualização do pedido',
      body: 'Confirma a tua boleia para $dest',
    );
  }
}

/// Small red dot overlay for nav icons.
class NotificationDotIcon extends StatelessWidget {
  const NotificationDotIcon({
    super.key,
    required this.icon,
    required this.showDot,
  });

  final IconData icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showDot)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFDF3E45),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
