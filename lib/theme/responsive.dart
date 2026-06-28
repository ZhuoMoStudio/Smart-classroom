import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// 响应式布局工具
/// 基于屏幕宽度判断布局模式，不依赖 Platform 平台类型
enum ScreenType { mobile, tablet, teaching }

extension ScreenTypeX on BuildContext {
  ScreenType get screenType {
    final w = MediaQuery.of(this).size.width;
    final h = MediaQuery.of(this).size.height;
    if (w >= 1400 && h >= 900) return ScreenType.teaching;
    if (w >= 768) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  bool get isTeachingLayout => screenType == ScreenType.teaching;
  bool get isMobileLayout => screenType == ScreenType.mobile;
  bool get isTabletLayout => screenType == ScreenType.tablet;
}

/// 教学模式下获取缩放系数
class TeachingScale {
  /// 基础字体缩放（手机16px → 大屏36px，比例 2.25x）
  static double textScale(bool isTeaching) => isTeaching ? 2.25 : 1.0;

  /// 触控热区缩放
  static double touchScale(bool isTeaching) => isTeaching ? 1.67 : 1.0;

  /// 图标缩放
  static double iconScale(bool isTeaching) => isTeaching ? 2.5 : 1.0;

  /// 间距缩放
  static double spacingScale(bool isTeaching) => isTeaching ? 2.0 : 1.0;

  /// 教学模式下获取动态字号
  static double fontSize(bool isTeaching, double mobileSize) =>
      isTeaching ? mobileSize * 2.25 : mobileSize;

  /// 教学模式下获取动态尺寸
  static double size(bool isTeaching, double mobileSize) =>
      isTeaching ? mobileSize * 1.67 : mobileSize;
}


