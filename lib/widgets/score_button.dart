import 'package:flutter/material.dart';
import '../services/audio_engine.dart';
import '../theme/responsive.dart';

/// 积分按钮 — 按压时触发缩放反馈动画
class ScoreButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool teaching;

  const ScoreButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.teaching = false,
  });

  @override
  State<ScoreButton> createState() => _ScoreButtonState();
}

class _ScoreButtonState extends State<ScoreButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // 触感反馈
    AudioEngine().hapticClick();
    // 按下缩放
    _controller.forward().then((_) {
      if (!mounted) return;
      // 弹回 + 微过冲
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final sz = widget.teaching ? 72.0 : 36.0;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: SizedBox(
        width: sz,
        height: sz,
        child: Material(
          color: widget.color ?? t.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(widget.teaching ? 16 : 8),
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(widget.teaching ? 16 : 8),
            child: Center(
              child: Text(
                widget.label,
                style: t.textTheme.labelLarge?.copyWith(
                  fontSize: widget.teaching ? 28 : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
