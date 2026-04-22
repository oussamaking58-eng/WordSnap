import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SeasonService {
  static final SeasonService _instance = SeasonService._internal();
  factory SeasonService() => _instance;
  SeasonService._internal();

  String get currentSeasonId {
    final now = DateTime.now();
    return DateFormat('yyyy_MM').format(now);
  }

  String get currentSeasonName {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now).toUpperCase();
    return "SAISON : $monthName ${now.year}";
  }

  DateTime get seasonEnd {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
  }

  String get timeLeft {
    final remaining = seasonEnd.difference(DateTime.now());
    if (remaining.inDays > 0) {
      return "${remaining.inDays}j restant";
    } else {
      return "${remaining.inHours}h restant";
    }
  }

  // Logic to save score for current season
  Future<void> saveSeasonScore(String userId, String name, int score) async {
    final seasonRef = FirebaseFirestore.instance
        .collection('seasons')
        .doc(currentSeasonId)
        .collection('scores')
        .doc(userId);

    await seasonRef.set({
      'userId': userId,
      'name': name,
      'score': score,
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
