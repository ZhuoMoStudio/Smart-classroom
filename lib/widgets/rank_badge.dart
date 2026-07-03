import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../theme/design_tokens.dart';

/// 等级徽章 — 积分变化时弹性弹跳动画
class RankBadge extends StatefulWidget {
  final double score;
  final bool animate;
  final bool teaching;

  const RankBadge({
    super.key,
    required this.score,
    this.animate = false,
    this.teaching = false,
  });

  @override
  State<RankBadge> createState() => _RankBadgeState();
}

class _RankBadgeState extends State<RankBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  double _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _previousScore = widget.score;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    // 首次加载时也弹跳一次
    if (widget.animate) _trigger();
  }

  @override
  void didUpdateWidget(covariant RankBadge old) {
    super.didUpdateWidget(old);
    if (widget.score != old.score && widget.animate) {
      _trigger();
    }
  }

  void _trigger() {
    _previousScore = widget.score;
    _controller.forward().then((_) {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (name, level) = RankSystem.getRank(widget.score);
    final colors = _rankColors(level);
    final teaching = widget.teaching;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: teaching ? 16 : 6,
            vertical: teaching ? 8 : 2,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(teaching ? 12 : 4),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: teaching ? 24 : 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _rankColors(int level) {
    if (level >= 35) return [Colors.red, Colors.orange];
    if (level >= 30) return [Colors.deepOrange, Colors.orangeAccent];
    if (level >= 25) return [Colors.deepPurple, Colors.purpleAccent];
    if (level >= 20) return [Colors.blue, Colors.lightBlueAccent];
    if (level >= 15) return [Colors.teal, Colors.cyanAccent];
    if (level >= 10) return [Colors.amber, Colors.yellowAccent];
    if (level >= 5) return [AppColors.neutral300, AppColors.neutral200];
    return [AppColors.neutral400, AppColors.neutral300];
  }
}
