import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_test/profile_rating_button.dart';



Future<void> launchApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ProfileRatingButton(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Rate profiles'));
  await tester.pumpAndSettle();
}

Finder get sheetFinder => find.byType(DraggableScrollableSheet);

Finder get sheetListFinder => find.descendant(
  of: sheetFinder,
  matching: find.byType(ListView),
);

Finder _profileNameInList(String name) => find.descendant(
  of: sheetListFinder,
  matching: find.text(name),
);

Future<void> selectProfile(WidgetTester tester, String name) async {
  final target = _profileNameInList(name);
  await tester.scrollUntilVisible(target, 80, scrollable: sheetListFinder);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> tapStar(WidgetTester tester, String profileName, int starIndex) async {
  final nameTarget = _profileNameInList(profileName);
  await tester.scrollUntilVisible(nameTarget, 80, scrollable: sheetListFinder);
  await tester.pumpAndSettle();

  final profileRow = find.ancestor(
    of: nameTarget,
    matching: find.byType(InkWell),
  ).first;

  final allStarsInRow = find.descendant(
    of: profileRow,
    matching: find.byWidgetPredicate(
          (w) =>
      w is Icon &&
          (w.icon == Icons.star_rounded || w.icon == Icons.star_outline_rounded),
    ),
  );

  await tester.tap(allStarsInRow.at(starIndex - 1));
  await tester.pumpAndSettle();
}

Future<void> tapSheetButton(WidgetTester tester, String label) async {
  // Footer buttons are outside the ListView — scroll the whole sheet.
  final btn = find.descendant(of: sheetFinder, matching: find.text(label));
  // If already visible just tap; otherwise drag the sheet up a bit.
  if (tester.getTopLeft(btn).dy > 700) {
    await tester.drag(sheetFinder, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

void main() {
  group('US3 - Rate Profiles Acceptance Tests (Profile Management)', () {
    testWidgets('PM-1 — Default profiles are displayed on sheet open',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          expect(find.text('Alex Rivera'), findsOneWidget);
          expect(find.text('Sam Chen'), findsOneWidget);
          expect(find.text('Maya Patel'), findsOneWidget);
        });

    testWidgets('PM-2 — User can add a new profile by name via button',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          await tester.enterText(find.byType(TextField).first, 'Jordan Lee');
          await tester.tap(find.text('+ Add'));
          await tester.pumpAndSettle();

          expect(find.text('Jordan Lee'), findsOneWidget);
          final tf = tester.widget<TextField>(find.byType(TextField).first);
          expect(tf.controller?.text, isEmpty);
        });

    testWidgets('PM-3 — Pressing keyboard return also adds the profile',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          await tester.enterText(find.byType(TextField).first, 'Casey Morgan');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();

          expect(find.text('Casey Morgan'), findsOneWidget);
        });

    testWidgets('PM-4 — Empty name input is rejected', (tester) async {
      await launchApp(tester);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('+ Add'));
      await tester.pumpAndSettle();

      expect(find.text('Jordan Lee'), findsNothing);
      expect(find.text('Casey Morgan'), findsNothing);
    });
  });


  group('US3 - Rate Profiles Acceptance Tests (Star rating)', () {
    testWidgets('SR-1 — Selecting a profile and tapping 4th star fills 4 stars',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          await selectProfile(tester, 'Sam Chen');
          await tapStar(tester, 'Sam Chen', 4);

          final samRow = find.ancestor(
            of: _profileNameInList('Sam Chen'),
            matching: find.byType(InkWell),
          ).first;

          expect(find.descendant(of: samRow, matching: find.byIcon(Icons.star_rounded)), findsNWidgets(4));
          expect(find.descendant(of: samRow, matching: find.byIcon(Icons.star_outline_rounded)), findsNWidgets(1));
        });

    testWidgets('SR-2 — Tapping a star on an unselected profile selects it first',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          await tapStar(tester, 'Maya Patel', 3);

          final mayaRow = find.ancestor(
            of: _profileNameInList('Maya Patel'),
            matching: find.byType(InkWell),
          ).first;

          expect(find.descendant(of: mayaRow, matching: find.byIcon(Icons.star_rounded)), findsNWidgets(3));
        });

    testWidgets('SR-3 — Tapping an already-filled star updates the rating',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          await selectProfile(tester, 'Alex Rivera');
          await tapStar(tester, 'Alex Rivera', 3);
          await tapStar(tester, 'Alex Rivera', 2);

          final alexRow = find.ancestor(
            of: _profileNameInList('Alex Rivera'),
            matching: find.byType(InkWell),
          ).first;

          expect(find.descendant(of: alexRow, matching: find.byIcon(Icons.star_rounded)), findsNWidgets(2));
        });

    testWidgets('SR-4 — Switching profile resets picker to that profile saved stars',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          await selectProfile(tester, 'Sam Chen');
          await tapStar(tester, 'Sam Chen', 5);
          await selectProfile(tester, 'Alex Rivera');

          final alexRow = find.ancestor(
            of: _profileNameInList('Alex Rivera'),
            matching: find.byType(InkWell),
          ).first;

          expect(find.descendant(of: alexRow, matching: find.byIcon(Icons.star_rounded)), findsNothing);
        });
  });


  group('US3 - Rate Profiles Acceptance Tests (Save and cancel)', () {
    testWidgets('SC-1 — Save persists the rating and closes the sheet',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          await selectProfile(tester, 'Maya Patel');
          await tapStar(tester, 'Maya Patel', 5);
          await tapSheetButton(tester, 'Save rating');

          expect(find.text('Save rating'), findsNothing);
          expect(find.text('Maya Patel'), findsOneWidget);
        });

    testWidgets('SC-2 — Save with no profile selected shows snackbar',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          await tapSheetButton(tester, 'Save rating');

          expect(find.text('Select a profile first.'), findsOneWidget);
          expect(find.text('Save rating'), findsOneWidget);
        });

    testWidgets('SC-3 — Save with zero stars shows snackbar', (tester) async {
      await launchApp(tester);
      await openSheet(tester);

      await selectProfile(tester, 'Sam Chen');
      await tapSheetButton(tester, 'Save rating');

      expect(find.text('Choose a star rating.'), findsOneWidget);
      expect(find.text('Save rating'), findsOneWidget);
    });

    testWidgets('SC-4 — Cancel closes the sheet without saving', (tester) async {
      await launchApp(tester);
      await openSheet(tester);

      await selectProfile(tester, 'Sam Chen');
      await tapStar(tester, 'Sam Chen', 3);
      await tapSheetButton(tester, 'Cancel');

      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Current ratings'), findsNothing);
    });
  });

  group('US3 - Rate Profiles Acceptance Tests (Summary card)', () {
    testWidgets('SU-1 — Summary card is hidden when no ratings saved',
            (tester) async {
          await launchApp(tester);
          expect(find.text('Current ratings'), findsNothing);
        });

    testWidgets('SU-2 — Summary card appears after first rating is saved',
            (tester) async {
          await launchApp(tester);
          await openSheet(tester);

          await selectProfile(tester, 'Alex Rivera');
          await tapStar(tester, 'Alex Rivera', 2);
          await tapSheetButton(tester, 'Save rating');

          expect(find.text('Current ratings'), findsOneWidget);
          expect(find.text('Alex Rivera'), findsOneWidget);
        });

    testWidgets('SU-3 — Summary card shows only rated profiles', (tester) async {
      await launchApp(tester);

      await openSheet(tester);
      await selectProfile(tester, 'Alex Rivera');
      await tapStar(tester, 'Alex Rivera', 3);
      await tapSheetButton(tester, 'Save rating');

      await openSheet(tester);
      await selectProfile(tester, 'Sam Chen');
      await tapStar(tester, 'Sam Chen', 4);
      await tapSheetButton(tester, 'Save rating');

      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Sam Chen'), findsOneWidget);
      expect(find.text('Maya Patel'), findsNothing);
    });

    testWidgets('SU-4 — Updated rating reflects immediately in summary card',
            (tester) async {
          await launchApp(tester);

          await openSheet(tester);
          await selectProfile(tester, 'Alex Rivera');
          await tapStar(tester, 'Alex Rivera', 2);
          await tapSheetButton(tester, 'Save rating');

          await openSheet(tester);
          await selectProfile(tester, 'Alex Rivera');
          await tapStar(tester, 'Alex Rivera', 4);
          await tapSheetButton(tester, 'Save rating');

          final summaryCard = find.ancestor(
            of: find.text('Current ratings'),
            matching: find.byType(Container),
          ).first;

          final alexInSummary = find.descendant(
            of: summaryCard,
            matching: find.text('Alex Rivera'),
          );

          final summaryRow = find.ancestor(
            of: alexInSummary,
            matching: find.byType(Row),
          ).first;

          expect(
            find.descendant(of: summaryRow, matching: find.byIcon(Icons.star_rounded)),
            findsNWidgets(4),
          );
        });
  });
}