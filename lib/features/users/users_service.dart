import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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

  Future<void> addUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Initialize a secondary app instance to create the user without signing out the current admin
      secondaryApp = await Firebase.initializeApp(
        name: 'secondaryUserCreationApp',
        options: Firebase.app().options,
      );

      final auth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Add user details to Firestore
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': name,
        'role': role,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': null,
      });

      // Cleanup
      await secondaryApp.delete();
    } catch (e) {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
      rethrow;
    }
  }
}
