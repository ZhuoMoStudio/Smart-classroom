import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_engine.dart';
import '../services/network_time.dart';
import '../widgets/toast_overlay.dart';

class TimerPanel extends ConsumerStatefulWidget {
  const TimerPanel({super.key});

  @override
  ConsumerState<TimerPanel> createState() => _TimerPanelState();
}

class _TimerPanelState extends ConsumerState<TimerPanel> {
  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncTime() async {
    final netTime = await NetworkTimeService.getNetworkTime();
    if (netTime != null && mounted) {
      setState(() => _currentTime = netTime);
      ToastOverlay.show(context, '时间已同步');
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final minutes = timerState.remainingSeconds ~/ 60;
    final seconds = timerState.remainingSeconds % 60;
    final isLow = timerState.remainingSeconds <= 10 && timerState.remainingSeconds > 0 && timerState.isRunning;

    if (timerState.remainingSeconds == 0 && timerState.totalSeconds > 0 && _wasPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) => AudioEngine().playTimerEnd());
    }
    _wasPlaying = timerState.isRunning && timerState.remainingSeconds > 0;

    return Column(children: [
      GestureDetector(
        onDoubleTap: _syncTime,
        child: Column(children: [
          Text('${_pad(_currentTime.hour)}:${_pad(_currentTime.minute)}:${_pad(_currentTime.second)}',
              style: theme.textTheme.headlineSmall),
          Text('${_currentTime.year}/${_pad(_currentTime.month)}/${_pad(_currentTime.day)} ${_weekday(_currentTime.weekday)}',
              style: theme.textTheme.bodySmall),
        ]),
      ),
      const Divider(),
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(isLow ? 12 : 8),
        decoration: isLow
            ? BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red, width: 2))
            : null,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 1.0, end: isLow ? 1.1 : 1.0),
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Text('${_pad(minutes)}:${_pad(seconds)}',
              style: theme.textTheme.displaySmall?.copyWith(color: isLow ? Colors.red : null, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: settings.timerPresets.map((m) => ActionChip(
            label: Text('${m}′'), onPressed: () => ref.read(timerProvider.notifier).setTimer(m),
          )).toList()),
      const SizedBox(height: 4),
      Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 60, child: TextField(
              decoration: const InputDecoration(labelText: '分钟'),
              keyboardType: TextInputType.number,
              onSubmitted: (v) {
                final m = int.tryParse(v) ?? 0;
                if (m > 0) ref.read(timerProvider.notifier).setTimer(m);
              },
            )),
      ]),
      const SizedBox(height: 4),
      Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: Icon(timerState.isRunning ? Icons.pause : Icons.play_arrow),
          onPressed: () => timerState.isRunning ? ref.read(timerProvider.notifier).pause() : ref.read(timerProvider.notifier).start(),
        ),
        IconButton(icon: const Icon(Icons.stop), onPressed: () => ref.read(timerProvider.notifier).reset()),
      ]),
    ]);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String _weekday(int w) => ['一', '二', '三', '四', '五', '六', '日'][w - 1];
}