import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: Brightness.light);
    return ThemeData(useMaterial3: true, colorScheme: cs,
      cardTheme: CardTheme(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));
  }
  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: Brightness.dark);
    return ThemeData(useMaterial3: true, colorScheme: cs,
      cardTheme: CardTheme(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));
  }
}
