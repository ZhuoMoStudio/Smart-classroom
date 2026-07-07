import 'dart:ui' show Brightness;
import 'package:flutter/material.dart';

class AppColors {
  static const Color brandPrimary = Color(0xFF5E7EFF);
  static const Color brandPrimaryLight = Color(0xFF9DB5FF);
  static const Color brandPrimaryDark = Color(0xFF3A5AD9);
  static const Color brandSecondary = Color(0xFF8B8BA7);
  static const Color success = Color(0xFF7EC8A3);
  static const Color warning = Color(0xFFF0C27A);
  static const Color error = Color(0xFFE89292);
  static const Color info = Color(0xFF7AB8E8);
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE8EAF0);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);
  static const Color frostBar = Color(0xE6FFFFFF);
  static const Color frostCard = Color(0xD9F2F2F7);
  static const Color frostPopup = Color(0xCCF0F0F5);
  static const Color frostDark = Color(0x993C3C43);
  static const Color frostBorder = Color(0x338E8E93);
  static const Color neutral500 = Color(0xFF8E8E93);
  static Color get shadowLight => Colors.black.withOpacity(0.04);
  static Color get shadowMedium => Colors.black.withOpacity(0.08);
  static const Color neutral200 = Color(0xFFE8E8ED);
  static const Color neutral300 = Color(0xFFD1D1D6);
  static const Color neutral400 = Color(0xFFAEAEB2);
  static const Color neutral600 = Color(0xFF636366);
  static const Color neutral700 = Color(0xFF48484A);

}

class AppRadius {
  static const double sm=8, md=12, lg=16, xl=20, xxl=28;
  static BorderRadius get card => BorderRadius.circular(xl);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get dialog => BorderRadius.circular(xxl);
}

class AppShadows {
  static List<BoxShadow> get level1 => [BoxShadow(color:AppColors.shadowLight,blurRadius:8,offset:Offset(0,2))];
  static List<BoxShadow> get level2 => [BoxShadow(color:AppColors.shadowLight,blurRadius:12,offset:Offset(0,4)),BoxShadow(color:AppColors.shadowMedium,blurRadius:4,offset:Offset(0,1))];
  static List<BoxShadow> get level3 => [BoxShadow(color:AppColors.shadowLight,blurRadius:24,offset:Offset(0,8)),BoxShadow(color:AppColors.shadowMedium,blurRadius:8,offset:Offset(0,2))];
}

class AppBreakpoints {
  static const double mobile=0, tablet=768, desktop=1200;
}


class AppDuration {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration spring = Duration(milliseconds: 400);
}
