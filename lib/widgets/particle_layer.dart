import 'dart:math';
import 'package:flutter/material.dart';

class ParticleLayer extends StatefulWidget {
  final Widget child; const ParticleLayer({super.key, required this.child});
  @override State<ParticleLayer> createState() => ParticleLayerState();
}

class ParticleLayerState extends State<ParticleLayer> with SingleTickerProviderStateMixin {
  final _ps = <_Particle>[];
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(seconds: 1), vsync: this)
      ..addListener(_onAnimation);
  }

  void _onAnimation() {
    if (_c.isCompleted) {
      _ps.clear();
    }
    setState(() {});
  }

  void emit(Offset p) {
    final r = Random();
    for (int i = 0; i < 12; i++) {
      final a = r.nextDouble() * 2 * pi;
      final sp = 80 + r.nextDouble() * 120;
      _ps.add(_Particle(
        x: p.dx,
        y: p.dy,
        vx: cos(a) * sp,
        vy: sin(a) * sp,
        color: Colors.primaries[r.nextInt(Colors.primaries.length)],
      ));
    }
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.removeListener(_onAnimation);
    _ps.clear();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Stack(children: [
    widget.child,
    Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ParticlePainter(particles: _ps, progress: _c.value),
        ),
      ),
    ),
  ]);
}

class _Particle { final double x,y,vx,vy; final Color color; const _Particle({required this.x,required this.y,required this.vx,required this.vy,required this.color}); }
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles; final double progress;
  _ParticlePainter({required this.particles, required this.progress});
  @override void paint(Canvas c, Size s) { for (final p in particles) {
    final pt = Paint()..color=p.color.withOpacity(1-progress)..style=PaintingStyle.fill;
    c.drawCircle(Offset(p.x+p.vx*progress, p.y+p.vy*progress+100*progress*progress), 3*(1-progress), pt); }}
  @override bool shouldRepaint(covariant _ParticlePainter o) => true;
}
