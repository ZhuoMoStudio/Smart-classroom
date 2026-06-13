import 'package:flutter/material.dart';

class ToastOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    _entry?.remove();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (ctx) => Positioned(
          bottom: 80,
          left: MediaQuery.of(context).size.width * 0.2,
          width: MediaQuery.of(context).size.width * 0.6,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(message, textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)),
              ),
            ),
          ),
        ));
    overlay.insert(entry);
    _entry = entry;
    Future.delayed(duration, () {
      entry.remove();
      if (_entry == entry) _entry = null;
    });
  }
}