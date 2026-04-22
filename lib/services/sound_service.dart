/// SoundService stub — audio disabled pending iOS CI fix.
/// Replace this file with a real implementation once the build is stable.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _enabled = true;
  void setEnabled(bool enabled) => _enabled = enabled;

  Future<void> playPop() async {}
  Future<void> playTick() async {}
  Future<void> playDing() async {}
  Future<void> playTada() async {}
  Future<void> playError() async {}
}
