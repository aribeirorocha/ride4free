// HTTP client for the Ride4Free API.
// Remote URL: app_test/lib/app_config.dart (set by backend/start.sh)

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:app_test/app_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Bearer token for API calls (local session token from login/register).
class Ride4FreeAuth {
  static String? token;
}

class Ride4FreeConfig {
  Ride4FreeConfig._();
  static const String _overrideBaseUrl = String.fromEnvironment('RIDE4FREE_API_BASE_URL');

  /// Strips trailing slashes so paths like `/users/login` do not become `//users/login`.
  static String normalizeBaseUrl(String url) {
    var s = url.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return normalizeBaseUrl(_overrideBaseUrl);
    }
    if (Ride4FreeAppConfig.useRemoteApi) {
      return normalizeBaseUrl(Ride4FreeAppConfig.apiBaseUrl);
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
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

  Ride4FreeApi({String? baseUrl, http.Client? client})
      : _base = Ride4FreeConfig.normalizeBaseUrl(baseUrl ?? Ride4FreeConfig.baseUrl),
        _client = client ?? http.Client();

  final String _base;

  final http.Client _client;

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    final t = Ride4FreeAuth.token;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Uri _u(String path, [Map<String, String>? query]) {
    final base = Uri.parse(_base.endsWith('/') ? _base : '$_base/');
    final relative = path.startsWith('/') ? path.substring(1) : path;
    final uri = base.resolve(relative);
    return query != null ? uri.replace(queryParameters: query) : uri;
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
    final r = await _client.post(
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
    final r = await _client.post(
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
    final r = await _client.post(_u('/users/logout'), headers: _headers);
    await _jsonOrThrow(r);
    Ride4FreeAuth.token = null;
  }

  Future<Ride4FreeUser> me() async {
    final m = await getUserProfile();
    return Ride4FreeUser(id: m['id'] as int, email: m['email'] as String, name: m['name'] as String);
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final r = await _client.get(_u('/users/me'), headers: _headers);
    return _jsonOrThrow(r);
  }

  Future<void> updateVehicleInfo(String vehicleInfo) async {
    final r = await _client.put(
      _u('/users/me/vehicle'),
      headers: _headers,
      body: jsonEncode({'vehicle_info': vehicleInfo}),
    );
    await _jsonOrThrow(r);
  }

  Future<List<Map<String, dynamic>>> getUserReviews(int userId) async {
    final r = await _client.get(_u('/users/$userId/reviews'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final list = m['reviews'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<({int balance, List<Map<String, dynamic>> transactions})> getCredits() async {
    final r = await _client.get(_u('/users/me/credits'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final txs = (m['transactions'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return (balance: (m['balance'] as num).toInt(), transactions: txs);
  }

  Future<int> createPassengerRequest({
    required String destination,
    int passengerCount = 1,
    double? originLat,
    double? originLng,
    String? originDisplay,
    String? departureTime,
  }) async {
    final r = await _client.post(
      _u('/passenger/requests'),
      headers: _headers,
      body: jsonEncode({
        'destination': destination,
        'passenger_count': passengerCount,
        'origin_lat': ?originLat,
        'origin_lng': ?originLng,
        'origin_display': ?originDisplay,
        'departure_time': ?departureTime,
      }),
    );
    final m = await _jsonOrThrow(r);
    return (m['id'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> listDriversForDestination(
      String destination,{
        double? lat,
        double? lng,
        int radiusM = 500,
  }) async {
    final r = await _client.get(
      _u('/passenger/drivers', {
        'destination': destination,
        if (lat != null) 'lat': '$lat',
        if (lng != null) 'lng': '$lng',
        'radius_m': '$radiusM',
      }),
      headers: _headers,
    );
    final m = await _jsonOrThrow(r);
    final list = m['drivers'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<int> createDriverOffer({
    required String destination,
    required int availableSeats,
    String? departureTime,
    String? description,
    String? vehicleInfo,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
  }) async {
    final r = await _client.post(
      _u('/driver/offers'),
      headers: _headers,
      body: jsonEncode({
        'destination': destination,
        'available_seats': availableSeats,
        'description': description,
        'departure_time': departureTime,
        'vehicle_info': vehicleInfo,
        'origin_lat': ?originLat,
        'origin_lng': ?originLng,
        'destination_lat': ?destinationLat,
        'destination_lng': ?destinationLng,
      }),
    );
    final m = await _jsonOrThrow(r);
    return (m['id'] as num).toInt();
  }

  Future<Map<String, dynamic>> listPassengersForDestination(String destination) async {
    final r = await _client.get(
      _u('/driver/passengers', {'destination': destination}),
      headers: _headers,
    );
    final m = await _jsonOrThrow(r);
    return m;
  }

  Future<List<Map<String, dynamic>>> listAvailableDrivers({String? destination}) async {
    final q = (destination != null && destination.trim().isNotEmpty)
        ? {'destination': destination.trim()}
        : null;
    final r = await _client.get(_u('/community/drivers', q), headers: _headers);
    final m = await _jsonOrThrow(r);
    final list = m['drivers'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listAvailablePassengers({String? destination}) async {
    final q = (destination != null && destination.trim().isNotEmpty)
        ? {'destination': destination.trim()}
        : null;
    final r = await _client.get(_u('/community/passengers', q), headers: _headers);
    final m = await _jsonOrThrow(r);
    final list = m['passengers'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getDatabaseSchema() async {
    final r = await _client.get(_u('/database/schema'), headers: _headers);
    return _jsonOrThrow(r);
  }

  Future<void> bookDriverOffer(int offerId) async {
    final r = await _client.post(
      _u('/bookings/driver-offer'),
      headers: _headers,
      body: jsonEncode({'offer_id': offerId}),
    );
    await _jsonOrThrow(r);
  }

  Future<void> bookPassengerRequest(int requestId) async {
    final r = await _client.post(
      _u('/bookings/passenger-request'),
      headers: _headers,
      body: jsonEncode({'request_id': requestId}),
    );
    await _jsonOrThrow(r);
  }

  Future<({int id, int creditsBalance})> requestJoinRide({
    required int offerId,
    int passengerCount = 1,
    String? originDisplay,
    String? destinationDisplay,
    String? departureTime,
  }) async {
    final r = await _client.post(
      _u('/rides/join-requests'),
      headers: _headers,
      body: jsonEncode({
        'offer_id': offerId,
        'passenger_count': passengerCount,
        'origin_display': ?originDisplay,
        'destination_display': ?destinationDisplay,
        'departure_time': ?departureTime,
      }),
    );
    final m = await _jsonOrThrow(r);
    return (
      id: (m['id'] as num).toInt(),
      creditsBalance: (m['credits_balance'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> listMyPassengerJoinRequests() async {
    final r = await _client.get(_u('/passenger/my-join-requests'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final list = m['requests'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listDriverIncomingJoinRequests() async {
    final r = await _client.get(_u('/driver/incoming-join-requests'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final list = m['requests'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> passengerRespondJoinRequest(int requestId, {required bool accept}) async {
    final r = await _client.post(
      _u('/rides/join-requests/$requestId/passenger-respond'),
      headers: _headers,
      body: jsonEncode({'accept': accept}),
    );
    return _jsonOrThrow(r);
  }

  Future<List<Map<String, dynamic>>> listJoinRequestMessages(int requestId) async {
    final r = await _client.get(_u('/rides/join-requests/$requestId/messages'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final list = m['messages'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> sendJoinRequestMessage(int requestId, String body) async {
    final r = await _client.post(
      _u('/rides/join-requests/$requestId/messages'),
      headers: _headers,
      body: jsonEncode({'body': body}),
    );
    await _jsonOrThrow(r);
  }

  Future<List<Map<String, dynamic>>> listJoinRequestsForOffer(int offerId) async {
    final r = await _client.get(_u('/driver/offers/$offerId/join-requests'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final list = m['requests'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listMyOffersWithPendingRequests() async {
    final r = await _client.get(_u('/driver/my-offers/pending-requests'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final list = m['offers'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> respondJoinRequest(int requestId, {required bool accept}) async {
    final r = await _client.post(
      _u('/rides/join-requests/$requestId/respond'),
      headers: _headers,
      body: jsonEncode({'accept': accept}),
    );
    return _jsonOrThrow(r);
  }

  Future<({Map<String, dynamic>? ride, Map<String, dynamic>? pendingRating})> getActiveRideState() async {
    final r = await _client.get(_u('/rides/active'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final rideJson = m['ride'];
    final ratingJson = m['pending_rating'];
    return (
      ride: rideJson == null ? null : Map<String, dynamic>.from(rideJson as Map),
      pendingRating: ratingJson == null ? null : Map<String, dynamic>.from(ratingJson as Map),
    );
  }

  Future<Map<String, dynamic>> confirmInCar(int rideId) async {
    final r = await _client.post(_u('/rides/active/$rideId/in-car'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final ride = m['ride'];
    if (ride is Map) return Map<String, dynamic>.from(ride);
    return m;
  }

  Future<Map<String, dynamic>> completeRide(int rideId) async {
    final r = await _client.post(_u('/rides/active/$rideId/complete'), headers: _headers);
    return _jsonOrThrow(r);
  }

  Future<List<Map<String, dynamic>>> listRideMessages(int rideId) async {
    final r = await _client.get(_u('/rides/active/$rideId/messages'), headers: _headers);
    final m = await _jsonOrThrow(r);
    final list = m['messages'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> sendRideMessage(int rideId, String body) async {
    final r = await _client.post(
      _u('/rides/active/$rideId/messages'),
      headers: _headers,
      body: jsonEncode({'body': body}),
    );
    await _jsonOrThrow(r);
  }

  Future<void> rateRideParticipant(
    int rideId, {
    int? stars,
    Map<String, int>? criteria,
  }) async {
    final r = await _client.post(
      _u('/rides/active/$rideId/rate'),
      headers: _headers,
      body: jsonEncode({
        if (stars != null) 'stars': stars,
        if (criteria != null) 'criteria': criteria,
      }),
    );
    await _jsonOrThrow(r);
  }
}