import 'package:flutter/material.dart';

/// Design Token 系统 — 统一设计令牌
/// 所有颜色、字体、间距、圆角、阴影必须通过此类获取，禁止硬编码

// ==================== 颜色系统 ====================
class AppColors {
  // 品牌色
  static const Color brandPrimary = Color(0xFF6750A4);
  static const Color brandPrimaryLight = Color(0xFFD0BCFF);
  static const Color brandSecondary = Color(0xFF625B71);

  // 功能色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // 中性色阶
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF5F5F5);
  static const Color neutral100 = Color(0xFFE0E0E0);
  static const Color neutral200 = Color(0xFFBDBDBD);
  static const Color neutral300 = Color(0xFF9E9E9E);
  static const Color neutral400 = Color(0xFF757575);
  static const Color neutral500 = Color(0xFF616161);
  static const Color neutral600 = Color(0xFF424242);
  static const Color neutral700 = Color(0xFF303030);
  static const Color neutral800 = Color(0xFF212121);
  static const Color neutral900 = Color(0xFF000000);

  // 大屏/教室模式 — 高对比度暖色背景（抗反光、易看清）
  static const Color teachingBg = Color(0xFFFFF8F0);       // 暖黄白底
  static const Color teachingSurface = Color(0xFFFFFBF5);   // 卡片面
  static const Color teachingText = Color(0xFF1A1A1A);      // 近黑色文字
  static const Color teachingTextSecondary = Color(0xFF4A4A4A);
  static const Color teachingBorder = Color(0xFFD4C5A9);

  // 风险题专用色
  static const Color riskBg = Color(0xFFFFEBEE);
  static const Color riskBorder = Color(0xFFE53935);
  static const Color riskText = Color(0xFFC62828);

  // 答案专用色
  static const Color answerBg = Color(0xFFE8F5E9);
  static const Color answerBorder = Color(0xFF4CAF50);
  static const Color answerText = Color(0xFF2E7D32);

  // 抽取按钮色
  static const Color drawMember = Color(0xFF6750A4);
  static const Color drawGroup = Color(0xFF00897B);

  // 排名色
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankBronze = Color(0xFFCD7F32);
}

// ==================== 字体系统（手机端） ====================
class AppTypography {
  static const TextStyle h1 = TextStyle(fontSize: 34, fontWeight: FontWeight.bold, height: 1.2);
  static const TextStyle h2 = TextStyle(fontSize: 26, fontWeight: FontWeight.w600, height: 1.25);
  static const TextStyle h3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, height: 1.6);
  static const TextStyle bodyMedium = TextStyle(fontSize: 15, height: 1.6);
  static const TextStyle bodySmall = TextStyle(fontSize: 13, height: 1.5);
  static const TextStyle label = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle caption = TextStyle(fontSize: 12, height: 1.4);
  static const TextStyle overline = TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.0, height: 1.3);

  // ==================== 大屏/教学端字体（希沃100寸） ====================
  static const TextStyle teachingH1 = TextStyle(fontSize: 56, fontWeight: FontWeight.bold, height: 1.2);
  static const TextStyle teachingH2 = TextStyle(fontSize: 48, fontWeight: FontWeight.w600, height: 1.25);
  static const TextStyle teachingH3 = TextStyle(fontSize: 40, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle teachingBody = TextStyle(fontSize: 36, height: 1.6);
  static const TextStyle teachingBodySmall = TextStyle(fontSize: 32, height: 1.5);
  static const TextStyle teachingLabel = TextStyle(fontSize: 28, fontWeight: FontWeight.w500, height: 1.4);
}

// ==================== 间距系统（4px 基准） ====================
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
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: lg, vertical: 14);

  // 大屏间距
  static const EdgeInsets teachingPagePadding = EdgeInsets.all(40);
  static const double teachingSafeMargin = 40;
}

// ==================== 圆角系统 ====================
class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double round = 999;
  static const double teachingButton = 16;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get chip => BorderRadius.circular(xxl);
  static BorderRadius get input => BorderRadius.circular(md);
  static BorderRadius get teachingBtn => BorderRadius.circular(teachingButton);
}

// ==================== 阴影系统 ====================
class AppShadows {
  static List<BoxShadow> get level1 => [BoxShadow(color: AppColors.neutral900.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))];
  static List<BoxShadow> get level2 => [BoxShadow(color: AppColors.neutral900.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))];
  static List<BoxShadow> get level3 => [BoxShadow(color: AppColors.neutral900.withOpacity(0.16), blurRadius: 16, offset: const Offset(0, 8))];
}

// ==================== 触控热区 ====================
class AppTouchTarget {
  /// 手机端最小 48dp
  static const double mobileMin = 48;
  static const Size mobileBtnSize = Size(mobileMin, mobileMin);

  /// 大屏端最小 80px（约 3cm 物理尺寸，适应悬空手臂操作）
  static const double teachingMin = 80;
  static const Size teachingBtnSize = Size(teachingMin, teachingMin);

  /// 根据模式返回最小触控尺寸
  static double minSize(bool isTeaching) => isTeaching ? teachingMin : mobileMin;
  static Size btnSize(bool isTeaching) => isTeaching ? teachingBtnSize : mobileBtnSize;

  /// 大屏底部死区高度（防掌误触）
  static const double teachingBottomDeadZone = 20;
}

// ==================== 响应式断点 ====================
class AppBreakpoints {
  static const double mobile = 0;
  static const double tablet = 768;
  static const double desktop = 1200;
  /// 大屏教学模式的宽度阈值（>1400px 且高度 >900px 自动启用）
  static const double teachingWidth = 1400;
  static const double teachingHeight = 900;

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < tablet;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= tablet && MediaQuery.of(context).size.width < desktop;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= desktop;

  /// 判断是否应启用大屏教学模式（基于物理尺寸，不依赖 Platform）
  static bool isTeachingLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= teachingWidth && size.height >= teachingHeight;
  }
}

// ==================== 动效时间 ====================
class AppDuration {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration toast = Duration(seconds: 2);
  static const Duration autoSaveDefault = Duration(seconds: 30);
  static const Duration controlsHide = Duration(seconds: 5);
  static const Duration drawAnimation = Duration(milliseconds: 1200);
  /// 大屏点击反馈动效时长
  static const Duration teachingFeedback = Duration(milliseconds: 150);
}

// ==================== 滚动条（大屏加粗） ====================
class AppScrollbar {
  static const double teachingThickness = 14.0;
  static const double mobileThickness = 6.0;

  static double thickness(bool isTeaching) => isTeaching ? teachingThickness : mobileThickness;
}
