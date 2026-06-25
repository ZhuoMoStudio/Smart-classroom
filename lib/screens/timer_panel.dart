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
  bool _wasTimerRunning = false;
  final TextEditingController _customMinutesController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() => _currentTime = DateTime.now());
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _customMinutesController.dispose();
    super.dispose();
  }

  Future<void> _syncNetworkTime() async {
    final networkTime = await NetworkTimeService.getNetworkTime();
    if (networkTime != null && mounted) {
      setState(() => _currentTime = networkTime);
      ToastOverlay.show(context, '时间已同步');
    } else {
      ToastOverlay.show(context, '网络时间获取失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final minutes = timerState.remainingSeconds ~/ 60;
    final seconds = timerState.remainingSeconds % 60;
    final isLowTime = timerState.remainingSeconds <= 10 &&
        timerState.remainingSeconds > 0 &&
        timerState.isRunning;

    // 计时器结束时触发音效
    if (timerState.remainingSeconds == 0 &&
        timerState.totalSeconds > 0 &&
        _wasTimerRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AudioEngine().playTimerEnd();
      });
    }
    _wasTimerRunning = timerState.isRunning && timerState.remainingSeconds > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 当前时间显示（双击同步网络时间）
        GestureDetector(
          onDoubleTap: _syncNetworkTime,
          child: Column(
            children: [
              Text(
                '${_pad(_currentTime.hour)}:${_pad(_currentTime.minute)}:${_pad(_currentTime.second)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${_currentTime.year}/${_pad(_currentTime.month)}/${_pad(_currentTime.day)}  星期${_weekday(_currentTime.weekday)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '双击同步网络时间',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // 倒计时显示
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isLowTime ? 12 : 8),
          decoration: isLowTime
              ? BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 2),
                )
              : null,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 1.0, end: isLowTime ? 1.1 : 1.0),
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${_pad(minutes)}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: isLowTime ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ':',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: isLowTime ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_pad(seconds)}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: isLowTime ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 进度条
        if (timerState.totalSeconds > 0) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: timerState.remainingSeconds / timerState.totalSeconds,
              color: isLowTime
                  ? Colors.red
                  : theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
        const SizedBox(height: 8),
        // 预设按钮
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: settings.timerPresets.map((minutes) {
            return ActionChip(
              label: Text('$minutes 分钟'),
              avatar: Icon(Icons.timer, size: 16),
              onPressed: () => ref.read(timerProvider.notifier).setTimer(minutes),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        // 自定义分钟输入
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: _customMinutesController,
                decoration: const InputDecoration(
                  labelText: '分钟',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  final minutes = int.tryParse(value);
                  if (minutes != null && minutes > 0) {
                    ref.read(timerProvider.notifier).setTimer(minutes);
                    _customMinutesController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.check, size: 18),
              onPressed: () {
                final minutes = int.tryParse(_customMinutesController.text);
                if (minutes != null && minutes > 0) {
                  ref.read(timerProvider.notifier).setTimer(minutes);
                  _customMinutesController.clear();
                }
              },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 控制按钮
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonalIcon(
              icon: Icon(
                timerState.isRunning ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(timerState.isRunning ? '暂停' : '开始'),
              onPressed: () {
                if (timerState.isRunning) {
                  ref.read(timerProvider.notifier).pause();
                } else {
                  ref.read(timerProvider.notifier).start();
                }
              },
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text('重置'),
              onPressed: () => ref.read(timerProvider.notifier).reset(),
            ),
          ],
        ),
      ],
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _weekday(int w) {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    return days[w - 1];
  }
}
