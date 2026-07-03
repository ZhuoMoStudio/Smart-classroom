import 'dart:ui' show Brightness;
import 'package:flutter/material.dart';

// ====================================================================
// iOS 18 / macOS Sonoma 极简设计令牌系统
// ====================================================================

// ==================== 颜色系统 ====================
class AppColors {
  // 品牌色 — 低饱和浅蓝
  static const Color brandPrimary = Color(0xFF6B8EFF);
  static const Color brandPrimaryLight = Color(0xFFA8C0FF);
  static const Color brandSecondary = Color(0xFF8B8BA7);

  // 功能色 — 柔和低饱和
  static const Color success = Color(0xFF7EC8A3);
  static const Color warning = Color(0xFFF0C27A);
  static const Color error = Color(0xFFE89292);
  static const Color info = Color(0xFF7AB8E8);

  // 浅色主题
  static const Color surface = Color(0xFFF8F9FC);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE8EAF0);
  static const Color onSurface = Color(0xFF1C1C1E);
  static const Color onSurfaceSecondary = Color(0xFF8E8E93);
  static const Color onSurfaceTertiary = Color(0xFFC7C7CC);

  // 磨砂玻璃效果色
  static const Color frostWhite = Color(0xE6FFFFFF);
  static const Color frostLight = Color(0xB3F2F2F7);
  static const Color frostBorder = Color(0x4D8E8E93);

  // 中性色阶（兼容旧引用）
  static const Color neutral200 = Color(0xFFE8E8ED);
  static const Color neutral300 = Color(0xFFD1D1D6);
  static const Color neutral400 = Color(0xFFAEAEB2);
  static const Color neutral500 = Color(0xFF8E8E93);
  static const Color neutral600 = Color(0xFF636366);
  static const Color neutral700 = Color(0xFF48484A);

  // 卡片浅投影
  static Color cardShadow = Colors.black.withOpacity(0.04);

  // 大屏教学色
  static const Color teachingBg = Color(0xFFFFF8F0);
  static const Color teachingSurface = Color(0xFFFFFBF5);
  static const Color teachingText = Color(0xFF1A1A1A);
  static const Color teachingBorder = Color(0xFFD4C5A9);
}

// ==================== 字体系统 ====================
class AppTypography {
  // SF Pro 近似 — title
  static const TextStyle h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.3);
  static const TextStyle h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: -0.2);
  static const TextStyle h3 = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3);
  // body
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodyMedium = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodySmall = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45);
  // label
  static const TextStyle label = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.35, color: Color(0xFF8E8E93));
  // 大屏
  static const TextStyle teachingH1 = TextStyle(fontSize: 56, fontWeight: FontWeight.w700, height: 1.2);
  static const TextStyle teachingH2 = TextStyle(fontSize: 48, fontWeight: FontWeight.w600, height: 1.25);
  static const TextStyle teachingH3 = TextStyle(fontSize: 40, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle teachingBody = TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 1.6);
  static const TextStyle teachingBodySmall = TextStyle(fontSize: 32, height: 1.5);
  static const TextStyle teachingLabel = TextStyle(fontSize: 28, fontWeight: FontWeight.w500, height: 1.4);
}

// ==================== 间距系统 ====================
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const EdgeInsets pagePadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const double teachingSafeMargin = 40;
}

// ==================== 圆角 ====================
class AppRadius {
  // iOS 18 统一 20px 大圆角
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20; // 默认大圆角
  static const double xxl = 28;
  static const double round = 999;

  static BorderRadius get card => BorderRadius.circular(xl);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get chip => BorderRadius.circular(xxl);
  static BorderRadius get input => BorderRadius.circular(md);
}

// ==================== 投影 ====================
class AppShadows {
  // 轻薄柔和投影（无硬阴影）
  static List<BoxShadow> get level1 => [
    BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get level2 => [
    BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get level3 => [
    BoxShadow(color: AppColors.cardShadow, blurRadius: 24, offset: const Offset(0, 8)),
  ];
}

// ==================== 触控热区 ====================
class AppTouchTarget {
  static const double mobileMin = 48;
  static const Size mobileBtnSize = Size(mobileMin, mobileMin);
  static const double teachingMin = 80;
  static const Size teachingBtnSize = Size(teachingMin, teachingMin);
  static double minSize(bool isTeaching) => isTeaching ? teachingMin : mobileMin;
  static Size btnSize(bool isTeaching) => isTeaching ? teachingBtnSize : mobileBtnSize;
  static const double teachingBottomDeadZone = 20;
}

// ==================== 断点 ====================
class AppBreakpoints {
  static const double mobile = 0;
  static const double tablet = 768;
  static const double desktop = 1200;
  static const double teachingWidth = 1400;
  static const double teachingHeight = 900;
}

// ==================== 动效 ====================
class AppDuration {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration toast = Duration(seconds: 2);
  static const Duration autoSaveDefault = Duration(seconds: 30);
  static const Duration controlsHide = Duration(seconds: 5);
  static const Duration drawAnimation = Duration(milliseconds: 1200);
  static const Duration teachingFeedback = Duration(milliseconds: 150);
}

// ==================== 滚动条 ====================
class AppScrollbar {
  static const double teachingThickness = 14.0;
  static const double mobileThickness = 6.0;
  static double thickness(bool isTeaching) => isTeaching ? teachingThickness : mobileThickness;
}
