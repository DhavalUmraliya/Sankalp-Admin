import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class UsersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AppUser>> getUsers() {
    // Using the default Firestore database instance.
    return _firestore
        .collection('users')
        // Removed orderBy for now to ensure all docs show up even if missing 'createdAt' or index.
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
  }
}
