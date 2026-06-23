/// Data model for a guard / field officer.
/// Guards are created on the web platform and stored in Firebase.
/// The mobile app authenticates against these records.
class Guard {
  final String id;
  final String name;
  final String role;
  final String username;
  final String password;
  final double lat;
  final double lon;
  final String status;

  Guard({
    required this.id,
    required this.name,
    required this.role,
    required this.username,
    required this.password,
    required this.lat,
    required this.lon,
    this.status = 'active',
  });

  factory Guard.fromFirestore(String docId, Map<String, dynamic> data) {
    return Guard(
      id: docId,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lon: (data['lon'] as num?)?.toDouble() ?? 0,
      status: data['status'] ?? 'active',
    );
  }
}
