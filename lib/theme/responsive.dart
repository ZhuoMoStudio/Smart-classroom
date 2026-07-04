import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// 响应式布局工具
enum ScreenType { mobile, tablet }

extension ScreenTypeX on BuildContext {
  ScreenType get screenType {
    final w = MediaQuery.of(this).size.width;
    if (w >= AppBreakpoints.tablet) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  bool get isMobileLayout => screenType == ScreenType.mobile;
  bool get isTabletLayout => screenType == ScreenType.tablet;

  /// 大屏检测（桌面端宽屏）
  bool get isWideScreen => MediaQuery.of(this).size.width >= AppBreakpoints.desktop;
}

/// 响应式缩放
class ResponsiveScale {
  static double of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= AppBreakpoints.desktop) return 1.0;
    if (w >= AppBreakpoints.tablet) return (w / AppBreakpoints.tablet).clamp(0.75, 1.0);
    return (w / 375).clamp(0.8, 1.1);
  }

  static double fontSize(BuildContext context, double base) => base * of(context);
  static double size(BuildContext context, double base) => base * of(context);
}
