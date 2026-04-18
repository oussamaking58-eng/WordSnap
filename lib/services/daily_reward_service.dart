import 'package:shared_preferences/shared_preferences.dart';
import 'score_service.dart';

enum RewardType { coins, hints, infiniteLives, mystery }

class DailyReward {
  final RewardType type;
  final int value;
  final String label;

  DailyReward(this.type, this.value, this.label);
}

class DailyRewardService {
  static final DailyRewardService _instance = DailyRewardService._internal();
  factory DailyRewardService() => _instance;
  DailyRewardService._internal();

  static const String _lastClaimKey = 'daily_last_claim';
  static const String _currentDayKey = 'daily_current_day';

  int _currentDay = 1;
  DateTime? _lastClaimDate;

  int get currentDay => _currentDay;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentDay = prefs.getInt(_currentDayKey) ?? 1;
    final lastMs = prefs.getInt(_lastClaimKey);
    if (lastMs != null) {
      _lastClaimDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
    _applyPenaltyIfNeeded();
  }

  void _applyPenaltyIfNeeded() {
    if (_lastClaimDate == null) return;
    final now = DateTime.now();
    final diff = now.difference(_lastClaimDate!).inDays;

    if (diff > 7) {
      // Plus d'une semaine d'absence -> Reset à 1
      _currentDay = 1;
    } else if (diff >= 3) {
      // Entre 3 et 7 jours d'absence -> Recule de 3 jours
      _currentDay = (_currentDay - 3).clamp(1, 30);
    }
    _save();
  }

  bool canClaimToday() {
    if (_lastClaimDate == null) return true;
    final now = DateTime.now();
    // On compare juste la date sans l'heure
    return _lastClaimDate!.year != now.year || 
           _lastClaimDate!.month != now.month || 
           _lastClaimDate!.day != now.day;
  }

  void claimReward() {
    if (!canClaimToday()) return;

    final reward = getRewardForDay(_currentDay);
    final scoreService = ScoreService();

    switch (reward.type) {
      case RewardType.coins:
        scoreService.addCoins(reward.value);
        break;
      case RewardType.hints:
        scoreService.addFreeHints(reward.value);
        break;
      case RewardType.infiniteLives:
        scoreService.addInfiniteLives(Duration(minutes: reward.value));
        break;
      case RewardType.mystery:
        scoreService.addCoins(500); // Mystère simple pour l'instant
        break;
    }

    _lastClaimDate = DateTime.now();
    _currentDay = (_currentDay % 30) + 1; // Cycle de 30 jours
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentDayKey, _currentDay);
    if (_lastClaimDate != null) {
      await prefs.setInt(_lastClaimKey, _lastClaimDate!.millisecondsSinceEpoch);
    }
  }

  DailyReward getRewardForDay(int day) {
    if (day % 7 == 0) return DailyReward(RewardType.mystery, 0, "Cadeau Mystère");
    if (day % 5 == 0) return DailyReward(RewardType.infiniteLives, 30, "30 min de vies");
    if (day % 3 == 0) return DailyReward(RewardType.hints, 1, "1 Indice");
    
    // Calcul de pièces arrondi (ex: 20, 30, 40...)
    int baseCoins = 20 + ((day - 1) * 5);
    int roundedCoins = (baseCoins / 10).round() * 10;
    if (roundedCoins < 20) roundedCoins = 20;

    return DailyReward(RewardType.coins, roundedCoins, "$roundedCoins 🪙");
  }
}
