class Profile {
  final int id;
  final String name;
  final String role;
  int stars;

  Profile({
    required this.id,
    required this.name,
    this.role = 'Team member',
    this.stars = 0,
  });
}