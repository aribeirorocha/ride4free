import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Ride4Free/main.dart'; // Ajusta para o teu caminho
import 'package:Ride4Free/ride4free_api.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Gera o mock para a API se ainda não tiveres
@GenerateMocks([Ride4FreeApi])
import 'mock_listview_test.mocks.dart';

void main() {
  testWidgets('ListView exibe RideCard com dados do motorista', (WidgetTester tester) async {
    // 1. Dados de teste mockados
    final mockDrivers = [
      {
        'id': 1,
        'driver_name': 'André Condutor',
        'available_seats': 3,
        'rating_display': '4.8',
        'destination_display': 'FEUP'
      }
    ];

    // 2. Monta o widget num contexto que suporte RideCard
    // Nota: Como o ListView está dentro de um StatefulWidget, 
    // testamos o componente RideCard isoladamente para garantir precisão.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RideCard(
            name: mockDrivers[0]['driver_name'] as String,
            car: 'Lugares livres: ${mockDrivers[0]['available_seats']}',
            rating: mockDrivers[0]['rating_display'] as String,
            distance: mockDrivers[0]['destination_display'] as String,
            credits: '−5',
            onReserve: () {},
          ),
        ),
      ),
    );

    // 3. Verifica se os textos aparecem corretamente
    expect(find.text('André Condutor'), findsOneWidget);
    expect(find.text('Lugares livres: 3 - ⭐ 4.8'), findsOneWidget);
    expect(find.text('📍 a FEUP de si'), findsOneWidget);
    expect(find.text('−5'), findsOneWidget);
    expect(find.text('Reservar Boleia'), findsOneWidget);
  });

  testWidgets('Botão Reservar chama a função onReserve', (WidgetTester tester) async {
    bool reservaChamada = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RideCard(
            name: 'Teste',
            car: 'Carro',
            rating: '5.0',
            distance: '1km',
            credits: '−5',
            onReserve: () => reservaChamada = true,
          ),
        ),
      ),
    );

    // Clica no botão
    await tester.tap(find.text('Reservar Boleia'));
    await tester.pump();

    // Valida se a função foi disparada
    expect(reservaChamada, isTrue);
  });
}