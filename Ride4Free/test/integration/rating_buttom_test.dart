import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Ride4Free/profile_rating_button.dart'; // Ajusta o import
import 'package:Ride4Free/profile_model.dart';

void main() {
  testWidgets('Adicionar novo perfil chama onAddProfile com o nome correto', (WidgetTester tester) async {
    String? addedName;
    
    // 1. Montamos o _RatingSheet com funções mock para testar a integração
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RatingSheet(
          profiles: [],
          avatarBg: (i) => Colors.blue,
          avatarFg: (i) => Colors.white,
          initials: (n) => n[0],
          onAddProfile: (name) => addedName = name,
          onSave: (id, stars) {},
        ),
      ),
    ));

    // 2. Encontramos o TextField e escrevemos um nome
    final textFieldFinder = find.byType(TextField);
    await tester.enterText(textFieldFinder, 'Novo Condutor');
    
    // 3. Clicamos no botão "+ Add"
    final addButtonFinder = find.text('+ Add');
    await tester.tap(addButtonFinder);
    await tester.pump();

    // 4. Verificamos se a callback foi disparada com o nome certo
    expect(addedName, equals('Novo Condutor'));
  });

  testWidgets('Nao adiciona perfil se o nome estiver vazio', (WidgetTester tester) async {
    bool addCalled = false;
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RatingSheet(
          profiles: [],
          avatarBg: (i) => Colors.blue,
          avatarFg: (i) => Colors.white,
          initials: (n) => n[0],
          onAddProfile: (name) => addCalled = true,
          onSave: (id, stars) {},
        ),
      ),
    ));

    // Clicar em adicionar sem escrever nada
    await tester.tap(find.text('+ Add'));
    await tester.pump();

    expect(addCalled, isFalse);
  });
 
}