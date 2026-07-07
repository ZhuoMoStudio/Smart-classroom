import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 苹果透明磨砂玻璃组件 — v1.30 深色模式适配
class FrostedPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding, margin;
  final double? width, height;
  final Color? backgroundColor, borderColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const FrostedPanel({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.darkFrostCard : AppColors.frostCard);
    final br = borderRadius ?? AppRadius.card;
    final bc = borderColor ??
        (isDark ? AppColors.darkFrostBorder : AppColors.frostBorder);
    final bs = boxShadow ??
        (isDark ? AppShadows.darkLevel2 : AppShadows.level2);
    final pad = padding ?? const EdgeInsets.all(12);
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            padding: pad,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: br,
              border: Border.all(color: bc, width: 0.5),
              boxShadow: bs,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 简易磨砂卡片（旧接口兼容 + 深色模式适配）
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 8.0,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isDark
                    ? AppColors.darkFrostCard
                    : Colors.white.withOpacity(0.55)),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkFrostBorder
                  : Colors.grey.withOpacity(0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
