import 'package:cloud_firestore/cloud_firestore.dart';

class ChantStats {
  const ChantStats({
    required this.totalChantCount,
    required this.todayChantCount,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int totalChantCount;
  final int todayChantCount;
  final int currentStreak;
  final int longestStreak;

  factory ChantStats.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChantStats(
      totalChantCount: data['totalChantCount'] ?? 0,
      todayChantCount: data['todayChantCount'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
    );
  }

  factory ChantStats.empty() {
    return const ChantStats(
      totalChantCount: 0,
      todayChantCount: 0,
      currentStreak: 0,
      longestStreak: 0,
    );
  }
}
