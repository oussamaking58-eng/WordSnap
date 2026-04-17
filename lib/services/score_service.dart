import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static final ScoreService _instance = ScoreService._internal();
  factory ScoreService() => _instance;
  ScoreService._internal();

  static const String _bestScoreKey = 'best_score';
  static const String _totalScoreKey = 'total_score';
  static const String _totalGamesKey = 'total_games';
  static const String _streakKey = 'streak';
  static const String _lastPlayedKey = 'last_played';

  int _bestScore = 0;
  int _totalScore = 0;
  int _totalGames = 0;
  int _streak = 0;
  DateTime? _lastPlayed;

  int get bestScore => _bestScore;
  int get totalScore => _totalScore;
  int get totalGames => _totalGames;
  int get streak => _streak;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _bestScore = prefs.getInt(_bestScoreKey) ?? 0;
    _totalScore = prefs.getInt(_totalScoreKey) ?? 0;
    _totalGames = prefs.getInt(_totalGamesKey) ?? 0;
    _streak = prefs.getInt(_streakKey) ?? 0;
    final lastPlayedMs = prefs.getInt(_lastPlayedKey);
    if (lastPlayedMs != null) {
      _lastPlayed = DateTime.fromMillisecondsSinceEpoch(lastPlayedMs);
    }
    _checkStreak();
  }

  void _checkStreak() {
    if (_lastPlayed == null) return;
    final now = DateTime.now();
    final diff = now.difference(_lastPlayed!).inDays;
    if (diff > 1) {
      // Streak cassé
      _streak = 0;
      _save();
    }
  }

  Future<void> saveGame(int score) async {
    final now = DateTime.now();
    _totalGames++;
    _totalScore += score;
    if (score > _bestScore) _bestScore = score;

    // Streak
    if (_lastPlayed == null) {
      _streak = 1;
    } else {
      final diff = now.difference(_lastPlayed!).inDays;
      if (diff == 0) {
        // Même jour — streak inchangé
      } else if (diff == 1) {
        // Jour suivant — streak++
        _streak++;
      } else {
        // Plus d'un jour — streak reset
        _streak = 1;
      }
    }
    _lastPlayed = now;
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestScoreKey, _bestScore);
    await prefs.setInt(_totalScoreKey, _totalScore);
    await prefs.setInt(_totalGamesKey, _totalGames);
    await prefs.setInt(_streakKey, _streak);
    if (_lastPlayed != null) {
      await prefs.setInt(_lastPlayedKey, _lastPlayed!.millisecondsSinceEpoch);
    }
  }
}