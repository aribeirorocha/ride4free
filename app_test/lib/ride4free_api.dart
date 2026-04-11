// HTTP client for the local Ride4Free API (SQLite backend).
// Point Ride4FreeConfig.baseUrl at your deployed API when leaving localhost
// (e.g. Firebase + Cloud Run / Cloud Functions).

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// In-memory session token (replace with secure storage + refresh for production).
class Ride4FreeAuth {
  static String? token;
}

class Ride4FreeConfig {
  Ride4FreeConfig._();

  /// Android emulator: use 10.0.2.2 to reach host machine. iOS simulator / desktop / web: localhost.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}

class Ride4FreeApiException implements Exception {
  Ride4FreeApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'Ride4FreeApiException($statusCode): $body';
}

class Ride4FreeUser {
  Ride4FreeUser({required this.id, required this.email, required this.name});
  final int id;
  final String email;
  final String name;

  factory Ride4FreeUser.fromJson(Map<String, dynamic> j) {
    return Ride4FreeUser(
      id: j['id'] as int,
      email: j['email'] as String,
      name: j['name'] as String,
    );
  }
}

class Ride4FreeApi {
  Ride4FreeApi({String? baseUrl}) : _base = baseUrl ?? Ride4FreeConfig.baseUrl;

  final String _base;

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    final t = Ride4FreeAuth.token;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Uri _u(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_base$p').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _jsonOrThrow(http.Response r) async {
    final body = r.body;
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (body.isEmpty) return {};
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw Ride4FreeApiException(r.statusCode, body);
  }

  Future<({Ride4FreeUser user, String token})> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final r = await http.post(
      _u('/users/register'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    final m = await _jsonOrThrow(r);
    final token = m['token'] as String;
    final user = Ride4FreeUser.fromJson(m['user'] as Map<String, dynamic>);
    return (user: user, token: token);
  }

  Future<({Ride4FreeUser user, String token})> login({
    required String email,
    required String password,
  }) async {
    final r = await http.post(
      _u('/users/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final m = await _jsonOrThrow(r);
    final token = m['token'] as String;
    final user = Ride4FreeUser.fromJson(m['user'] as Map<String, dynamic>);
    return (user: user, token: token);
  }

  Future<void> logout() async {
    final r = await http.post(_u('/users/logout'), headers: _headers);
    await _jsonOrThrow(r);
    Ride4FreeAuth.token = null;
  }

  Future<Ride4FreeUser> me() async {
    final r = await http.get(_u('/users/me'), headers: _headers);
    final m = await _jsonOrThrow(r);
    return Ride4FreeUser.fromJson(m);
  }

  Future<void> createPassengerRequest({
    required String destination,
    int passengerCount = 1,
  }) async {
    final r = await http.post(
      _u('/passenger/requests'),
      headers: _headers,
      body: jsonEncode({'destination': destination, 'passenger_count': passengerCount}),
    );
    await _jsonOrThrow(r);
  }

  Future<List<Map<String, dynamic>>> listDriversForDestination(String destination) async {
    final r = await http.get(
      _u('/passenger/drivers', {'destination': destination}),
      headers: _headers,
    );
    final m = await _jsonOrThrow(r);
    final list = m['drivers'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createDriverOffer({required String destination, required int availableSeats}) async {
    final r = await http.post(
      _u('/driver/offers'),
      headers: _headers,
      body: jsonEncode({'destination': destination, 'available_seats': availableSeats}),
    );
    await _jsonOrThrow(r);
  }

  Future<Map<String, dynamic>> listPassengersForDestination(String destination) async {
    final r = await http.get(
      _u('/driver/passengers', {'destination': destination}),
      headers: _headers,
    );
    final m = await _jsonOrThrow(r);
    return m;
  }
}
