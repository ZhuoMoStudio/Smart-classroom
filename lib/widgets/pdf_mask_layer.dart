import 'package:flutter/material.dart';
import 'dart:ui' show Canvas, Paint, Path, Rect, Offset, Size;
import 'pdf_annotation.dart';

/// 蒙层渲染层 — 在 PDF 之上绘制半透明蒙层和揭示区域
///
/// 支持多种蒙层方向：
/// - leftToRight / rightToLeft：水平逐渐揭示
/// - topToBottom / bottomToTop：垂直逐渐揭示
/// - centerOut：中心向外扩散
/// - clickReveal：点击逐步揭示（透明度渐变）
class MaskPaintLayer extends StatelessWidget {
  final AnnotationController controller;
  final int currentPage;
  final Size viewSize;

  const MaskPaintLayer({
    super.key,
    required this.controller,
    required this.currentPage,
    required this.viewSize,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final mask = controller.maskState;
        if (!mask.enabled || mask.isFullyRevealed) {
          return const SizedBox.shrink();
        }

        return CustomPaint(
          size: viewSize,
          painter: _MaskPainter(controller: controller, page: currentPage),
        );
      },
    );
  }
}

class _MaskPainter extends CustomPainter {
  final AnnotationController controller;
  final int page;

  _MaskPainter({required this.controller, required this.page});

  @override
  void paint(Canvas canvas, Size size) {
    final mask = controller.maskState;
    if (!mask.enabled || mask.isFullyRevealed) return;

    if (mask.direction == MaskDirection.clickReveal) {
      // 点击模式：整体半透明遮罩
      final paint = Paint()
        ..color = Colors.black.withOpacity(controller.maskOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    // 其他方向：绘制未揭示区域
    final revealRect = controller.getMaskClipRect(page, size);
    if (revealRect == null) {
      // 全屏遮罩
      final paint = Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    // 画布背景遮罩
    final maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // 上
    if (revealRect.top > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, revealRect.top),
        maskPaint,
      );
    }
    // 下
    if (revealRect.bottom < size.height) {
      canvas.drawRect(
        Rect.fromLTWH(0, revealRect.bottom, size.width, size.height - revealRect.bottom),
        maskPaint,
      );
    }
    // 左
    if (revealRect.left > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, revealRect.top, revealRect.left, revealRect.height),
        maskPaint,
      );
    }
    // 右
    if (revealRect.right < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(revealRect.right, revealRect.top, size.width - revealRect.right, revealRect.height),
        maskPaint,
      );
    }

    // 揭示区域边缘高亮
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(revealRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) => true;
}

/// 蒙层控制面板
class MaskControlPanel extends StatelessWidget {
  final AnnotationController controller;
  final VoidCallback onClose;

  const MaskControlPanel({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final mask = controller.maskState;
        final theme = Theme.of(context);

        return Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.level2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  const Icon(Icons.mask, size: 20, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    '蒙层设置',
                    style: theme.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  // 启用/禁用
                  Switch(
                    value: mask.enabled,
                    onChanged: (v) {
                      controller.toggleMask();
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 蒙层方向选择
              Text(
                '揭示方向',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _directionChip(
                    Icons.arrow_forward,
                    '从左到右',
                    MaskDirection.leftToRight,
                    mask,
                    controller,
                  ),
                  _directionChip(
                    Icons.arrow_back,
                    '从右到左',
                    MaskDirection.rightToLeft,
                    mask,
                    controller,
                  ),
                  _directionChip(
                    Icons.arrow_downward,
                    '从上到下',
                    MaskDirection.topToBottom,
                    mask,
                    controller,
                  ),
                  _directionChip(
                    Icons.arrow_upward,
                    '从下到上',
                    MaskDirection.bottomToTop,
                    mask,
                    controller,
                  ),
                  _directionChip(
                    Icons.center_focus_strong,
                    '中心扩散',
                    MaskDirection.centerOut,
                    mask,
                    controller,
                  ),
                  _directionChip(
                    Icons.touch_app,
                    '点击揭示',
                    MaskDirection.clickReveal,
                    mask,
                    controller,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 进度滑条（点击模式除外）
              if (mask.direction != MaskDirection.clickReveal) ...[
                Row(
                  children: [
                    Text(
                      '揭示进度',
                      style: theme.textTheme.labelMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${(mask.progress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Slider(
                  value: mask.progress,
                  min: 0,
                  max: 1.0,
                  divisions: 100,
                  activeColor: Colors.purple,
                  onChanged: (v) => controller.setMaskProgress(v),
                ),
              ],

              // 点击模式提示
              if (mask.direction == MaskDirection.clickReveal)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: Colors.purple.shade300),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '点击PDF画面即可逐步揭示内容',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.purple.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (mask.direction != MaskDirection.clickReveal) ...[
                const SizedBox(height: 8),
                // 快速预设
                Wrap(
                  spacing: 4,
                  children: [0.25, 0.5, 0.75, 1.0].map((p) {
                    return ActionChip(
                      label: Text('${(p * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.setMaskProgress(p),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 8),
              // 关闭蒙层按钮
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.mask_off, size: 16),
                  label: const Text('关闭蒙层'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  onPressed: () {
                    controller.toggleMask();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _directionChip(
    IconData icon,
    String label,
    MaskDirection direction,
    MaskState mask,
    AnnotationController ctrl,
  ) {
    final selected = mask.direction == direction;
    return FilterChip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => ctrl.setMaskDirection(direction),
      visualDensity: VisualDensity.compact,
      selectedColor: Colors.purple.withOpacity(0.12),
      checkmarkColor: Colors.purple,
    );
  }
}
