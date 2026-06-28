import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_engine.dart';
import '../services/network_time.dart';
import '../theme/responsive.dart';
import '../widgets/toast_overlay.dart';

class TimerPanel extends ConsumerStatefulWidget {
  const TimerPanel({super.key});
  @override
  ConsumerState<TimerPanel> createState() => _TimerPanelState();
}

class _TimerPanelState extends ConsumerState<TimerPanel> {
  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;
  bool _wasTimerRunning = false;
  final TextEditingController _customMinutesController = TextEditingController();

  @override
  void initState() { super.initState(); _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => _currentTime = DateTime.now()); }); }

  @override
  void dispose() { _clockTimer?.cancel(); _customMinutesController.dispose(); super.dispose(); }

  Future<void> _syncNetworkTime() async {
    final networkTime = await NetworkTimeService.getNetworkTime();
    if (networkTime != null && mounted) { setState(() => _currentTime = networkTime); ToastOverlay.show(context, '时间已同步'); }
    else { ToastOverlay.show(context, '网络时间获取失败'); }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final teaching = context.isTeachingLayout;

    final minutes = timerState.remainingSeconds ~/ 60;
    final seconds = timerState.remainingSeconds % 60;
    final isLowTime = timerState.remainingSeconds <= 10 && timerState.remainingSeconds > 0 && timerState.isRunning;

    if (timerState.remainingSeconds == 0 && timerState.totalSeconds > 0 && _wasTimerRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) { AudioEngine().playTimerEnd(); });
    }
    _wasTimerRunning = timerState.isRunning && timerState.remainingSeconds > 0;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // 当前时间
      GestureDetector(
        onDoubleTap: _syncNetworkTime,
        child: Column(children: [
          Text('${_pad(_currentTime.hour)}:${_pad(_currentTime.minute)}:${_pad(_currentTime.second)}',
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: TeachingScale.fontSize(teaching, 24), fontWeight: FontWeight.w300, letterSpacing: 2)),
          Text('${_currentTime.year}/${_pad(_currentTime.month)}/${_pad(_currentTime.day)}  星期${_weekday(_currentTime.weekday)}',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: TeachingScale.fontSize(teaching, 12), color: theme.colorScheme.onSurface.withOpacity(0.6))),
          if (!teaching)
            Text('双击同步网络时间', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
        ]),
      ),
      if (!teaching) const Divider(),
      // 倒计时
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(teaching ? 24 : (isLowTime ? 12 : 8)),
        decoration: isLowTime ? BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(teaching ? 24 : 12),
          border: Border.all(color: Colors.red, width: teaching ? 4 : 2),
        ) : null,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 1.0, end: isLowTime ? 1.1 : 1.0),
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('${_pad(minutes)}', style: theme.textTheme.displaySmall?.copyWith(fontSize: TeachingScale.fontSize(teaching, 36), color: isLowTime ? Colors.red : null, fontWeight: FontWeight.bold)),
            Text(':', style: theme.textTheme.displaySmall?.copyWith(fontSize: TeachingScale.fontSize(teaching, 36), color: isLowTime ? Colors.red : null, fontWeight: FontWeight.bold)),
            Text('${_pad(seconds)}', style: theme.textTheme.displaySmall?.copyWith(fontSize: TeachingScale.fontSize(teaching, 36), color: isLowTime ? Colors.red : null, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
      // 进度条
      if (timerState.totalSeconds > 0) ...[
        SizedBox(height: teaching ? 16 : 8),
        SizedBox(width: teaching ? 400 : 200, child: LinearProgressIndicator(
          value: timerState.remainingSeconds / timerState.totalSeconds,
          color: isLowTime ? Colors.red : theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          minHeight: teaching ? 12 : 4,
        )),
      ],
      SizedBox(height: teaching ? 16 : 8),
      // 预设按钮
      Wrap(spacing: teaching ? 16 : 6, runSpacing: teaching ? 12 : 6, children: settings.timerPresets.map((min) {
        return ActionChip(
          label: Text('$min 分钟', style: TextStyle(fontSize: teaching ? 24 : null)),
          avatar: Icon(Icons.timer, size: teaching ? 36 : 16),
          onPressed: () => ref.read(timerProvider.notifier).setTimer(min),
        );
      }).toList()),
      SizedBox(height: teaching ? 12 : 4),
      // 自定义分钟输入
      Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: teaching ? 180 : 80, child: TextField(
          controller: _customMinutesController,
          decoration: InputDecoration(
            labelText: '分钟',
            labelStyle: TextStyle(fontSize: teaching ? 24 : null),
            isDense: !teaching,
            contentPadding: EdgeInsets.symmetric(horizontal: teaching ? 24 : 10, vertical: teaching ? 16 : 8),
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: teaching ? 28 : null),
          onSubmitted: (value) { final m = int.tryParse(value); if (m != null && m > 0) { ref.read(timerProvider.notifier).setTimer(m); _customMinutesController.clear(); } },
        )),
        SizedBox(width: teaching ? 16 : 8),
        IconButton.filledTonal(
          icon: Icon(Icons.check, size: teaching ? 40 : 18),
          iconSize: teaching ? 40 : null,
          onPressed: () { final m = int.tryParse(_customMinutesController.text); if (m != null && m > 0) { ref.read(timerProvider.notifier).setTimer(m); _customMinutesController.clear(); } },
          visualDensity: teaching ? VisualDensity.standard : VisualDensity.compact,
        ),
      ]),
      SizedBox(height: teaching ? 16 : 8),
      // 控制按钮
      Row(mainAxisSize: MainAxisSize.min, children: [
        FilledButton.tonalIcon(
          icon: Icon(timerState.isRunning ? Icons.pause : Icons.play_arrow, size: teaching ? 36 : null),
          label: Text(timerState.isRunning ? '暂停' : '开始', style: TextStyle(fontSize: teaching ? 28 : null)),
          style: teaching ? FilledButton.styleFrom(
            minimumSize: const Size(200, 80),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ) : null,
          onPressed: () { if (timerState.isRunning) { ref.read(timerProvider.notifier).pause(); } else { ref.read(timerProvider.notifier).start(); } },
        ),
        SizedBox(width: teaching ? 16 : 8),
        OutlinedButton.icon(
          icon: Icon(Icons.stop, size: teaching ? 36 : null),
          label: Text('重置', style: TextStyle(fontSize: teaching ? 28 : null)),
          style: teaching ? OutlinedButton.styleFrom(
            minimumSize: const Size(200, 80),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ) : null,
          onPressed: () => ref.read(timerProvider.notifier).reset(),
        ),
      ]),
    ]);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String _weekday(int w) { const days = ['一','二','三','四','五','六','日']; return days[w - 1]; }
}
