import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'season_service.dart';

class ScoreService {
  static final ScoreService _instance = ScoreService._internal();
  factory ScoreService() => _instance;
  ScoreService._internal();

  static const String _bestScoreKey = 'best_score';
  static const String _totalScoreKey = 'total_score';
  static const String _totalGamesKey = 'total_games';
  static const String _streakKey = 'streak';
  static const String _lastPlayedKey = 'last_played';
  static const String _coinsKey = 'coins';
  static const String _currentLevelKey = 'current_level';
  static const String _freeHintsKey = 'free_hints';
  static const String _infiniteLivesUntilKey = 'infinite_lives_until';

  int _bestScore = 0;
  int _totalScore = 0;
  int _totalGames = 0;
  int _streak = 0;
  int _coins = 300;
  int _currentLevel = 1;
  int _freeHints = 0;
  DateTime? _infiniteLivesUntil;
  DateTime? _lastPlayed;

  int get bestScore => _bestScore;
  int get totalScore => _totalScore;
  int get totalGames => _totalGames;
  int get streak => _streak;
  int get coins => _coins;
  int get currentLevel => _currentLevel;
  int get freeHints => _freeHints;
  bool get hasInfiniteLives => _infiniteLivesUntil != null && _infiniteLivesUntil!.isAfter(DateTime.now());
  String get infiniteLivesRemaining {
    if (!hasInfiniteLives) return "";
    final diff = _infiniteLivesUntil!.difference(DateTime.now());
    return "${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _bestScore = prefs.getInt(_bestScoreKey) ?? 0;
    _totalScore = prefs.getInt(_totalScoreKey) ?? 0;
    _totalGames = prefs.getInt(_totalGamesKey) ?? 0;
    _streak = prefs.getInt(_streakKey) ?? 0;
    _coins = prefs.getInt(_coinsKey) ?? 300;
    _currentLevel = prefs.getInt(_currentLevelKey) ?? 1;
    _freeHints = prefs.getInt(_freeHintsKey) ?? 0;
    
    final infiniteMs = prefs.getInt(_infiniteLivesUntilKey);
    if (infiniteMs != null) {
      _infiniteLivesUntil = DateTime.fromMillisecondsSinceEpoch(infiniteMs);
    }

    final lastPlayedMs = prefs.getInt(_lastPlayedKey);
    if (lastPlayedMs != null) {
      _lastPlayed = DateTime.fromMillisecondsSinceEpoch(lastPlayedMs);
    }
    _checkStreak();
  }

  // --- Boosters ---
  void addFreeHints(int count) {
    _freeHints += count;
    _save();
  }

  bool useFreeHint() {
    if (_freeHints > 0) {
      _freeHints--;
      _save();
      return true;
    }
    return false;
  }

  void addInfiniteLives(Duration duration) {
    final now = DateTime.now();
    if (hasInfiniteLives) {
      _infiniteLivesUntil = _infiniteLivesUntil!.add(duration);
    } else {
      _infiniteLivesUntil = now.add(duration);
    }
    _save();
  }

  void _checkStreak() {
    if (_lastPlayed == null) return;
    final now = DateTime.now();
    final diff = now.difference(_lastPlayed!).inDays;
    if (diff > 1) {
      _streak = 0;
      _save();
    }
  }

  Future<void> saveGame(int score) async {
    final now = DateTime.now();
    _totalGames++;
    _totalScore += score;
    if (score > _bestScore) _bestScore = score;

    if (_lastPlayed == null) {
      _streak = 1;
    } else {
      final diff = now.difference(_lastPlayed!).inDays;
      if (diff == 1) {
        _streak++;
      } else if (diff > 1) {
        _streak = 1;
      }
    }
    _lastPlayed = now;
    await _save();

    // Sync with Firestore for Seasons
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await SeasonService().saveSeasonScore(
        user.uid,
        user.displayName ?? 'Joueur',
        _bestScore,
      );
    }
  }

  // --- Economie ---
  void addCoins(int amount) {
    _coins += amount;
    _save();
  }

  bool spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      _save();
      return true;
    }
    return false;
  }

  // --- Progression (Saga) ---
  void unlockNextLevel() {
    _currentLevel++;
    _save();
  }
  
  void forceSetLevel(int level) {
    _currentLevel = level;
    _save();
  }

  void incrementStreak() {
    _streak++;
    _save();
  }

  void resetStreak() {
    _streak = 0;
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestScoreKey, _bestScore);
    await prefs.setInt(_totalScoreKey, _totalScore);
    await prefs.setInt(_totalGamesKey, _totalGames);
    await prefs.setInt(_streakKey, _streak);
    await prefs.setInt(_coinsKey, _coins);
    await prefs.setInt(_currentLevelKey, _currentLevel);
    await prefs.setInt(_freeHintsKey, _freeHints);
    if (_infiniteLivesUntil != null) {
      await prefs.setInt(_infiniteLivesUntilKey, _infiniteLivesUntil!.millisecondsSinceEpoch);
    }
    if (_lastPlayed != null) {
      await prefs.setInt(_lastPlayedKey, _lastPlayed!.millisecondsSinceEpoch);
    }
  }
}
