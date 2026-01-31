import 'package:cloud_firestore/cloud_firestore.dart';

class ChantingSession {
  const ChantingSession({
    required this.id,
    required this.mantra,
    required this.completedCount,
    required this.duration,
    required this.status,
    required this.startTime,
  });

  final String id;
  final String mantra;
  final int completedCount;
  final int duration; // in seconds
  final String status;
  final DateTime startTime;

  factory ChantingSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ChantingSession(
      id: doc.id,
      mantra: data['mantra'] ?? data['mantraName'] ?? 'Unknown',
      completedCount: data['completedCount'] ?? data['count'] ?? 0,
      duration: data['duration'] ?? 0,
      status: data['status'] ?? 'Unknown',
      startTime: _parseDateTime(data['startTime']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
