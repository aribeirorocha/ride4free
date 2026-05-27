import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:Ride4Free/main.dart'; // Ajusta para o caminho correto do teu main.dart

void main() {
  testWidgets('Verifica se o CircleLayer é renderizado com os parâmetros corretos', (WidgetTester tester) async {
    final testLocation = LatLng(41.1780, -8.5980);
    const testRadius = 500.0;

    // 1. Monta o widget _ConferenceMap
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConferenceMap(
          userLocation: testLocation,
          radiusMeters: testRadius,
        ),
      ),
    ));

    // 2. Procura pelo CircleLayer na árvore de widgets
    // O FlutterMap renderiza internamente os seus filhos
    final circleLayerFinder = find.byType(CircleLayer);
    expect(circleLayerFinder, findsOneWidget);

    // 3. Obtém o widget para verificar as propriedades
    final circleLayer = tester.widget<CircleLayer>(circleLayerFinder);
    
    // Valida se existe pelo menos um círculo
    expect(circleLayer.circles, isNotEmpty);
    
    // Valida as propriedades do círculo
    final circle = circleLayer.circles.first;
    expect(circle.point, equals(testLocation));
    expect(circle.radius, equals(testRadius));
    expect(circle.useRadiusInMeter, isTrue);
  });
}