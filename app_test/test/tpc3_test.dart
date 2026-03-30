import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_test/main2.dart';
void main(){
    testWidgets('User can tap the ProfileRatingButton',
            (WidgetTester tester) async {
          await tester.pumpWidget(MyApp());
          await tester.pumpAndSettle();

          final buttonFinder = find.byType(ProfileRatingButton);

          expect(buttonFinder, findsOneWidget);

          // Tap the button
          await tester.tap(buttonFinder);
          await tester.pump();

        });
  }