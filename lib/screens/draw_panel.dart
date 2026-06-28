import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/draw_provider.dart';
import '../providers/class_provider.dart';
import '../models/class_model.dart';
import '../services/audio_engine.dart';
import '../theme/responsive.dart';
import '../widgets/score_button.dart';
import '../widgets/rolling_display.dart';
import '../widgets/toast_overlay.dart';

class DrawPanel extends ConsumerStatefulWidget {
  const DrawPanel({super.key});
  @override
  ConsumerState<DrawPanel> createState() => _DrawPanelState();
}

class _DrawPanelState extends ConsumerState<DrawPanel> {
  final GlobalKey<RollingDisplayState> _mk = GlobalKey<RollingDisplayState>();
  final GlobalKey<RollingDisplayState> _gk = GlobalKey<RollingDisplayState>();
  String? _drawnMemberName;
  Member? _drawnMemberObj;
  String? _drawnGroupName;
  Group? _drawnGroupObj;

  bool get _isTeaching => context.isTeachingLayout;

  void _drawMember() {
    final notifier = ref.read(drawProvider.notifier);
    final classState = ref.read(classProvider);
    final cls = classState.selectedClass;
    final member = notifier.drawMember();
    if (member == null) { ToastOverlay.show(context, '没有可抽取的成员，请先添加成员'); return; }
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
    if (group == null) { ToastOverlay.show(context, '没有可抽取的小组，请先添加小组'); return; }
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
    final classState = ref.read(classProvider);
    final cls = classState.selectedClass;
    if (cls == null) return;
    Group? parentGroup;
    for (final g in cls.groups) { if (g.members.any((m) => m.uid == _drawnMemberObj!.uid)) { parentGroup = g; break; } }
    if (parentGroup == null) return;
    ref.read(classProvider.notifier).changeScore(cls.uid, parentGroup.uid, _drawnMemberObj!.uid, delta);
    if (delta > 0) { AudioEngine().playScoreUp(); } else { AudioEngine().playScoreDown(); }
    setState(() { _drawnMemberObj = _drawnMemberObj!.copyWith(score: _drawnMemberObj!.score + delta); });
  }

  @override
  Widget build(BuildContext context) {
    final drawState = ref.watch(drawProvider);
    final notifier = ref.read(drawProvider.notifier);
    final members = notifier.availableMembers;
    final groups = notifier.availableGroups;
    final theme = Theme.of(context);
    final t = _isTeaching;

    return Row(
      children: [
        // 个人抽取区域
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('个人抽取', style: theme.textTheme.titleSmall?.copyWith(fontSize: TeachingScale.fontSize(t, 14))),
            Text('候选池: ${members.length} 人', style: theme.textTheme.bodySmall?.copyWith(
              fontSize: TeachingScale.fontSize(t, 12), color: theme.colorScheme.onSurface.withOpacity(0.6),
            )),
            SizedBox(height: t ? 16 : 8),
            _drawButton('抽!', theme.colorScheme.primaryContainer, theme.colorScheme.primary, _drawMember),
            SizedBox(height: t ? 16 : 8),
            RollingDisplay(key: _mk, items: members.map((m) => m.name).toList(), itemHeight: t ? 80 : 40),
            if (_drawnMemberName != null) ...[
              SizedBox(height: t ? 12 : 6),
              Text(_drawnMemberName!, style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: TeachingScale.fontSize(t, 26), color: theme.colorScheme.primary,
              )),
              if (_drawnMemberObj != null)
                Text('当前积分: ${_drawnMemberObj!.score.toStringAsFixed(1)}', style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: TeachingScale.fontSize(t, 13),
                )),
              SizedBox(height: t ? 16 : 8),
              Wrap(
                spacing: t ? 16 : 6, runSpacing: t ? 12 : 4,
                children: [
                  ScoreButton(label: '+2', onTap: () => _changeScore(2), color: Colors.green.shade100, teaching: t),
                  ScoreButton(label: '+1', onTap: () => _changeScore(1), color: Colors.lightGreen.shade100, teaching: t),
                  ScoreButton(label: '+0.5', onTap: () => _changeScore(0.5), color: Colors.lime.shade100, teaching: t),
                  ScoreButton(label: '-0.5', onTap: () => _changeScore(-0.5), color: Colors.orange.shade100, teaching: t),
                  ScoreButton(label: '-1', onTap: () => _changeScore(-1), color: Colors.red.shade100, teaching: t),
                  ScoreButton(label: '-2', onTap: () => _changeScore(-2), color: Colors.deepOrange.shade100, teaching: t),
                ],
              ),
            ],
          ],
        )),
        const VerticalDivider(width: 1),
        // 小组抽取区域
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('小组抽取', style: theme.textTheme.titleSmall?.copyWith(fontSize: TeachingScale.fontSize(t, 14))),
            Text('候选池: ${groups.length} 组', style: theme.textTheme.bodySmall?.copyWith(
              fontSize: TeachingScale.fontSize(t, 12), color: theme.colorScheme.onSurface.withOpacity(0.6),
            )),
            SizedBox(height: t ? 16 : 8),
            _drawButton('抽!', theme.colorScheme.secondaryContainer, theme.colorScheme.secondary, _drawGroup),
            SizedBox(height: t ? 16 : 8),
            RollingDisplay(key: _gk, items: groups.map((g) => g.name).toList(), itemHeight: t ? 80 : 40),
            if (_drawnGroupName != null) ...[
              SizedBox(height: t ? 12 : 6),
              Text(_drawnGroupName!, style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: TeachingScale.fontSize(t, 26), color: theme.colorScheme.secondary,
              )),
            ],
            SizedBox(height: t ? 16 : 8),
            if (drawState.lockedGroupUid != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock, size: t ? 32 : 14, color: Colors.orange),
                SizedBox(width: t ? 8 : 4),
                Text('已锁定小组', style: theme.textTheme.bodySmall?.copyWith(fontSize: TeachingScale.fontSize(t, 12), color: Colors.orange)),
                SizedBox(width: t ? 16 : 8),
                TextButton.icon(
                  icon: Icon(Icons.lock_open, size: t ? 32 : 16),
                  label: Text('解锁', style: TextStyle(fontSize: TeachingScale.fontSize(t, 13))),
                  onPressed: () => notifier.unlockGroup(),
                ),
              ])
            else
              TextButton.icon(
                icon: Icon(Icons.lock_outline, size: t ? 32 : 16),
                label: Text('锁定小组', style: TextStyle(fontSize: TeachingScale.fontSize(t, 13))),
                onPressed: () {
                  if (_drawnGroupObj != null) { notifier.lockGroup(_drawnGroupObj!.uid); ToastOverlay.show(context, '已锁定: ${_drawnGroupObj!.name}'); }
                  else { ToastOverlay.show(context, '请先抽取一个小组再锁定'); }
                },
              ),
          ],
        )),
      ],
    );
  }

  Widget _drawButton(String text, Color backgroundColor, Color borderColor, VoidCallback onTap) {
    final t = _isTeaching;
    final size = t ? 120.0 : 80.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: t ? 4 : 2),
          boxShadow: [BoxShadow(color: borderColor.withOpacity(0.3), blurRadius: t ? 16 : 8, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(text, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: TeachingScale.fontSize(t, 24), color: borderColor, fontWeight: FontWeight.bold,
        ))),
      ),
    );
  }
}
