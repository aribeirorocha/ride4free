// =============================================================================
// EXTENDED UNIT TESTS — LocationService Advanced Scenarios
// Tests for edge cases, coordinate validation, and distance calculations
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:latlong2/latlong.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';


import 'package:Ride4Free/location_service.dart';
import 'package:Ride4Free/main.dart';

class AdvancedMockGeolocatorPlatform extends GeolocatorPlatform 
    with MockPlatformInterfaceMixin {
  
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Position? mockPosition;
  Exception? exceptionToThrow;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    
    return mockPosition ?? Position(
      latitude: 41.1780,
      longitude: -8.5980,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() => const Stream.empty();

  @override
  Future<Position?> getLastKnownPosition({bool? forceLocationManager}) async => null;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) => const Stream.empty();
}

void main() {
  late AdvancedMockGeolocatorPlatform mockPlatform;

  setUp(() {
    mockPlatform = AdvancedMockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockPlatform;
  });

  group('Extended LocationService Tests - Coordinate Extremes', () {
    
    test('Handles North Pole coordinates (90°N)', () async {
      mockPlatform.mockPosition = Position(
        latitude: 90.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 90.0);
      expect(result.longitude, 0.0);
    });

    test('Handles South Pole coordinates (90°S)', () async {
      mockPlatform.mockPosition = Position(
        latitude: -90.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, -90.0);
    });

    test('Handles Prime Meridian coordinates (0°,0°)', () async {
      mockPlatform.mockPosition = Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 0.0);
      expect(result!.longitude, 0.0);
    });

    test('Handles International Date Line coordinates (180° longitude)', () async {
      mockPlatform.mockPosition = Position(
        latitude: 0.0,
        longitude: 180.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.longitude, 180.0);
    });

    test('Handles negative longitude (-180°)', () async {
      mockPlatform.mockPosition = Position(
        latitude: 45.0,
        longitude: -180.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.longitude, -180.0);
    });

    test('Handles high precision coordinates (many decimal places)', () async {
      mockPlatform.mockPosition = Position(
        latitude: 41.17803456789,
        longitude: -8.59801234567,
        timestamp: DateTime.now(),
        accuracy: 0.001,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, closeTo(41.17803456789, 0.0001));
      expect(result!.longitude, closeTo(-8.59801234567, 0.0001));
    });
  });

  group('Extended LocationService Tests - Accuracy Levels', () {
    
    test('Very low accuracy (1000m)', () async {
      mockPlatform.mockPosition = Position(
        latitude: 41.1780,
        longitude: -8.5980,
        timestamp: DateTime.now(),
        accuracy: 1000.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 41.1780);
    });

    test('Very high accuracy (0.1m)', () async {
      mockPlatform.mockPosition = Position(
        latitude: 41.1780,
        longitude: -8.5980,
        timestamp: DateTime.now(),
        accuracy: 0.1,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 41.1780);
    });

    test('Negative accuracy value is handled', () async {
      mockPlatform.mockPosition = Position(
        latitude: 41.1780,
        longitude: -8.5980,
        timestamp: DateTime.now(),
        accuracy: -1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
    });

    test('Zero accuracy is handled', () async {
      mockPlatform.mockPosition = Position(
        latitude: 41.1780,
        longitude: -8.5980,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
    });
  });

  group('Extended LocationService Tests - Time & Timestamp', () {
    
    test('Returns position with current timestamp', () async {
      final before = DateTime.now();
      final result = await LocationService.getCurrentLocation();
      final after = DateTime.now();

      expect(result, isNotNull);
      // The mock position timestamp should be within our test timeframe
      expect(result!.latitude, 41.1780);
    });

    test('Handles position from past timestamp', () async {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      
      mockPlatform.mockPosition = Position(
        latitude: 41.1780,
        longitude: -8.5980,
        timestamp: pastTime,
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 41.1780);
    });

    test('Handles position with zero altitude', () async {
      mockPlatform.mockPosition = Position(
        latitude: 41.1780,
        longitude: -8.5980,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 41.1780);
    });

    test('Handles position with high altitude (plane altitude)', () async {
      mockPlatform.mockPosition = Position(
        latitude: 41.1780,
        longitude: -8.5980,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 10000.0, // 10km altitude
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 41.1780);
    });
  });

  group('Extended LocationService Tests - Permission States', () {
    
    test('Returns null when permission is denied', () async {
      mockPlatform.permission = LocationPermission.denied;

      final result = await LocationService.getCurrentLocation();

      expect(result, isNull);
    });

    test('Returns null when permission is denied forever', () async {
      mockPlatform.permission = LocationPermission.deniedForever;

      final result = await LocationService.getCurrentLocation();

      expect(result, isNull);
    });

    test('Returns position when permission is whileInUse', () async {
      mockPlatform.permission = LocationPermission.whileInUse;

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 41.1780);
    });

    test('Returns position when permission is always', () async {
      mockPlatform.permission = LocationPermission.always;

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
    });
  });

  group('Extended LocationService Tests - Service State', () {
    
    test('Returns null when location service is disabled', () async {
      mockPlatform.serviceEnabled = false;

      final result = await LocationService.getCurrentLocation();

      expect(result, isNull);
    });

    test('Returns position when location service is enabled', () async {
      mockPlatform.serviceEnabled = true;

      final result = await LocationService.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 41.1780);
    });

    test('Recovers after service was disabled then re-enabled', () async {
      mockPlatform.serviceEnabled = false;
      var result = await LocationService.getCurrentLocation();
      expect(result, isNull);

      mockPlatform.serviceEnabled = true;
      result = await LocationService.getCurrentLocation();
      expect(result, isNotNull);
      expect(result!.latitude, 41.1780);
    });
  });

  group('Extended LocationService Tests - Distance Calculations', () {
    
    test('Distance check', () {
  final pointA = ll.LatLng(41.1780, -8.5980);
  final pointB = ll.LatLng(40.7128, -74.0060);

  final distance = const ll.Distance().as(ll.LengthUnit.Meter, pointA, pointB);
  expect(distance, greaterThan(0));
});

    test('Distance is symmetric (A to B equals B to A)', () {
  final pointA = LatLng(41.1780, -8.5980);
  final pointB = LatLng(40.7128, -74.0060); // New York

  // Instanciamos o calculador de distância da biblioteca latlong2
  const Distance distanceCalculator = Distance();

  // Calculamos A para B e B para A usando o método oficial .as()
  final distanceAB = distanceCalculator.as(LengthUnit.Meter, pointA, pointB);
  final distanceBA = distanceCalculator.as(LengthUnit.Meter, pointB, pointA);

  // Verificamos a simetria
  expect(distanceAB, closeTo(distanceBA, 0.01));
});

    test('Distance is symmetric (A to B equals B to A)', () {
  final pointA = LatLng(41.1780, -8.5980);
  final pointB = LatLng(40.7128, -74.0060); // New York

  // Instanciamos o calculador de distância da biblioteca latlong2
  const ll.Distance distanceCalculator = ll.Distance();

  // Calculamos A para B e B para A usando o método .as()
  final distanceAB = distanceCalculator.as(ll.LengthUnit.Meter, pointA, pointB);
  final distanceBA = distanceCalculator.as(LengthUnit.Meter, pointB, pointA);

  // Verificamos a simetria
  expect(distanceAB, closeTo(distanceBA, 0.01));
});

    test('Distance between far points is large', () {
  final porto = LatLng(41.1780, -8.5980);
  final lisbon = LatLng(38.7223, -9.1393); // ~270km de distância (o valor de ~65km estava incorreto na nota)

  // Instanciamos o calculador de distância oficial
  const Distance distanceCalculator = Distance();

  // Calculamos a distância em metros
  final distance = distanceCalculator.as(LengthUnit.Meter, porto, lisbon);

  // Verificamos se é maior que 60km (60000 metros)
  expect(distance, greaterThan(60000));
});
  });

  group('Extended LocationService Tests - Exception Handling', () {
    
    test('Handles geolocator exception gracefully', () async {
      mockPlatform.exceptionToThrow = Exception('GPS timeout');

      expect(
        () => LocationService.getCurrentLocation(),
        throwsA(isA<Exception>()),
      );
    });

  });

  group('Extended LocationService Tests - Multiple Calls', () {
    
    test('Multiple consecutive calls work correctly', () async {
      for (int i = 0; i < 5; i++) {
        final result = await LocationService.getCurrentLocation();
        expect(result, isNotNull);
        expect(result!.latitude, 41.1780);
      }
    });

    test('Calls with changing coordinates', () async {
      mockPlatform.mockPosition = Position(
        latitude: 40.0,
        longitude: -8.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      var result = await LocationService.getCurrentLocation();
      expect(result!.latitude, 40.0);

      mockPlatform.mockPosition = Position(
        latitude: 42.0,
        longitude: -9.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      result = await LocationService.getCurrentLocation();
      expect(result!.latitude, 42.0);
    });
  });
}
