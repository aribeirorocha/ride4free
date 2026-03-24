import 'package:flutter/material.dart';

void main() => runApp(MyApp());

// ── App ──────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CounterApp(),
    );
  }
}

// ── Counter App ───────────────────────────────────────────────────────────────

class CounterApp extends StatefulWidget {
  @override
  _CounterAppState createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Counter App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pressed the button this many times:'),
            Text(
              '$_counter',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // ← Profile rating widget sits right here
            const ProfileRatingButton(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Profile Model ─────────────────────────────────────────────────────────────

class Profile {
  final int id;
  final String name;
  final String role;
  int stars;

  Profile({required this.id, required this.name, this.role = 'Team member', this.stars = 0});
}

// ── Profile Rating Button ─────────────────────────────────────────────────────

class ProfileRatingButton extends StatefulWidget {
  const ProfileRatingButton({super.key});

  @override
  State<ProfileRatingButton> createState() => _ProfileRatingButtonState();
}

class _ProfileRatingButtonState extends State<ProfileRatingButton> {
  final List<Profile> _profiles = [
    Profile(id: 1, name: 'Alex Rivera', role: 'condutor'),
    Profile(id: 2, name: 'Sam Chen',    role: 'Condutor'),
    Profile(id: 3, name: 'Maya Patel',  role: 'driver'),
  ];
  int _nextId = 4;

  static const _avatarColors = [
    Color(0xFFB5D4F4), Color(0xFFCECBF6), Color(0xFF9FE1CB),
    Color(0xFFFAC775), Color(0xFFF5C4B3), Color(0xFFF4C0D1),
  ];
  static const _avatarTextColors = [
    Color(0xFF0C447C), Color(0xFF3C3489), Color(0xFF085041),
    Color(0xFF633806), Color(0xFF712B13), Color(0xFF72243E),
  ];

  Color _avatarBg(int i) => _avatarColors[i % _avatarColors.length];
  Color _avatarFg(int i) => _avatarTextColors[i % _avatarTextColors.length];

  String _initials(String name) {
    final parts = name.trim().split(' ');
    final letters = parts.map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    return letters.length >= 2 ? letters.substring(0, 2) : letters;
  }

  void _openSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(
        profiles: _profiles,
        avatarBg: _avatarBg,
        avatarFg: _avatarFg,
        initials: _initials,
        onAddProfile: (name) => setState(() {
          _profiles.add(Profile(id: _nextId++, name: name));
        }),
        onSave: (id, stars) => setState(() {
          _profiles.firstWhere((p) => p.id == id).stars = stars;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rated = _profiles.where((p) => p.stars > 0).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trigger button
        GestureDetector(
          onTap: _openSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline_rounded, size: 16),
                SizedBox(width: 8),
                Text('Rate profiles', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),

        // Summary card
        if (rated.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current ratings',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                for (int i = 0; i < _profiles.length; i++)
                  if (_profiles[i].stars > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: _avatarBg(i),
                            child: Text(_initials(_profiles[i].name),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _avatarFg(i))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_profiles[i].name, style: const TextStyle(fontSize: 13))),
                          _StarDisplay(stars: _profiles[i].stars, size: 14),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Rating Sheet ──────────────────────────────────────────────────────────────

class _RatingSheet extends StatefulWidget {
  final List<Profile> profiles;
  final Color Function(int) avatarBg;
  final Color Function(int) avatarFg;
  final String Function(String) initials;
  final void Function(String) onAddProfile;
  final void Function(int, int) onSave;

  const _RatingSheet({
    required this.profiles,
    required this.avatarBg,
    required this.avatarFg,
    required this.initials,
    required this.onAddProfile,
    required this.onSave,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  Profile? _selected;
  int _pendingStars = 0;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _select(Profile p) => setState(() { _selected = p; _pendingStars = p.stars; });

  void _addProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.onAddProfile(name);
    _nameController.clear();
    setState(() {});
  }

  void _save() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a profile first.')));
      return;
    }
    if (_pendingStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a star rating.')));
      return;
    }
    widget.onSave(_selected!.id, _pendingStars);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Choose a profile to rate',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Add profile row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      onSubmitted: (_) => _addProfile(),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'New profile name...',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _addProfile,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('+ Add', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Profile list
            Expanded(
              child: widget.profiles.isEmpty
                  ? const Center(child: Text('No profiles yet.', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                controller: controller,
                itemCount: widget.profiles.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
                itemBuilder: (_, i) {
                  final p = widget.profiles[i];
                  final isSel = _selected?.id == p.id;
                  return InkWell(
                    onTap: () => _select(p),
                    child: Container(
                      color: isSel ? Colors.grey.shade50 : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: widget.avatarBg(i),
                            child: Text(widget.initials(p.name),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: widget.avatarFg(i))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(p.role, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                _StarPicker(
                                  stars: isSel ? _pendingStars : p.stars,
                                  onChanged: (s) { _select(p); setState(() => _pendingStars = s); },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF1A1A2E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save rating'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Star Picker ───────────────────────────────────────────────────────────────

class _StarPicker extends StatelessWidget {
  final int stars;
  final void Function(int) onChanged;
  const _StarPicker({required this.stars, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) => GestureDetector(
        onTap: () => onChanged(i + 1),
        child: Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 18,
            color: i < stars ? const Color(0xFFF5A623) : Colors.grey.shade400,
          ),
        ),
      )),
    );
  }
}

// ── Star Display (read-only) ──────────────────────────────────────────────────

class _StarDisplay extends StatelessWidget {
  final int stars;
  final double size;
  const _StarDisplay({required this.stars, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
        size: size,
        color: i < stars ? const Color(0xFFF5A623) : Colors.grey.shade300,
      )),
    );
  }
}