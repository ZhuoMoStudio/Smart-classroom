import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 基础组件库 — 统一的可复用 UI 组件
/// 遵循 Atomic Design 原则：原子组件（Atom）

// ==================== 统一卡片 ====================
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xs),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: padding ?? AppSpacing.cardPadding,
          child: child,
        ),
      ),
    );
  }
}

// ==================== 统一标题区域 ====================
class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  const SectionTitle({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
        ],
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ==================== 统一空状态 ====================
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.bodyLarge.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.outline.withOpacity(0.7)), textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(icon: Icon(icon, size: 16), label: Text(actionLabel!), onPressed: onAction),
          ],
        ]),
      ),
    );
  }
}

// ==================== 统一加载状态 ====================
class LoadingState extends StatelessWidget {
  final String? message;
  final double? progress;
  const LoadingState({super.key, this.message, this.progress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 48, height: 48,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          )),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(message!, style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        ],
        if (progress != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('${(progress! * 100).toStringAsFixed(0)}%',
            style: AppTypography.caption.copyWith(color: Theme.of(context).colorScheme.outline)),
        ],
      ]),
    );
  }
}

// ==================== 统一错误状态 ====================
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              onPressed: onRetry,
            ),
          ],
        ]),
      ),
    );
  }
}

// ==================== 统一确认对话框 ====================
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final VoidCallback onConfirm;
  const ConfirmDialog({super.key, required this.title, required this.content, required this.onConfirm, this.confirmLabel = '确认', this.cancelLabel = '取消', this.confirmColor});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(cancelLabel)),
        FilledButton(
          style: confirmColor != null ? FilledButton.styleFrom(backgroundColor: confirmColor) : null,
          onPressed: () { Navigator.pop(context); onConfirm(); },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
