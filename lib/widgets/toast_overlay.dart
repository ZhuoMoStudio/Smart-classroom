import 'package:flutter/material.dart';

class ToastOverlay {
  static OverlayEntry? _e;
  static void show(BuildContext ctx, String msg, {Duration d = const Duration(seconds: 2)}) {
    _e?.remove(); final ov = Overlay.of(ctx); late OverlayEntry en;
    en = OverlayEntry(builder: (_) => Positioned(bottom: 80,
          left: MediaQuery.of(ctx).size.width * 0.2, width: MediaQuery.of(ctx).size.width * 0.6,
          child: Material(color: Colors.transparent,
            child: TweenAnimationBuilder<double>(duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (_, v, child) => Opacity(opacity: v,
                  child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.inverseSurface,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(msg, textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.onInverseSurface))),
            ))));
    ov.insert(en); _e = en; Future.delayed(d, () { en.remove(); if (_e == en) _e = null; });
  }
}
