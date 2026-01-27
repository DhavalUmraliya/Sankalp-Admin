import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.role,
    this.createdAt,
    this.photoUrl,
    this.metadata,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? role;
  final DateTime? createdAt;
  final String? photoUrl;
  final Map<String, dynamic>? metadata;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['name'] ?? data['displayName'],
      role: data['role'],
      photoUrl: data['photoUrl'] ?? data['profileImage'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      metadata: data,
    );
  }
}
