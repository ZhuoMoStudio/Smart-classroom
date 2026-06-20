import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/question_provider.dart';
import '../models/question_bank.dart';
import '../services/csv_parser.dart';
import '../widgets/toast_overlay.dart';
import 'dialogs/question_detail_dialog.dart';

class QuestionPanel extends ConsumerWidget {
  const QuestionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qs = ref.watch(questionProvider); final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        FilterChip(label: const Text('全部'), selected: qs.selectedBankUid == null && !qs.mixMode,
            onSelected: (_) => ref.read(questionProvider.notifier).selectBank(null)),
        const SizedBox(width: 4),
        ...qs.banks.map((b) => Padding(padding: const EdgeInsets.only(right: 4), child: ChoiceChip(
          label: Text(b.name), selected: qs.selectedBankUid == b.uid,
          onSelected: (_) => ref.read(questionProvider.notifier).selectBank(b.uid),
        ))),
        const SizedBox(width: 8),
        Checkbox(value: qs.mixMode, onChanged: (_) => ref.read(questionProvider.notifier).toggleMixMode()),
        const Text('混合模式'),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.upload_file), tooltip: '导入 CSV', onPressed: () => _import(ref, context)),
      ])),
      const SizedBox(height: 8),
      Expanded(child: _grid(context, qs, t, ref)),
      const SizedBox(height: 8),
      _statusBar(qs, t, ref),
    ]);
  }

  Widget _grid(BuildContext ctx, QuestionState qs, ThemeData t, WidgetRef ref) {
    final qlist = qs.allQuestions;
    if (qlist.isEmpty) return const Center(child: Text('暂无题目，请导入 CSV'));
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 1.2, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: qlist.length,
      itemBuilder: (ctx, i) {
        final q = qlist[i];
        Color bg = t.colorScheme.surfaceContainerHighest;
        if (q.used) bg = Colors.grey.shade300;
        Border? bd;
        if (q.isRisk) bd = const Border(left: BorderSide(color: Colors.red, width: 3));
        if (q.answer != null && q.answer!.isNotEmpty) bd = const Border(bottom: BorderSide(color: Colors.green, width: 3));
        return GestureDetector(
          onTap: () => _detail(ctx, q, ref),
          child: Container(
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6),
                border: bd ?? Border.all(color: t.colorScheme.outline.withOpacity(0.2))),
            child: Center(child: Text('${q.index}', style: TextStyle(
                decoration: q.used ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold))),
          ),
        );
      },
    );
  }

  Widget _statusBar(QuestionState qs, ThemeData t, WidgetRef ref) {
    final qlist = qs.allQuestions;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('风险题: ${qlist.where((q) => q.isRisk).length}'),
      Text('已答: ${qlist.where((q) => q.used).length}'),
      TextButton(onPressed: () {
        final b = qs.selectedBank; if (b != null) ref.read(questionProvider.notifier).resetAllUsed(b.uid);
      }, child: const Text('重置已答')),
    ]);
  }

  void _detail(BuildContext ctx, Question q, WidgetRef ref) {
    showDialog(context: ctx, builder: (_) => QuestionDetailDialog(question: q)).then((_) {
      final qs = ref.read(questionProvider);
      for (final b in qs.banks) { if (b.questions.any((x) => x.uid == q.uid)) { ref.read(questionProvider.notifier).markUsed(b.uid, q.uid); break; } }
    });
  }

  Future<void> _import(WidgetRef ref, BuildContext ctx) async {
    final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (r == null || r.files.isEmpty) return;
    final p = r.files.single.path; if (p == null) return;
    final b = await CsvParser.parseFromFile(p);
    ref.read(questionProvider.notifier).addBank(b);
    ToastOverlay.show(ctx, '导入题库: ${b.name} (${b.questions.length}题)');
  }
}
