import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// 音频与触感反馈引擎 — 统一管理音效和振动
class AudioEngine {
  static final AudioEngine _i = AudioEngine._();
  factory AudioEngine() => _i;
  AudioEngine._();

  final _p = AudioPlayer();
  bool _soundOn = true;
  bool _hapticOn = true;

  void setSoundEnabled(bool v) => _soundOn = v;
  void setHapticEnabled(bool v) => _hapticOn = v;
  void setEnabled(bool v) => _soundOn = v;

  bool get soundEnabled => _soundOn;
  bool get hapticEnabled => _hapticOn;

  // ========== 音频播放 ==========
  Future<void> _play(String a) async {
    if (!_soundOn) return;
    try {
      await _p.play(AssetSource(a));
    } catch (_) {}
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

  // ========== 触感反馈（独立开关） ==========
  void hapticClick() {
    if (!_hapticOn) return;
    HapticFeedback.lightImpact();
  }

  void hapticMedium() {
    if (!_hapticOn) return;
    HapticFeedback.mediumImpact();
  }

  void hapticHeavy() {
    if (!_hapticOn) return;
    HapticFeedback.heavyImpact();
  }

  void hapticSelection() {
    if (!_hapticOn) return;
    HapticFeedback.selectionClick();
  }
}
