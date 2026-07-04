import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// 响应式布局工具
enum ScreenType { mobile, tablet }

extension ScreenTypeX on BuildContext {
  ScreenType get screenType {
    final w = MediaQuery.of(this).size.width;
    if (w >= 768) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  bool get isMobileLayout => screenType == ScreenType.mobile;
  bool get isTabletLayout => screenType == ScreenType.tablet;

  /// 兼容旧代码引用
  @Deprecated('Use screenType instead')
  bool get isTeachingLayout => false;
}

/// 响应式缩放（兼容旧引用）
class ResponsiveScale {
  static double of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1400) return 1.0;
    if (w >= 768) return (w / 768).clamp(0.75, 1.0);
    return (w / 375).clamp(0.8, 1.1);
  }

  static double fontSize(BuildContext context, double base) => base * of(context);
  static double size(BuildContext context, double base) => base * of(context);
}

/// 兼容旧代码（旧文件引用 TeachingScale）
class TeachingScale {
  static double fontSize(bool isTeaching, double base) => isTeaching ? base * 2.25 : base;
  static double size(bool isTeaching, double base) => isTeaching ? base * 1.67 : base;
  static double textScale(bool isTeaching) => isTeaching ? 2.25 : 1.0;
  static double touchScale(bool isTeaching) => isTeaching ? 1.67 : 1.0;
}
