import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// 统一的主题配置
/// 使用 Design Token 系统，确保全局一致性
class AppTheme {
  static ThemeData _base(Brightness brightness) {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      // 统一字体
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
      // 统一触控热区
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // 统一卡片
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),
      // 统一输入框
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppRadius.input),
        contentPadding: AppSpacing.inputPadding,
      ),
      // 统一按钮
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: AppTouchTarget.buttonMinSize,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: AppTouchTarget.buttonMinSize),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: AppTouchTarget.buttonMinSize),
      ),
    );
  }

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);
}
