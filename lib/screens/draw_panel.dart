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
  final _mk = GlobalKey<RollingDisplayState>();
  final _gk = GlobalKey<RollingDisplayState>();
  String? _mn, _gn;

  void _drawM() {
    final n = ref.read(drawProvider.notifier); final m = n.drawMember(); if (m == null) return;
    AudioEngine().playDrawStart(); setState(() => _mn = null); _mk.currentState?.start();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return; setState(() => _mn = m.name); AudioEngine().playDrawResult();
    });
  }

  void _drawG() {
    final n = ref.read(drawProvider.notifier); final g = n.drawGroup(); if (g == null) return;
    AudioEngine().playDrawStart(); setState(() => _gn = null); _gk.currentState?.start();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return; setState(() => _gn = g.name); AudioEngine().playDrawResult();
    });
  }

  @override
  Widget build(BuildContext ctx) {
    final d = ref.watch(drawProvider);
    final mp = ref.read(drawProvider.notifier).availableMembers; final gp = ref.read(drawProvider.notifier).availableGroups;
    final t = Theme.of(ctx);
    return Row(children: [
      Expanded(child: Column(children: [
        Text('个人抽取', style: t.textTheme.titleSmall), Text('候选池: ${mp.length} 人'),
        const SizedBox(height: 8),
        _db('抽!', t.colorScheme.primaryContainer, t.colorScheme.primary, _drawM),
        const SizedBox(height: 8),
        RollingDisplay(key: _mk, items: mp.map((m) => m.name).toList(), itemHeight: 40),
        if (_mn != null) Text(_mn!, style: t.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 4, children: [
          ScoreButton(label: '+1', onTap: () {}), ScoreButton(label: '+0.5', onTap: () {}),
          ScoreButton(label: '-1', onTap: () {}), ScoreButton(label: '-0.5', onTap: () {}),
        ]),
      ])),
      const VerticalDivider(),
      Expanded(child: Column(children: [
        Text('小组抽取', style: t.textTheme.titleSmall), Text('候选池: ${gp.length} 组'),
        const SizedBox(height: 8),
        _db('抽!', t.colorScheme.secondaryContainer, t.colorScheme.secondary, _drawG),
        const SizedBox(height: 8),
        RollingDisplay(key: _gk, items: gp.map((g) => g.name).toList(), itemHeight: 40),
        if (_gn != null) Text(_gn!, style: t.textTheme.headlineMedium),
        const SizedBox(height: 8),
        if (d.lockedGroupUid != null)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock, size: 14),
            TextButton(onPressed: () => ref.read(drawProvider.notifier).unlockGroup(), child: const Text('解锁')),
          ]),
      ])),
    ]);
  }

  Widget _db(String text, Color bg, Color bd, VoidCallback cb) => GestureDetector(onTap: cb,
    child: Container(width: 80, height: 80, decoration: BoxDecoration(
        shape: BoxShape.circle, color: bg, border: Border.all(color: bd, width: 2)),
      child: Center(child: Text(text, style: Theme.of(context).textTheme.headlineSmall))));
}
