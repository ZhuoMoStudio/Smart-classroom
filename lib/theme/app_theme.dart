import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// iOS 苹果透明磨砂玻璃拟态主题
class AppTheme {
  static ThemeData _base(Brightness brightness) {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
      surface: AppColors.background,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.compact,
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.frostCard,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xB3F2F2F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialog),
        elevation: 0,
        backgroundColor: AppColors.frostPopup,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        elevation: 0,
        modalBackgroundColor: AppColors.frostPopup,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0, scrolledUnderElevation: 0.5, centerTitle: true,
        backgroundColor: Colors.transparent, foregroundColor: AppColors.textPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.frostBar,
        indicatorColor: AppColors.brandPrimary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.brandPrimary);
          }
          return const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
        }),
      ),
      dividerTheme: const DividerThemeData(space: 0, thickness: 0.5, color: Color(0x1A8E8E93)),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4.0),
        radius: const Radius.circular(2),
        thumbColor: WidgetStateProperty.all(AppColors.textTertiary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);
}