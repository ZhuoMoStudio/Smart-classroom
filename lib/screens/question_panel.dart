import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/question_provider.dart';
import '../models/question_bank.dart';
import '../services/excel_service.dart';
import '../theme/responsive.dart';
import '../widgets/toast_overlay.dart';
import 'dialogs/question_detail_dialog.dart';

class QuestionPanel extends ConsumerWidget {
  const QuestionPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qs = ref.watch(questionProvider);
    final t = Theme.of(context);
    final teaching = context.isTeachingLayout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 题目标签栏（可横向滚动）
        SizedBox(
          height: teaching ? 72 : 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(bottom: teaching ? 8 : 4),
            children: [
              FilterChip(
                label: Text('全部', style: TextStyle(fontSize: teaching ? 28 : null)),
                selected: qs.selectedBankUid == null && !qs.mixMode,
                onSelected: (_) => ref.read(questionProvider.notifier).selectBank(null),
              ),
              SizedBox(width: teaching ? 12 : 4),
              ...qs.banks.map((bank) {
                final selected = qs.selectedBankUid == bank.uid;
                return Padding(
                  padding: EdgeInsets.only(right: teaching ? 12 : 4),
                  child: ChoiceChip(
                    label: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(bank.name, style: TextStyle(fontSize: teaching ? 28 : null)),
                      if (selected) ...[
                        SizedBox(width: teaching ? 12 : 4),
                        GestureDetector(
                          onTap: () {
                            showDialog(context: context, builder: (ctx) => AlertDialog(
                              title: const Text('删除题库'),
                              content: Text('确定删除题库「${bank.name}」吗？'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                                FilledButton(onPressed: () {
                                  final updated = qs.banks.where((b) => b.uid != bank.uid).toList();
                                  ref.read(questionProvider.notifier).loadFromData(updated);
                                  Navigator.pop(ctx);
                                  ToastOverlay.show(context, '已删除题库: ${bank.name}');
                                }, child: const Text('删除')),
                              ],
                            ));
                          },
                          child: Icon(Icons.close, size: teaching ? 28 : 14, color: Colors.red),
                        ),
                      ],
                    ]),
                    selected: selected,
                    onSelected: (_) => ref.read(questionProvider.notifier).selectBank(bank.uid),
                  ),
                );
              }),
              SizedBox(width: teaching ? 16 : 8),
              // 混合模式
              Row(mainAxisSize: MainAxisSize.min, children: [
                Checkbox(
                  value: qs.mixMode,
                  onChanged: (_) => ref.read(questionProvider.notifier).toggleMixMode(),
                  visualDensity: teaching ? VisualDensity.standard : VisualDensity.compact,
                  materialTapTargetSize: teaching ? MaterialTapTargetSize.padded : MaterialTapTargetSize.shrinkWrap,
                ),
                Text('混合模式', style: TextStyle(fontSize: teaching ? 28 : 13)),
              ]),
              SizedBox(width: teaching ? 12 : 4),
              IconButton(
                icon: Icon(Icons.upload_file, size: teaching ? 48 : 20),
                tooltip: '导入 Excel',
                onPressed: () => _import(ref, context),
              ),
              IconButton(
                icon: Icon(Icons.shuffle, size: teaching ? 48 : 20),
                tooltip: '随机选题',
                onPressed: () => _random(ref, context),
              ),
            ],
          ),
        ),
        SizedBox(height: teaching ? 16 : 8),
        Expanded(child: _grid(qs, t, ref, context, teaching)),
        SizedBox(height: teaching ? 16 : 8),
        _statusBar(qs, t, ref, context, teaching),
      ],
    );
  }

  Widget _grid(QuestionState qs, ThemeData t, WidgetRef ref, BuildContext ctx, bool teaching) {
    final qlist = qs.allQuestions;
    if (qlist.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.quiz_outlined, size: teaching ? 80 : 32, color: t.colorScheme.outline),
        SizedBox(height: teaching ? 24 : 8),
        Text('暂无题目', style: t.textTheme.bodyMedium?.copyWith(fontSize: teaching ? 32 : null, color: t.colorScheme.outline)),
        SizedBox(height: teaching ? 12 : 4),
        Text('点击导入按钮添加 Excel 题库', style: t.textTheme.bodySmall?.copyWith(fontSize: teaching ? 28 : null, color: t.colorScheme.outline)),
        SizedBox(height: teaching ? 24 : 12),
        OutlinedButton.icon(
          icon: Icon(Icons.upload_file, size: teaching ? 32 : 16),
          label: Text('导入 Excel', style: TextStyle(fontSize: teaching ? 28 : null)),
          onPressed: () => _import(ref, ctx),
        ),
      ]));
    }
    return LayoutBuilder(
      builder: (ctx, cs) {
        final cc = teaching ? 8 : (cs.maxWidth > 400 ? 6 : 4);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cc,
            childAspectRatio: teaching ? 1.5 : 1.3,
            crossAxisSpacing: teaching ? 12 : 4,
            mainAxisSpacing: teaching ? 12 : 4,
          ),
          itemCount: qlist.length,
          itemBuilder: (ctx, i) {
            final q = qlist[i];
            Color bg = t.colorScheme.surfaceContainerHighest;
            if (q.used) bg = t.brightness == Brightness.light ? Colors.grey.shade300 : Colors.grey.shade800;
            BorderSide? left, bottom;
            if (q.isRisk) left = BorderSide(color: Colors.red, width: teaching ? 6 : 3);
            if (q.answer != null && q.answer!.isNotEmpty) bottom = BorderSide(color: Colors.green, width: teaching ? 6 : 3);
            return GestureDetector(
              onTap: () => _detail(ctx, q, ref),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(teaching ? 16 : 6),
                  border: Border(
                    left: left ?? BorderSide.none,
                    bottom: bottom ?? BorderSide.none,
                    top: BorderSide(color: t.colorScheme.outline.withOpacity(0.15)),
                    right: BorderSide(color: t.colorScheme.outline.withOpacity(0.15)),
                  ),
                ),
                child: Center(child: Text('${q.index}', style: TextStyle(
                  fontSize: teaching ? 36 : null,
                  decoration: q.used ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                  color: q.used ? t.colorScheme.outline : t.colorScheme.onSurface,
                ))),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusBar(QuestionState qs, ThemeData t, WidgetRef ref, BuildContext ctx, bool teaching) {
    final qlist = qs.allQuestions;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: teaching ? 24 : 8, vertical: teaching ? 16 : 4),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(teaching ? 16 : 8),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.warning_amber, size: teaching ? 32 : 14, color: Colors.red),
          SizedBox(width: teaching ? 8 : 4),
          Text('风险题: ${qlist.where((q) => q.isRisk).length}', style: TextStyle(fontSize: teaching ? 28 : null)),
          SizedBox(width: teaching ? 24 : 16),
          Icon(Icons.check_circle, size: teaching ? 32 : 14, color: Colors.green),
          SizedBox(width: teaching ? 8 : 4),
          Text('已答: ${qlist.where((q) => q.used).length} / ${qlist.length}', style: TextStyle(fontSize: teaching ? 28 : null)),
        ]),
        TextButton.icon(
          icon: Icon(Icons.refresh, size: teaching ? 32 : 14),
          label: Text('重置已答', style: TextStyle(fontSize: teaching ? 24 : null)),
          style: TextButton.styleFrom(
            visualDensity: teaching ? VisualDensity.standard : VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: teaching ? 24 : 8),
          ),
          onPressed: () {
            final b = qs.selectedBank;
            if (b != null) { ref.read(questionProvider.notifier).resetAllUsed(b.uid); ToastOverlay.show(ctx, '已重置题库: ${b.name}'); }
            else { ToastOverlay.show(ctx, '请先选择一个题库'); }
          },
        ),
      ]),
    );
  }

  void _detail(BuildContext ctx, Question q, WidgetRef ref) {
    showDialog<bool>(context: ctx, builder: (_) => QuestionDetailDialog(question: q)).then((marked) {
      if (marked == true) {
        final qs = ref.read(questionProvider);
        for (final b in qs.banks) {
          if (b.questions.any((x) => x.uid == q.uid)) { ref.read(questionProvider.notifier).markUsed(b.uid, q.uid); break; }
        }
      }
    });
  }

  Future<void> _import(WidgetRef ref, BuildContext ctx) async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
    if (r == null || r.files.isEmpty) return;
    final p = r.files.single.path;
    if (p == null) return;
    try {
      final bn = p.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.(xlsx|xls)$'), '');
      final bank = await ExcelService.parseQuestionBank(p, bn);
      ref.read(questionProvider.notifier).addBank(bank);
      ToastOverlay.show(ctx, '导入成功: ${bank.name} (${bank.questions.length} 题)');
    } catch (e) { ToastOverlay.show(ctx, '导入失败: $e'); }
  }

  void _random(WidgetRef ref, BuildContext ctx) {
    final q = ref.read(questionProvider.notifier).getRandomUnusedNonRisk();
    if (q == null) { ToastOverlay.show(ctx, '没有可用的题目'); return; }
    _detail(ctx, q, ref);
  }
}
