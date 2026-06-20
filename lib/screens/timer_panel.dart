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
  DateTime _now = DateTime.now();
  Timer? _ct; bool _wp = false;

  @override
  void initState() { super.initState(); _ct = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => _now = DateTime.now()); }); }
  @override
  void dispose() { _ct?.cancel(); super.dispose(); }

  Future<void> _sync() async { final nt = await NetworkTimeService.getNetworkTime(); if (nt != null && mounted) { setState(() => _now = nt); ToastOverlay.show(context, '时间已同步'); } }

  @override
  Widget build(BuildContext ctx) {
    final ts = ref.watch(timerProvider); final ss = ref.watch(settingsProvider); final t = Theme.of(ctx);
    final min = ts.remainingSeconds ~/ 60; final sec = ts.remainingSeconds % 60;
    final lo = ts.remainingSeconds <= 10 && ts.remainingSeconds > 0 && ts.isRunning;

    if (ts.remainingSeconds == 0 && ts.totalSeconds > 0 && _wp) { WidgetsBinding.instance.addPostFrameCallback((_) => AudioEngine().playTimerEnd()); }
    _wp = ts.isRunning && ts.remainingSeconds > 0;

    return Column(children: [
      GestureDetector(onDoubleTap: _sync, child: Column(children: [
        Text('${_p(_now.hour)}:${_p(_now.minute)}:${_p(_now.second)}', style: t.textTheme.headlineSmall),
        Text('${_now.year}/${_p(_now.month)}/${_p(_now.day)} ${_wd(_now.weekday)}', style: t.textTheme.bodySmall),
      ])),
      const Divider(),
      AnimatedContainer(duration: const Duration(milliseconds: 300), padding: EdgeInsets.all(lo ? 12 : 8),
        decoration: lo ? BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red, width: 2)) : null,
        child: TweenAnimationBuilder<double>(duration: const Duration(milliseconds: 500), tween: Tween(begin: 1.0, end: lo ? 1.1 : 1.0),
          builder: (_, s, c) => Transform.scale(scale: s, child: c),
          child: Text('${_p(min)}:${_p(sec)}', style: t.textTheme.displaySmall?.copyWith(color: lo ? Colors.red : null, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: ss.timerPresets.map((m) => ActionChip(label: Text('${m}′'), onPressed: () => ref.read(timerProvider.notifier).setTimer(m))).toList()),
      const SizedBox(height: 4),
      Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 60, child: TextField(decoration: const InputDecoration(labelText: '分钟'), keyboardType: TextInputType.number,
            onSubmitted: (v) { final m = int.tryParse(v) ?? 0; if (m > 0) ref.read(timerProvider.notifier).setTimer(m); })),
      ]),
      const SizedBox(height: 4),
      Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: Icon(ts.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () => ts.isRunning ? ref.read(timerProvider.notifier).pause() : ref.read(timerProvider.notifier).start()),
        IconButton(icon: const Icon(Icons.stop), onPressed: () => ref.read(timerProvider.notifier).reset()),
      ]),
    ]);
  }

  String _p(int n) => n.toString().padLeft(2, '0');
  String _wd(int w) => ['一','二','三','四','五','六','日'][w - 1];
}
