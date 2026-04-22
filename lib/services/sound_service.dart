import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  SoundService._internal() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  void setEnabled(bool enabled) => _enabled = enabled;

  Future<void> _play(String path, {double volume = 1.0}) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(path), volume: volume);
    } catch (e) {
      // Ignore audio errors in production
    }
  }

  Future<void> playPop() => _play('sounds/pop.mp3', volume: 0.6);
  Future<void> playTick() => _play('sounds/pop.mp3', volume: 0.3); // Réutilisation pour l'instant
  Future<void> playDing() => _play('sounds/ding.mp3');
  Future<void> playTada() => _play('sounds/tada.mp3');
  Future<void> playError() => _play('sounds/pop.mp3', volume: 1.0); // Placeholder
}
