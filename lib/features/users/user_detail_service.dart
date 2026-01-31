import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/chant_stats.dart';
import 'models/chanting_session.dart';

class UserDetailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch chant stats for a user from users/{uid}/backup/stats
  Future<ChantStats> getChantStats(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('backup')
          .doc('stats')
          .get();

      if (doc.exists) {
        return ChantStats.fromFirestore(doc);
      }
      return ChantStats.empty();
    } catch (e) {
      print('Error fetching chant stats: $e');
      return ChantStats.empty();
    }
  }

  /// Fetch recent chanting sessions for a user
  /// From users/{uid}/sessions, ordered by startTime desc, limit 10
  Stream<List<ChantingSession>> getRecentSessions(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('startTime', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChantingSession.fromFirestore(doc))
              .toList();
        });
  }

  /// Block or unblock a user
  Future<void> updateAccountStatus(String uid, String status) async {
    await _firestore.collection('users').doc(uid).update({
      'accountStatus': status,
    });
  }

  /// Reset user's streak (admin action)
  Future<void> resetStreak(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('backup')
        .doc('stats')
        .update({'currentStreak': 0});
  }
}
