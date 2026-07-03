import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// iOS 18 / macOS Sonoma 极简主题
class AppTheme {
  // ==================== 基础主题 ====================
  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      // 苹方 / SF Pro 近似字体系列
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
      // 视觉密度
      visualDensity: VisualDensity.compact,
      // ==== 卡片 — 磨砂玻璃风格 ====
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? AppColors.frostWhite : AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: AppColors.frostBorder, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      // ==== 输入框 — 大圆角 ====
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.frostLight : null,
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      // ==== 按钮 — 大圆角 + 无投影 ====
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          side: BorderSide(color: AppColors.frostBorder),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      // ==== 导航 ====
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        titleTextStyle: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.onSurface,
        ),
      ),
      // 底部导航栏（iOS 风格）
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isLight ? AppColors.frostWhite : null,
        indicatorColor: AppColors.brandPrimary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.brandPrimary);
          }
          return const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.onSurfaceSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 22, color: AppColors.brandPrimary);
          }
          return const IconThemeData(size: 22, color: AppColors.onSurfaceSecondary);
        }),
      ),
      // ==== 分割线 ====
      dividerTheme: const DividerThemeData(
        space: 0,
        thickness: 0.5,
        color: Color(0x1A8E8E93),
      ),
      // ==== 分割按钮 ====
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          selectedBackgroundColor: AppColors.brandPrimary.withOpacity(0.12),
        ),
      ),
      // ==== 滚动条 ====
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4.0),
        radius: const Radius.circular(2),
        thumbColor: WidgetStateProperty.all(AppColors.onSurfaceTertiary),
      ),
      // ==== Chip ====
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      // ==== 弹出菜单 ====
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        elevation: 2,
        shadowColor: AppColors.cardShadow,
      ),
    );
  }

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);
}
