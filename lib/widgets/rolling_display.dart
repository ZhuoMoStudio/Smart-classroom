import 'package:flutter/material.dart';

class RollingDisplay extends StatefulWidget {
  final List<String> items;
  final double itemHeight;
  final Duration duration;
  final TextStyle? textStyle;
  final VoidCallback? onFinish;

  const RollingDisplay({
    super.key,
    required this.items,
    this.itemHeight = 48,
    this.duration = const Duration(milliseconds: 1200),
    this.textStyle,
    this.onFinish,
  });

  @override
  State<RollingDisplay> createState() => RollingDisplayState();
}

class RollingDisplayState extends State<RollingDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinish?.call();
      }
    });
  }

  void start() {
    _currentIndex = 0;
    _controller.forward(from: 0);
    _scroll();
  }

  void _scroll() async {
    while (_controller.isAnimating && mounted) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!_controller.isAnimating || !mounted) break;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.items.length;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(height: widget.itemHeight);
    }

    return SizedBox(
      height: widget.itemHeight,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 60),
          child: Text(
            widget.items[_currentIndex],
            key: ValueKey('${widget.items[_currentIndex]}_$_currentIndex'),
            style: widget.textStyle ??
                Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
