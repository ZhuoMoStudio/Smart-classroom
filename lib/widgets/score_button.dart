import 'package:flutter/material.dart';

class ScoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const ScoreButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: color ?? t.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              style: t.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
