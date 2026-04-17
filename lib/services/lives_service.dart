import 'package:shared_preferences/shared_preferences.dart';

class LivesService {
  static final LivesService _instance = LivesService._internal();
  factory LivesService() => _instance;
  LivesService._internal();

  static const int maxLives = 5;
  static const int regenMinutes = 30;
  static const String _livesKey = 'lives';
  static const String _lastRegenKey = 'last_regen';

  int _lives = 5;
  DateTime? _lastRegen;

  int get lives => _lives;
  bool get hasLives => _lives > 0;
  bool get isFull => _lives >= maxLives;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lives = prefs.getInt(_livesKey) ?? maxLives;
    final lastRegenMs = prefs.getInt(_lastRegenKey);
    if (lastRegenMs != null) {
      _lastRegen = DateTime.fromMillisecondsSinceEpoch(lastRegenMs);
    }
    await _regenLives();
  }

  Future<void> _regenLives() async {
    if (_lives >= maxLives) return;
    if (_lastRegen == null) {
      _lastRegen = DateTime.now();
      await _save();
      return;
    }
    final now = DateTime.now();
    final diff = now.difference(_lastRegen!).inMinutes;
    final livesToAdd = (diff ~/ regenMinutes).clamp(0, maxLives - _lives);
    if (livesToAdd > 0) {
      _lives = (_lives + livesToAdd).clamp(0, maxLives);
      _lastRegen = now;
      await _save();
    }
  }

  Future<void> consumeLife() async {
    if (_lives > 0) {
      _lives--;
      _lastRegen ??= DateTime.now();
      await _save();
    }
  }

  Future<void> addLife() async {
    if (_lives < maxLives) {
      _lives++;
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_livesKey, _lives);
    if (_lastRegen != null) {
      await prefs.setInt(_lastRegenKey, _lastRegen!.millisecondsSinceEpoch);
    }
  }

  Duration get timeUntilNextLife {
  if (_lives >= maxLives) return Duration.zero;
  if (_lastRegen == null) return Duration(minutes: regenMinutes);
  final elapsedSeconds = DateTime.now().difference(_lastRegen!).inSeconds;
  final remainingSeconds = (regenMinutes * 60) - (elapsedSeconds % (regenMinutes * 60));
  return Duration(seconds: remainingSeconds);
}

 String get timeUntilNextLifeString {
  final duration = timeUntilNextLife;
  if (duration == Duration.zero) return '';
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
}
}