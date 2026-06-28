import 'package:flutter/material.dart';
import '../theme/responsive.dart';

class ScoreButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final sz = teaching ? 72.0 : 36.0;
    return SizedBox(
      width: sz,
      height: sz,
      child: Material(
        color: color ?? t.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(teaching ? 16 : 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(teaching ? 16 : 8),
          child: Center(
            child: Text(
              label,
              style: t.textTheme.labelLarge?.copyWith(
                fontSize: teaching ? 28 : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
