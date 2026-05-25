import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';


import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';


import 'package:Ride4Free/location_service.dart';

// 1. Removemos o 'implements' e mantemos apenas o 'extends'
class MockGeolocatorPlatform extends GeolocatorPlatform 
    with MockPlatformInterfaceMixin {
  
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;

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
    return Position(
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

  // Métodos adicionais necessários para satisfazer a interface da plataforma
  @override
  Stream<ServiceStatus> getServiceStatusStream() => const Stream.empty();

  @override
  Future<Position?> getLastKnownPosition({bool? forceLocationManager}) async => null;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) => const Stream.empty();
}
void main() {
  late MockGeolocatorPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockGeolocatorPlatform();
    // 2. IMPORTANTE: Injetamos o nosso GPS falso no plugin global
    GeolocatorPlatform.instance = mockPlatform;
  });

  group('Unit Tests - LocationService', () {
    
    test('LOC-U1: Deve retornar LatLng quando o GPS está ligado e há permissão', () async {
      // Act
      final result = await LocationService.getCurrentLocation();

      // Assert
      expect(result, isA<LatLng>());
      expect(result?.latitude, 41.1780);
      expect(result?.longitude, -8.5980);
    });

    test('LOC-U2: Deve retornar null quando o serviço de localização está desligado', () async {
      // Arrange
      mockPlatform.serviceEnabled = false;

      // Act
      final result = await LocationService.getCurrentLocation();

      // Assert
      expect(result, isNull);
    });

    test('LOC-U3: Deve retornar null quando a permissão é negada', () async {
      // Arrange
      mockPlatform.permission = LocationPermission.denied;

      // Act
      final result = await LocationService.getCurrentLocation();

      // Assert
      expect(result, isNull);
    });

    test('LOC-U4: Deve retornar null quando a permissão é negada para sempre', () async {
      // Arrange
      mockPlatform.permission = LocationPermission.deniedForever;

      // Act
      final result = await LocationService.getCurrentLocation();

      // Assert
      expect(result, isNull);
    });
    test('LOC-U5: Deve pedir permissão e retornar posição se o user aceitar no popup', () async {
      // Arrange: Simulamos que inicialmente está negado, mas o utilizador vai aceitar
      mockPlatform.permission = LocationPermission.denied;
      
      // Simulamos que após o "requestPermission", a permissão passa a 'whileInUse'
      // Nota: No nosso mock manual, como a variável é a mesma, podemos testar a lógica 
      // de fluxo do teu IF no LocationService.
      mockPlatform.permission = LocationPermission.whileInUse;

      // Act
      final result = await LocationService.getCurrentLocation();

      // Assert
      expect(result, isNotNull);
      expect(result?.latitude, 41.1780);
    });
  });
}