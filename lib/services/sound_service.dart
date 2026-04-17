import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // On crée une nouvelle instance à la volée qui se détruit toute seule (évite les crashs d'état)
  Future<void> playPop() async {
    try {
      await AudioPlayer().play(AssetSource('sounds/pop.mp3'));
    } catch (e) {
      print("Erreur Pop: $e");
    }
  }

  Future<void> playDing() async {
    try {
      await AudioPlayer().play(AssetSource('sounds/ding.mp3'));
    } catch (e) {
      print("Erreur Ding: $e");
    }
  }

  Future<void> playTada() async {
    try {
      await AudioPlayer().play(AssetSource('sounds/tada.mp3'));
    } catch (e) {
      print("Erreur Tada: $e");
    }
  }
}
