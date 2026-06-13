import 'dart:math';
import 'package:flutter/material.dart';

class ParticleLayer extends StatefulWidget {
  final Widget child;
  const ParticleLayer({super.key, required this.child});
  @override
  State<ParticleLayer> createState() => ParticleLayerState();
}

class ParticleLayerState extends State<ParticleLayer> with SingleTickerProviderStateMixin {
  final List<_Particle> _particles = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this)
      ..addListener(() => setState(() {}));
  }

  void emit(Offset position) {
    final rand = Random();
    for (int i = 0; i < 12; i++) {
      final angle = rand.nextDouble() * 2 * pi;
      final speed = 80 + rand.nextDouble() * 120;
      _particles.add(_Particle(
        x: position.dx, y: position.dy,
        vx: cos(angle) * speed, vy: sin(angle) * speed,
        color: Colors.primaries[rand.nextInt(Colors.primaries.length)],
      ));
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ParticlePainter(particles: _particles, progress: _controller.value)),
          ),
        ),
      ]);
}

class _Particle {
  final double x, y, vx, vy;
  final Color color;
  const _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withOpacity(1 - progress)..style = PaintingStyle.fill;
      final x = p.x + p.vx * progress;
      final y = p.y + p.vy * progress + 100 * progress * progress;
      canvas.drawCircle(Offset(x, y), 3 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}