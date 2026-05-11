//US3 AINDA NÃO ESTÁ IMPLEMENTADO
// ignore_for_file: file_names
/* import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';



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


// Classe temporária para o Mock
class MockProfile {
  final String name;
  int stars;
  MockProfile(this.name, {this.stars = 0});
}

class ProfileRatingButton extends StatefulWidget {
  const ProfileRatingButton({super.key});

  @override
  State<ProfileRatingButton> createState() => _ProfileRatingButtonState();
}

class _ProfileRatingButtonState extends State<ProfileRatingButton> {
  // Lista que guarda os perfis que já foram avaliados e guardados (para o Summary Card)
  List<MockProfile> savedProfiles = [];

  void _openRatingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _RatingSheet(
          onSave: (profileName, stars) {
            setState(() {
              // Atualiza as estrelas se já existir, senão adiciona à lista do Summary Card
              final existing = savedProfiles.where((p) => p.name == profileName).toList();
              if (existing.isNotEmpty) {
                existing.first.stars = stars;
              } else {
                savedProfiles.add(MockProfile(profileName, stars: stars));
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: _openRatingSheet,
          child: const Text('Rate profiles'),
        ),
        const SizedBox(height: 20),
        
        // SU-2, SU-3, SU-4: Summary Card aparece apenas quando há avaliações guardadas
        if (savedProfiles.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200], // Fundo para simular o Card
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current ratings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...savedProfiles.map((p) => Row(
                  children: [
                    Text(p.name),
                    const SizedBox(width: 10),
                    // Desenha as estrelas no modo só de leitura
                    ...List.generate(5, (i) => Icon(
                      i < p.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: Colors.amber,
                    )),
                  ],
                )),
              ],
            ),
          ),
        ]
      ],
    );
  }
}

// O conteúdo do Bottom Sheet
class _RatingSheet extends StatefulWidget {
  final Function(String, int) onSave;
  const _RatingSheet({required this.onSave});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  final TextEditingController _nameController = TextEditingController();
  
  // PM-1: Perfis por defeito
  List<MockProfile> sheetProfiles = [
    MockProfile('Alex Rivera'),
    MockProfile('Sam Chen'),
    MockProfile('Maya Patel'),
  ];
  
  String? selectedProfile;

  // Lógica para o botão "+ Add" e "Enter" no teclado
  void _addProfile() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        sheetProfiles.add(MockProfile(name));
        _nameController.clear();
      });
    }
  }

  void _save() {
    // SC-2: Validação de perfil
    if (selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a profile first.')));
      return;
    }
    
    final profile = sheetProfiles.firstWhere((p) => p.name == selectedProfile);
    
    // SC-3: Validação de estrelas
    if (profile.stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a star rating.')));
      return;
    }
    
    // SC-1: Sucesso
    widget.onSave(profile.name, profile.stars);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // PM-2 e PM-3: Input de novos perfis
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Add new profile...'),
                      onSubmitted: (_) => _addProfile(),
                    ),
                  ),
                  TextButton(
                    onPressed: _addProfile,
                    child: const Text('+ Add'),
                  )
                ],
              ),
              const SizedBox(height: 10),
              
              // Lista interativa
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: sheetProfiles.length,
                  itemBuilder: (context, index) {
                    final p = sheetProfiles[index];
                    final isSelected = p.name == selectedProfile;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedProfile = p.name;
                        });
                      },
                      child: Container(
                        color: isSelected ? Colors.blue.withAlpha((0.1 * 255).toInt()) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            // SR-1, SR-2, SR-3: Lógica das estrelas interativas
                            Row(
                              children: List.generate(5, (starIndex) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedProfile = p.name;
                                      p.stars = starIndex + 1;
                                    });
                                  },
                                  child: Icon(
                                    starIndex < p.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: Colors.amber,
                                  ),
                                );
                              }),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // SC-4 e SC-1: Botões de ação do Footer
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save rating'),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
