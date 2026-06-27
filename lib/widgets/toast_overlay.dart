import 'package:flutter/material.dart';

enum ToastType { info, success, warning, error }

class ToastOverlay {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    ToastType type = ToastType.info,
  }) {
    _entry?.remove();

    final theme = Theme.of(context);
    final (bg, icon, textColor) = _toastStyle(theme, type);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => Positioned(
            bottom: 80,
            left: MediaQuery.of(context).size.width * 0.15,
            width: MediaQuery.of(context).size.width * 0.7,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 350),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder:
                    (_, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - value)),
                        child: child,
                      ),
                    ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: bg.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: textColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(entry);
    _entry = entry;

    Future.delayed(duration, () {
      entry.remove();
      if (_entry == entry) _entry = null;
    });
  }

  static (Color, IconData, Color) _toastStyle(ThemeData theme, ToastType type) {
    switch (type) {
      case ToastType.success:
        return (Colors.green.shade600, Icons.check_circle, Colors.white);
      case ToastType.warning:
        return (Colors.orange.shade600, Icons.warning_amber, Colors.white);
      case ToastType.error:
        return (Colors.red.shade600, Icons.error, Colors.white);
      case ToastType.info:
      default:
        return (
          theme.colorScheme.inverseSurface,
          Icons.info_outline,
          theme.colorScheme.onInverseSurface,
        );
    }
  }
}
