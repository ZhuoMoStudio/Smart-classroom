import 'dart:math';
import 'package:flutter/material.dart';

/// 抽取滚动显示组件 — v1.30 增强动画
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
    this.duration = const Duration(milliseconds: 1500),
    this.textStyle,
    this.onFinish,
  });

  @override
  State<RollingDisplay> createState() => RollingDisplayState();
}

class RollingDisplayState extends State<RollingDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _position;
  int _finalIndex = 0;
  int _rotationCount = 0;
  int _displayIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: widget.duration, vsync: this);
    _position = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
    _controller.addListener(() {
      if (widget.items.isNotEmpty) {
        final idx =
            _position.value.floor() % widget.items.length;
        if (idx != _displayIndex) {
          setState(() => _displayIndex = idx);
        }
      }
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinish?.call();
      }
    });
  }

  /// 启动滚动动画 — 带缓入缓出效果
  void start() {
    if (widget.items.isEmpty) return;
    _finalIndex = Random().nextInt(widget.items.length);
    // 随机 3~6 圈 + 目标位置
    _rotationCount = 3 + Random().nextInt(4);
    final totalRotations =
        (_rotationCount * widget.items.length + _finalIndex).toDouble();

    _position = Tween<double>(begin: 0.0, end: totalRotations).animate(
      CurvedAnimation(
        parent: _controller,
        // 先快后慢的缓出曲线，模拟减速停止
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
        reverseCurve: Curves.easeOut,
      ),
    );

    _controller.forward(from: 0.0);
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

    final isAnimating = _controller.isAnimating;

    return SizedBox(
      height: widget.itemHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 阴影渐变遮罩
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.9),
                      Colors.transparent,
                      Colors.transparent,
                      Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // 显示内容
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 80),
            child: Text(
              widget.items[_displayIndex],
              key: ValueKey('${widget.items[_displayIndex]}_$_displayIndex'),
              style: (widget.textStyle ??
                      Theme.of(context).textTheme.headlineMedium)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
