import 'package:audioplayers/audioplayers.dart';

class AudioEngine {
  static final AudioEngine _i = AudioEngine._();
  factory AudioEngine() => _i;
  AudioEngine._();
  final _p = AudioPlayer();
  bool _on = true;
  void setEnabled(bool v) => _on = v;
  Future<void> _play(String a) async {
    if (!_on) return;
    await _p.play(AssetSource(a));
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
