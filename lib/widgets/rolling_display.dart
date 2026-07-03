import 'dart:math';
import 'package:flutter/material.dart';

/// 抽取滚动显示组件 — 使用缓动曲线实现的流畅滚动动画
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
  late Animation<double> _position;
  int _finalIndex = 0;
  int _rotationCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _position = _buildPosition();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinish?.call();
      }
    });
  }

  Animation<double> _buildPosition() {
    return Tween<double>(begin: 0.0, end: _rotationCount + _finalIndex.toDouble())
        .animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.fastOutSlowIn,
        ));
  }

  /// 启动滚动动画
  /// 随机确定最终位置，实现每次抽取结果不同的滚动效果
  void start() {
    if (widget.items.isEmpty) return;
    _finalIndex = Random().nextInt(widget.items.length);
    _rotationCount = max(widget.items.length * 3, 15);
    _position = _buildPosition();
    _controller.forward(from: 0.0);
    setState(() {});
  }

  /// 当前显示的项目索引
  int get _displayIndex {
    if (widget.items.isEmpty) return 0;
    if (!_controller.isAnimating && _controller.isCompleted) {
      return _finalIndex;
    }
    final pos = _position.value;
    return pos.floor() % widget.items.length;
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
      child: AnimatedBuilder(
        animation: _position,
        builder: (context, _) {
          final idx = _displayIndex;
          return Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                widget.items[idx],
                key: ValueKey('${widget.items[idx]}_${_controller.value.toStringAsFixed(3)}'),
                style: widget.textStyle ?? Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          );
        },
      ),
    );
  }
}
