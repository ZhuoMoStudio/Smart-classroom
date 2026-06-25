import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../theme/design_tokens.dart';

class RankBadge extends StatefulWidget {
  final double score;
  final bool animate;
  const RankBadge({super.key, required this.score, this.animate = false});
  @override
  State<RankBadge> createState() => _RankBadgeState();
}

class _RankBadgeState extends State<RankBadge> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _a = Tween(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut));
    if (widget.animate) _t();
  }

  @override
  void didUpdateWidget(covariant RankBadge old) {
    super.didUpdateWidget(old);
    if (widget.score != old.score && widget.animate) _t();
  }

  void _t() { _c.forward().then((_) => _c.reverse()); }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final (name, lv) = RankSystem.getRank(widget.score);
    final cs = _rc(lv);
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Transform.scale(
        scale: _a.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: cs),
            borderRadius: BorderRadius.circular(4)),
          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  List<Color> _rc(int lv) {
    if (lv >= 35) return [Colors.red, Colors.orange];
    if (lv >= 30) return [Colors.deepOrange, Colors.orangeAccent];
    if (lv >= 25) return [Colors.deepPurple, Colors.purpleAccent];
    if (lv >= 20) return [Colors.blue, Colors.lightBlueAccent];
    if (lv >= 15) return [Colors.teal, Colors.cyanAccent];
    if (lv >= 10) return [Colors.amber, Colors.yellowAccent];
    if (lv >= 5) return [AppColors.neutral300, AppColors.neutral200];
    return [AppColors.neutral400, AppColors.neutral300];
  }
}
