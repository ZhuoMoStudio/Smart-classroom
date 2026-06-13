import 'package:audioplayers/audioplayers.dart';

class AudioEngine {
  static final AudioEngine _instance = AudioEngine._();
  factory AudioEngine() => _instance;
  AudioEngine._();

  final _player = AudioPlayer();
  bool _enabled = true;

  void setEnabled(bool v) => _enabled = v;

  Future<void> _play(String asset) async {
    if (!_enabled) return;
    await _player.play(AssetSource(asset));
  }

  Future<void> playClick() => _play('sounds/click.wav');
  Future<void> playDrawStart() => _play('sounds/draw_start.wav');
  Future<void> playDrawRoll() => _play('sounds/draw_roll.wav');
  Future<void> playDrawResult() => _play('sounds/draw_result.wav');
  Future<void> playTimerEnd() => _play('sounds/timer_end.wav');
  Future<void> playScoreUp() => _play('sounds/score_up.wav');
  Future<void> playScoreDown() => _play('sounds/score_down.wav');
  Future<void> playAddMember() => _play('sounds/add_member.wav');
  Future<void> playDeleteMember() => _play('sounds/delete_member.wav');
  Future<void> playSyncComplete() => _play('sounds/sync_complete.wav');
  Future<void> playSyncFail() => _play('sounds/sync_fail.wav');
}