import 'package:flutter/material.dart';

class RollingDisplay extends StatefulWidget {
  final List<String> items; final double itemHeight; final Duration duration;
  final TextStyle? textStyle; final VoidCallback? onFinish;
  const RollingDisplay({super.key, required this.items, this.itemHeight = 48,
      this.duration = const Duration(milliseconds: 1200), this.textStyle, this.onFinish});
  @override State<RollingDisplay> createState() => RollingDisplayState();
}

class RollingDisplayState extends State<RollingDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _c; int _i = 0;
  @override void initState() { super.initState();
    _c = AnimationController(duration: widget.duration, vsync: this);
    _c.addStatusListener((s) { if (s == AnimationStatus.completed) widget.onFinish?.call(); }); }

  void start() { _i = 0; _c.forward(from: 0); _scroll(); }

  void _scroll() async {
    while (_c.isAnimating && mounted) { await Future.delayed(const Duration(milliseconds: 80));
      if (!_c.isAnimating || !mounted) break; setState(() => _i = (_i + 1) % widget.items.length); }
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  @override Widget build(BuildContext ctx) => SizedBox(height: widget.itemHeight,
      child: widget.items.isEmpty ? const SizedBox() : Center(child: Text(widget.items[_i],
          style: widget.textStyle ?? Theme.of(ctx).textTheme.headlineMedium)));
}
