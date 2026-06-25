import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/question_provider.dart';
import '../models/question_bank.dart';
import '../services/excel_service.dart';
import '../widgets/toast_overlay.dart';
import 'dialogs/question_detail_dialog.dart';

class QuestionPanel extends ConsumerWidget {
  const QuestionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qs = ref.watch(questionProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            FilterChip(
              label: const Text('全部'),
              selected: qs.selectedBankUid == null && !qs.mixMode,
              onSelected: (_) => ref.read(questionProvider.notifier).selectBank(null),
            ),
            const SizedBox(width: 4),
            ...qs.banks.map((bank) {
              final selected = qs.selectedBankUid == bank.uid;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(bank.name),
                    if (selected) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('删除题库'),
                              content: Text('确定删除题库「${bank.name}」吗？'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                                FilledButton(
                                  onPressed: () {
                                    final updated = qs.banks.where((b) => b.uid != bank.uid).toList();
                                    ref.read(questionProvider.notifier).loadFromData(updated);
                                    Navigator.pop(ctx);
                                    ToastOverlay.show(context, '已删除题库: ${bank.name}');
                                  },
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(Icons.close, size: 14, color: Colors.red),
                      ),
                    ],
                  ]),
                  selected: selected,
                  onSelected: (_) => ref.read(questionProvider.notifier).selectBank(bank.uid),
                ),
              );
            }),
            const SizedBox(width: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Checkbox(
                value: qs.mixMode,
                onChanged: (_) => ref.read(questionProvider.notifier).toggleMixMode(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const Text('混合模式', style: TextStyle(fontSize: 13)),
            ]),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.upload_file, size: 20),
              tooltip: '导入 Excel',
              onPressed: () => _importExcel(ref, context),
            ),
            IconButton(
              icon: const Icon(Icons.shuffle, size: 20),
              tooltip: '随机选题',
              onPressed: () => _randomPick(ref, context),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildGrid(context, qs, theme, ref)),
        const SizedBox(height: 8),
        _buildStatusBar(qs, theme, ref),
      ],
    );
  }

  Widget _buildGrid(BuildContext ctx, QuestionState qs, ThemeData t, WidgetRef ref) {
    final qlist = qs.allQuestions;
    if (qlist.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.quiz_outlined, size: 32, color: t.colorScheme.outline),
          const SizedBox(height: 8),
          Text('暂无题目', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.outline)),
          const SizedBox(height: 4),
          Text('点击导入按钮添加 Excel 题库', style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('导入 Excel'),
            onPressed: () => _importExcel(ref, ctx),
          ),
        ]),
      );
    }

    return LayoutBuilder(builder: (ctx, constraints) {
      final crossAxisCount = constraints.maxWidth > 400 ? 6 : 4;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: qlist.length,
        itemBuilder: (ctx, i) {
          final q = qlist[i];
          Color bg = t.colorScheme.surfaceContainerHighest;
          if (q.used) bg = t.brightness == Brightness.light ? Colors.grey.shade300 : Colors.grey.shade800;

          BorderSide? left, bottom;
          if (q.isRisk) left = const BorderSide(color: Colors.red, width: 3);
          if (q.answer != null && q.answer!.isNotEmpty) bottom = const BorderSide(color: Colors.green, width: 3);

          return GestureDetector(
            onTap: () => _detail(ctx, q, ref),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  left: left ?? BorderSide.none,
                  bottom: bottom ?? BorderSide.none,
                  top: BorderSide(color: t.colorScheme.outline.withOpacity(0.15)),
                  right: BorderSide(color: t.colorScheme.outline.withOpacity(0.15)),
                ),
              ),
              child: Center(
                child: Text(
                  '${q.index}',
                  style: TextStyle(
                    decoration: q.used ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.bold,
                    color: q.used ? t.colorScheme.outline : t.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildStatusBar(QuestionState qs, ThemeData t, WidgetRef ref) {
    final qlist = qs.allQuestions;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber, size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Text('风险题: ${qlist.where((q) => q.isRisk).length}', style: t.textTheme.bodySmall),
          const SizedBox(width: 16),
          const Icon(Icons.check_circle, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text('已答: ${qlist.where((q) => q.used).length} / ${qlist.length}', style: t.textTheme.bodySmall),
        ]),
        TextButton.icon(
          icon: const Icon(Icons.refresh, size: 14),
          label: const Text('重置已答'),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
          onPressed: () {
            final b = qs.selectedBank;
            if (b != null) {
              ref.read(questionProvider.notifier).resetAllUsed(b.uid);
              ToastOverlay.show(context, '已重置题库: ${b.name}');
            } else {
              ToastOverlay.show(context, '请先选择一个题库');
            }
          },
        ),
      ]),
    );
  }

  void _detail(BuildContext ctx, Question q, WidgetRef ref) {
    showDialog(context: ctx, builder: (_) => QuestionDetailDialog(question: q)).then((_) {
      final qs = ref.read(questionProvider);
      for (final b in qs.banks) {
        if (b.questions.any((x) => x.uid == q.uid)) {
          ref.read(questionProvider.notifier).markUsed(b.uid, q.uid);
          break;
        }
      }
    });
  }

  Future<void> _importExcel(WidgetRef ref, BuildContext ctx) async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (r == null || r.files.isEmpty) return;
    final p = r.files.single.path;
    if (p == null) return;

    try {
      final bankName = p.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.(xlsx|xls)$'), '');
      final bank = await ExcelService.parseQuestionBank(p, bankName);
      ref.read(questionProvider.notifier).addBank(bank);
      ToastOverlay.show(ctx, '导入成功: ${bank.name} (${bank.questions.length} 题)');
    } catch (e) {
      ToastOverlay.show(ctx, '导入失败: $e');
    }
  }

  void _randomPick(WidgetRef ref, BuildContext ctx) {
    final q = ref.read(questionProvider.notifier).getRandomUnusedNonRisk();
    if (q == null) {
      ToastOverlay.show(ctx, '没有可用的题目');
      return;
    }
    _detail(ctx, q, ref);
  }
}
