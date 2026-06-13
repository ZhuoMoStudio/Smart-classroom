import 'package:flutter/material.dart';
import '../models/class_model.dart';

class RankBadge extends StatefulWidget {
  final double score;
  final bool animate;

  const RankBadge({super.key, required this.score, this.animate = false});

  @override
  State<RankBadge> createState() => _RankBadgeState();
}

class _RankBadgeState extends State<RankBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    if (widget.animate) _trigger();
  }

  @override
  void didUpdateWidget(covariant RankBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score != oldWidget.score && widget.animate) _trigger();
  }

  void _trigger() {
    _controller.forward().then((_) => _controller.reverse());
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
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(4)),
          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
    if (level >= 5) return [Colors.blueGrey, Colors.grey];
    return [const Color(0xFF8D6E63), Colors.brown];
  }
}