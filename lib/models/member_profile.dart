class MemberProfile {
  const MemberProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.associationName,
  });

  final String id;
  final String email;
  final String fullName;
  final String associationName;

  factory MemberProfile.fromSupabaseMap(Map<String, dynamic> map) {
    return MemberProfile(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      associationName: (map['association_name'] ?? '').toString(),
    );
  }
}
