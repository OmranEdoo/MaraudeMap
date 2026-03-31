enum UserStatus { active, pending, rejected }

class User {
  final String id;
  final String email;
  final String? associationName;
  final UserStatus status;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.associationName,
    required this.status,
    required this.createdAt,
  });
}
