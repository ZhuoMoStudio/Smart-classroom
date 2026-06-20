import 'dart:ui';
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  final Widget child; final double blur; final Color? backgroundColor;
  final BorderRadius? borderRadius; final EdgeInsetsGeometry? padding;
  const GlassPanel({super.key, required this.child, this.blur = 8.0,
      this.backgroundColor, this.borderRadius, this.padding});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bg = backgroundColor ?? t.colorScheme.surface.withOpacity(0.55);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(color: t.colorScheme.outline.withOpacity(0.15))),
          child: child)),
    );
  }
}
