import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalUsers,
    required this.activeUsersLast7Days,
    required this.totalQuestionsAsked,
    required this.totalSatsangPlayed,
  });

  final int totalUsers;
  final int activeUsersLast7Days;
  final int totalQuestionsAsked;
  final int totalSatsangPlayed;
}

class DashboardMetricsService {
  DashboardMetricsService({FirebaseFirestore? firestore}) : _firestore = firestore;

  // Keep nullable so widget tests can run without Firebase initialization.
  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  // ---- Schema assumptions (adjust here if your DB differs) ----
  static const String usersCollection = 'users';
  static const String questionsCollection = 'questions';
  static const String satsangPlaysCollection = 'satsang_plays';

  /// User "active" signal stored in `users/{uid}`.
  /// Documents missing this field are treated as inactive.
  static const String userLastActiveAtField = 'lastActiveAt';

  Future<DashboardMetrics> fetch() async {
    final now = Timestamp.now();
    final sevenDaysAgo = Timestamp.fromDate(
      DateTime.now().toUtc().subtract(const Duration(days: 7)),
    );

    final results = await Future.wait<int>([
      _count(firestore.collection(usersCollection)),
      _count(
        firestore
            .collection(usersCollection)
            .where(userLastActiveAtField, isGreaterThanOrEqualTo: sevenDaysAgo)
            .where(userLastActiveAtField, isLessThanOrEqualTo: now),
      ),
      _count(firestore.collection(questionsCollection)),
      _count(firestore.collection(satsangPlaysCollection)),
    ]);

    return DashboardMetrics(
      totalUsers: results[0],
      activeUsersLast7Days: results[1],
      totalQuestionsAsked: results[2],
      totalSatsangPlayed: results[3],
    );
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final agg = await query.count().get();
    return agg.count ?? 0;
  }
}

