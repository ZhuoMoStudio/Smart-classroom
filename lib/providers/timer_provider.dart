import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerState {
  final int remainingSeconds;
  final bool isRunning;
  final int totalSeconds;

  const TimerState({this.remainingSeconds = 0, this.isRunning = false, this.totalSeconds = 0});

  TimerState copyWith({int? remainingSeconds, bool? isRunning, int? totalSeconds}) =>
      TimerState(
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        isRunning: isRunning ?? this.isRunning,
        totalSeconds: totalSeconds ?? this.totalSeconds,
      );
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;

  TimerNotifier() : super(const TimerState());

  void setTimer(int minutes) {
    _timer?.cancel();
    state = state.copyWith(remainingSeconds: minutes * 60, totalSeconds: minutes * 60, isRunning: false);
  }

  void start() {
    if (state.remainingSeconds <= 0) {
      if (state.totalSeconds > 0) state = state.copyWith(remainingSeconds: state.totalSeconds);
      else return;
    }
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newSec = state.remainingSeconds - 1;
      if (newSec <= 0) {
        timer.cancel();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);
      } else {
        state = state.copyWith(remainingSeconds: newSec);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = const TimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) => TimerNotifier());