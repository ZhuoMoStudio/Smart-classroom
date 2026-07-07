import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draw_provider.dart';
import '../providers/class_provider.dart';
import '../models/class_model.dart';
import '../services/audio_engine.dart';
import '../theme/design_tokens.dart';
import '../widgets/score_button.dart';
import '../widgets/rolling_display.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/glass_panel.dart';

class DrawPanel extends ConsumerStatefulWidget {
  const DrawPanel({super.key});
  @override
  ConsumerState<DrawPanel> createState() => _DrawPanelState();
}

class _DrawPanelState extends ConsumerState<DrawPanel> {
  final GlobalKey<RollingDisplayState> _mk = GlobalKey();
  final GlobalKey<RollingDisplayState> _gk = GlobalKey();
  String? _drawnMemberName;
  Member? _drawnMemberObj;
  String? _drawnGroupName;
  Group? _drawnGroupObj;

  void _drawMember() {
    final notifier = ref.read(drawProvider.notifier);
    final member = notifier.drawMember();
    if (member == null) {
      ToastOverlay.show(context, '没有可抽取的成员，请先添加成员或重置排除列表');
      return;
    }
    AudioEngine().playDrawStart();
    setState(() { _drawnMemberName = null; _drawnMemberObj = null; });
    _mk.currentState?.start();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() { _drawnMemberName = member.name; _drawnMemberObj = member; });
      AudioEngine().playDrawResult();
    });
  }

  void _drawGroup() {
    final notifier = ref.read(drawProvider.notifier);
    final group = notifier.drawGroup();
    if (group == null) {
      ToastOverlay.show(context, '没有可抽取的小组，请先添加小组或重置排除列表');
      return;
    }
    AudioEngine().playDrawStart();
    setState(() { _drawnGroupName = null; _drawnGroupObj = null; });
    _gk.currentState?.start();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() { _drawnGroupName = group.name; _drawnGroupObj = group; });
      AudioEngine().playDrawResult();
    });
  }

  void _changeScore(double delta) {
    if (_drawnMemberObj == null) return;
    final cs = ref.read(classProvider);
    final cls = cs.selectedClass;
    if (cls == null) return;
    Group? pg;
    for (final g in cls.groups) {
      if (g.members.any((m) => m.uid == _drawnMemberObj!.uid)) { pg = g; break; }
    }
    if (pg == null) return;
    ref.read(classProvider.notifier).changeScore(cls.uid, pg.uid, _drawnMemberObj!.uid, delta);
    if (delta > 0) AudioEngine().playScoreUp(); else AudioEngine().playScoreDown();
    setState(() {
      _drawnMemberObj = _drawnMemberObj!.copyWith(score: _drawnMemberObj!.score + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = ref.watch(drawProvider);
    final notifier = ref.read(drawProvider.notifier);
    final members = notifier.availableMembers;
    final groups = notifier.availableGroups;
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.height < 600;

    final content = Row(children: [
      Expanded(child: _buildSide(theme, true, members.length, _drawMember, _mk, members.map((m) => m.name).toList(), _drawnMemberName, _drawnMemberObj)),
      const VerticalDivider(width: 1),
      Expanded(child: _buildSide(theme, false, groups.length, _drawGroup, _gk, groups.map((g) => g.name).toList(), _drawnGroupName, null)),
    ]);

    return isCompact
        ? SingleChildScrollView(padding: const EdgeInsets.all(4), child: content)
        : Padding(padding: const EdgeInsets.all(6), child: content);
  }

  Widget _buildSide(ThemeData theme, bool isMember, int count, VoidCallback onDraw,
      GlobalKey<RollingDisplayState> key, List<String> items, String? drawnName, Member? drawnObj) {
    final icon = isMember ? Icons.person : Icons.groups;
    final label = isMember ? '个人抽取' : '小组抽取';
    final unit = isMember ? '人' : '组';
    final c = isMember ? theme.colorScheme.primary : theme.colorScheme.secondary;
    final bg = isMember ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: c), const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text('$count $unit', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ]),
      ),
      const SizedBox(height: 6),
      _PulseButton(size: 56, backgroundColor: bg, borderColor: c, text: '抽!', onTap: onDraw),
      const SizedBox(height: 6),
      RollingDisplay(key: key, items: items, itemHeight: 34),
      if (drawnName != null) ...[
        const SizedBox(height: 4),
        GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(drawnName, style: theme.textTheme.titleSmall?.copyWith(color: c, fontWeight: FontWeight.bold)),
            if (drawnObj != null)
              Text('积分: ${drawnObj.score.toStringAsFixed(1)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ]),
        ),
        if (isMember) ...[
          const SizedBox(height: 2),
          Wrap(spacing: 3, runSpacing: 3, children: [
            ScoreButton(label: '+2', onTap: () => _changeScore(2), color: Colors.green.shade100),
            ScoreButton(label: '+1', onTap: () => _changeScore(1), color: Colors.lightGreen.shade100),
            ScoreButton(label: '+0.5', onTap: () => _changeScore(0.5), color: Colors.lime.shade100),
            ScoreButton(label: '-0.5', onTap: () => _changeScore(-0.5), color: Colors.orange.shade100),
            ScoreButton(label: '-1', onTap: () => _changeScore(-1), color: Colors.red.shade100),
            ScoreButton(label: '-2', onTap: () => _changeScore(-2), color: Colors.deepOrange.shade100),
          ]),
        ] else ...[
          const SizedBox(height: 2),
          _GroupLockWidget(drawnGroupName: drawnName, drawnGroupObj: _drawnGroupObj),
        ],
      ],
    ]);
  }
}

class _GroupLockWidget extends ConsumerWidget {
  final String? drawnGroupName;
  final Group? drawnGroupObj;
  const _GroupLockWidget({this.drawnGroupName, this.drawnGroupObj});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = ref.watch(drawProvider);
    final notifier = ref.read(drawProvider.notifier);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (ds.lockedGroupUid != null) ...[
        const Icon(Icons.lock, size: 13, color: Colors.orange), const SizedBox(width: 3),
        Text('已锁定', style: TextStyle(fontSize: 11, color: Colors.orange)), const SizedBox(width: 6),
        TextButton.icon(icon: const Icon(Icons.lock_open, size: 13),
            label: const Text('解锁', style: TextStyle(fontSize: 11)),
            onPressed: () => notifier.unlockGroup()),
      ] else
        TextButton.icon(icon: const Icon(Icons.lock_outline, size: 13),
            label: const Text('锁定', style: TextStyle(fontSize: 11)),
            onPressed: () {
              if (drawnGroupObj != null) {
                notifier.lockGroup(drawnGroupObj!.uid);
                ToastOverlay.show(context, '已锁定: ${drawnGroupObj!.name}');
              } else { ToastOverlay.show(context, '请先抽取一个小组'); }
            }),
    ]);
  }
}

class _PulseButton extends StatefulWidget {
  final double size;
  final Color backgroundColor, borderColor;
  final String text;
  final VoidCallback onTap;
  const _PulseButton({required this.size, required this.backgroundColor,
      required this.borderColor, required this.text, required this.onTap});
  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scale = Tween(begin: 1.0, end: 0.82).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _handleTap() {
    AudioEngine().hapticHeavy();
    widget.onTap();
    _ctrl.forward().then((_) { if (mounted) _ctrl.reverse(); });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: RepaintBoundary(
          child: Container(
            width: widget.size, height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: widget.backgroundColor,
              border: Border.all(color: widget.borderColor, width: 2),
              boxShadow: [BoxShadow(color: widget.borderColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(widget.text,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20, color: widget.borderColor, fontWeight: FontWeight.bold))),
          ),
        ),
      ),
    );
  }
}
