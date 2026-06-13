import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draw_provider.dart';
import '../services/audio_engine.dart';
import '../widgets/score_button.dart';
import '../widgets/rolling_display.dart';

class DrawPanel extends ConsumerStatefulWidget {
  const DrawPanel({super.key});

  @override
  ConsumerState<DrawPanel> createState() => _DrawPanelState();
}

class _DrawPanelState extends ConsumerState<DrawPanel> {
  final _memberRollKey = GlobalKey<RollingDisplayState>();
  final _groupRollKey = GlobalKey<RollingDisplayState>();
  String? _drawnMemberName, _drawnGroupName;

  void _drawMember() {
    final notifier = ref.read(drawProvider.notifier);
    final member = notifier.drawMember();
    if (member == null) return;
    AudioEngine().playDrawStart();
    setState(() => _drawnMemberName = null);
    _memberRollKey.currentState?.start();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _drawnMemberName = member.name);
      AudioEngine().playDrawResult();
    });
  }

  void _drawGroup() {
    final notifier = ref.read(drawProvider.notifier);
    final group = notifier.drawGroup();
    if (group == null) return;
    AudioEngine().playDrawStart();
    setState(() => _drawnGroupName = null);
    _groupRollKey.currentState?.start();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _drawnGroupName = group.name);
      AudioEngine().playDrawResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    final draw = ref.watch(drawProvider);
    final memberPool = draw.availableMembers;
    final groupPool = draw.availableGroups;
    return Row(children: [
      Expanded(child: Column(children: [
        Text('个人抽取', style: Theme.of(context).textTheme.titleSmall),
        Text('候选池: ${memberPool.length} 人'),
        const SizedBox(height: 8),
        _drawButton('抽!', Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.primary, _drawMember),
        const SizedBox(height: 8),
        RollingDisplay(key: _memberRollKey, items: memberPool.map((m) => m.name).toList(), itemHeight: 40),
        if (_drawnMemberName != null)
          Text(_drawnMemberName!, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 4, children: [
          ScoreButton(label: '+1', onTap: () {}),
          ScoreButton(label: '+½', onTap: () {}),
          ScoreButton(label: '−1', onTap: () {}),
          ScoreButton(label: '−½', onTap: () {}),
        ]),
      ])),
      const VerticalDivider(),
      Expanded(child: Column(children: [
        Text('小组抽取', style: Theme.of(context).textTheme.titleSmall),
        Text('候选池: ${groupPool.length} 组'),
        const SizedBox(height: 8),
        _drawButton('抽!', Theme.of(context).colorScheme.secondaryContainer, Theme.of(context).colorScheme.secondary, _drawGroup),
        const SizedBox(height: 8),
        RollingDisplay(key: _groupRollKey, items: groupPool.map((g) => g.name).toList(), itemHeight: 40),
        if (_drawnGroupName != null)
          Text(_drawnGroupName!, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        if (draw.lockedGroupUid != null)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock, size: 14),
            TextButton(onPressed: () => ref.read(drawProvider.notifier).unlockGroup(), child: const Text('解锁')),
          ]),
      ])),
    ]);
  }

  Widget _drawButton(String text, Color bg, Color border, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg, border: Border.all(color: border, width: 2)),
          child: Center(child: Text(text, style: Theme.of(context).textTheme.headlineSmall)),
        ),
      );
}