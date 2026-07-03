import 'package:flutter/material.dart';

/// 响应式布局工具
enum ScreenType { mobile, tablet, desktop }

extension ScreenTypeX on BuildContext {
  ScreenType get screenType {
    final w = MediaQuery.of(this).size.width;
    if (w >= 768) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  bool get isMobileLayout => screenType == ScreenType.mobile;
  bool get isTabletLayout => screenType == ScreenType.tablet;
}

/// 响应式缩放
class ResponsiveScale {
  /// 基于屏幕宽度返回缩放系数（以 375px 为基准）
  static double of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1400) return 1.0;
    if (w >= 768) return w / 768; // 平板 0.75~1.0
    return w / 375; // 手机按 375 基准缩放
  }

  /// 响应式字号
  static double fontSize(BuildContext context, double base) =>
      base * of(context).clamp(0.75, 1.1);

  /// 响应式尺寸
  static double size(BuildContext context, double base) =>
      base * of(context).clamp(0.8, 1.2);
}
