import 'package:flutter/material.dart';

/// 滑动渐入页面过渡路由 — 统一页面切换动画
Route<T> fadePageRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 300)}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        ),
        child: child,
      );
    },
    transitionDuration: duration,
  );
}

/// 滑动渐入（带轻微上滑效果）
Route<T> slideFadePageRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 300)}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.03),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        ),
      );
    },
    transitionDuration: duration,
  );
}
