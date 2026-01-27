import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAccessDeniedException implements Exception {
  const AdminAccessDeniedException({
    required this.uid,
    required this.email,
    required this.foundUserDoc,
    required this.role,
  });

  final String uid;
  final String email;
  final bool foundUserDoc;
  final Object? role;
}

class AdminAuthService {
  AdminAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      await _auth.signOut();
      throw FirebaseAuthException(code: 'no-user', message: 'Login failed.');
    }

    final roleInfo = await _getUserRole(uid);
    final isAdmin = roleInfo.role == 'admin';
    if (!isAdmin) {
      await _auth.signOut();
      throw AdminAccessDeniedException(
        uid: uid,
        email: trimmedEmail,
        foundUserDoc: roleInfo.exists,
        role: roleInfo.role,
      );
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return isUidAdmin(uid);
  }

  Future<bool> isUidAdmin(String uid) async {
    final roleInfo = await _getUserRole(uid);
    return roleInfo.role == 'admin';
  }

  Future<_UserRoleInfo> _getUserRole(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    final data = snap.data();
    return _UserRoleInfo(
      exists: snap.exists,
      role: data?['role'],
    );
  }
}

class _UserRoleInfo {
  const _UserRoleInfo({required this.exists, required this.role});

  final bool exists;
  final Object? role;
}

