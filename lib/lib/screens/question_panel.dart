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
    final qState = ref.watch(questionProvider);
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        FilterChip(label: const Text('全部'), selected: qState.selectedBankUid == null && !qState.mixMode,
            onSelected: (_) => ref.read(questionProvider.notifier).selectBank(null)),
        const SizedBox(width: 4),
        ...qState.banks.map((bank) => Padding(padding: const EdgeInsets.only(right: 4), child: ChoiceChip(
              label: Text(bank.name),
              selected: qState.selectedBankUid == bank.uid,
              onSelected: (_) => ref.read(questionProvider.notifier).selectBank(bank.uid),
            ))),
        const SizedBox(width: 8),
        Checkbox(value: qState.mixMode, onChanged: (_) => ref.read(questionProvider.notifier).toggleMixMode()),
        const Text('混合模式'),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.upload_file), tooltip: '导入 CSV', onPressed: () => _importCsv(ref, context)),
      ])),
      const SizedBox(height: 8),
      Expanded(child: _buildGrid(context, qState, theme, ref)),
      const SizedBox(height: 8),
      _buildStatusBar(qState, theme, ref),
    ]);
  }

  Widget _buildGrid(BuildContext context, QuestionState qState, ThemeData theme, WidgetRef ref) {
    final questions = qState.allQuestions;
    if (questions.isEmpty) return const Center(child: Text('暂无题目，请导入 CSV'));
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 1.2, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index];
        Color bg = theme.colorScheme.surfaceContainerHighest;
        if (q.used) bg = Colors.grey.shade300;
        Border? border;
        if (q.isRisk) border = const Border(left: BorderSide(color: Colors.red, width: 3));
        if (q.answer != null && q.answer!.isNotEmpty) border = const Border(bottom: BorderSide(color: Colors.green, width: 3));
        return GestureDetector(
          onTap: () => _openDetail(context, q, ref),
          child: Container(
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6),
                border: border ?? Border.all(color: theme.colorScheme.outline.withOpacity(0.2))),
            child: Center(child: Text('${q.index}', style: TextStyle(decoration: q.used ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold))),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(QuestionState qState, ThemeData theme, WidgetRef ref) {
    final questions = qState.allQuestions;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('风险题: ${questions.where((q) => q.isRisk).length}'),
      Text('已答: ${questions.where((q) => q.used).length}'),
      TextButton(
        onPressed: () {
          final bank = qState.selectedBank;
          if (bank != null) ref.read(questionProvider.notifier).resetAllUsed(bank.uid);
        },
        child: const Text('重置已答'),
      ),
    ]);
  }

  void _openDetail(BuildContext context, Question q, WidgetRef ref) {
    showDialog(context: context, builder: (_) => QuestionDetailDialog(question: q)).then((_) {
      final qState = ref.read(questionProvider);
      for (final bank in qState.banks) {
        if (bank.questions.any((x) => x.uid == q.uid)) {
          ref.read(questionProvider.notifier).markUsed(bank.uid, q.uid);
          break;
        }
      }
    });
  }

  Future<void> _importCsv(WidgetRef ref, BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final bank = await CsvParser.parseFromFile(path);
    ref.read(questionProvider.notifier).addBank(bank);
    ToastOverlay.show(context, '导入题库: ${bank.name} (${bank.questions.length}题)');
  }
}