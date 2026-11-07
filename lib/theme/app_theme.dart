import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// iOS 苹果透明磨砂玻璃拟态主题 — v1.30 深色模式适配
///
/// 这里只放**全局**样式：颜色、圆角、组件默认值。
/// 页面里不要再散落 `Colors.white` / `AppColors.textSecondary` 这类
/// 只对浅色成立的常量 —— 深色模式下它们会变成「黑字黑底」。
class AppTheme {
  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final frostCard = isDark ? AppColors.darkFrostCard : AppColors.frostCard;
    final frostPopup =
        isDark ? AppColors.darkFrostPopup : AppColors.frostPopup;
    final frostBar = isDark ? AppColors.darkFrostBar : AppColors.frostBar;

    // 浅色/深色各自的主次文字色。页面里的次要文字一律取 colorScheme，
    // 不要直接取 AppColors.textSecondary（那只是浅色主题的值）。
    final onSurface =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final onSurfaceVariant =
        isDark ? AppColors.darkTextSecondary : AppColors.neutral600;
    final tertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.neutral400;

    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
      surface: bg,
    );

    // 文字层级跟随亮度：默认的 body/display 颜色在深色下由 colorScheme 决定，
    // 这里再 apply 一次，是为了让直接使用 textTheme 的地方也拿到正确颜色。
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = base.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      visualDensity: VisualDensity.compact,
      iconTheme: IconThemeData(color: onSurface, size: 22),
      cardTheme: CardThemeData(
        elevation: 0,
        color: frostCard,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.7)
            : const Color(0xB3F2F2F7),
        hintStyle: TextStyle(color: tertiary, fontSize: 14),
        labelStyle: TextStyle(color: onSurfaceVariant, fontSize: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.brandPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error, width: 1)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          elevation: 0,
          minimumSize: const Size(64, 44),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          minimumSize: const Size(56, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          minimumSize: const Size(64, 44),
          side: BorderSide(color: AppColors.brandPrimary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return Colors.white;
          return isDark ? AppColors.darkSurfaceDim : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.brandPrimary;
          return isDark ? AppColors.neutral700 : AppColors.neutral300;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurfaceVariant,
        textColor: onSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceDim.withValues(alpha: 0.96)
              : AppColors.neutral700.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.darkSurfaceDim : AppColors.neutral700,
        contentTextStyle: const TextStyle(fontSize: 13, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandPrimary,
        linearTrackColor: Color(0x1A5E7EFF),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialog),
        elevation: 0,
        backgroundColor: frostPopup,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        elevation: 0,
        modalBackgroundColor: frostPopup,
        backgroundColor: frostPopup,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: frostBar,
        indicatorColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary);
          }
          return TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: onSurfaceVariant);
        }),
      ),
      dividerTheme: DividerThemeData(
          space: 0, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.5)),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4.0),
        radius: const Radius.circular(2),
        thumbColor: WidgetStateProperty.all(tertiary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);
}
