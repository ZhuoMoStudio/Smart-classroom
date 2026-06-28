import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// 统一的主题配置
class AppTheme {
  static ThemeData _base(Brightness brightness) {
    final cs = ColorScheme.fromSeed(seedColor: AppColors.brandPrimary, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: const TextTheme(
        displaySmall: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        titleLarge: AppTypography.h3,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.label,
        labelSmall: AppTypography.caption,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppRadius.input),
        contentPadding: AppSpacing.inputPadding,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: AppTouchTarget.mobileBtnSize,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: AppTouchTarget.mobileBtnSize),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: AppTouchTarget.mobileBtnSize),
      ),
      dividerTheme: const DividerThemeData(space: 0, thickness: 1),
    );
  }

  /// 教学大屏主题 — 浅色暖色高对比
  static ThemeData teaching() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        brightness: Brightness.light,
        surface: AppColors.teachingBg,
      ),
      scaffoldBackgroundColor: AppColors.teachingBg,
      textTheme: const TextTheme(
        displaySmall: AppTypography.teachingH1,
        headlineMedium: AppTypography.teachingH2,
        titleLarge: AppTypography.teachingH3,
        bodyLarge: AppTypography.teachingBody,
        bodyMedium: AppTypography.teachingBody,
        bodySmall: AppTypography.teachingBodySmall,
        labelLarge: AppTypography.teachingLabel,
        labelSmall: AppTypography.teachingBodySmall,
      ),
      visualDensity: VisualDensity.standard,
      // 大屏卡片
      cardTheme: CardThemeData(
        elevation: 2,
        color: AppColors.teachingSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(12),
      ),
      // 大屏输入框
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        labelStyle: const TextStyle(fontSize: 28),
        hintStyle: const TextStyle(fontSize: 28),
      ),
      // 大屏按钮
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: AppTouchTarget.teachingBtnSize,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: AppTouchTarget.teachingBtnSize,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 28),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: AppTouchTarget.teachingBtnSize,
          iconSize: 48,
        ),
      ),
      // 大屏无 hover
      hoverColor: Colors.transparent,
      splashColor: AppColors.brandPrimary.withOpacity(0.2),
      highlightColor: AppColors.brandPrimary.withOpacity(0.1),
      // 大屏滚动条加粗
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(AppScrollbar.teachingThickness),
        radius: const Radius.circular(7),
        thumbColor: WidgetStateProperty.all(AppColors.neutral300),
      ),
      dividerTheme: const DividerThemeData(space: 0, thickness: 2),
    );
  }

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);
}
