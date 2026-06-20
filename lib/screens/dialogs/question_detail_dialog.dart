import 'package:flutter/material.dart';
import '../../models/question_bank.dart';

class QuestionDetailDialog extends StatelessWidget {
  final Question question;
  const QuestionDetailDialog({super.key, required this.question});

  @override
  Widget build(BuildContext ctx) {
    return AlertDialog(title: Text('题目 #${question.index}'), content: Column(
      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (question.isRisk) Container(padding: const EdgeInsets.all(8), color: Colors.red.shade50,
        child: const Row(children: [Icon(Icons.warning, color: Colors.red, size: 18),
          SizedBox(width: 4), Text('风险题', style: TextStyle(color: Colors.red))])),
      const SizedBox(height: 12),
      Text(question.text, style: Theme.of(ctx).textTheme.bodyLarge),
      if (question.answer != null && question.answer!.isNotEmpty) ...[
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => showDialog(context: ctx, builder: (_) => AlertDialog(
          title: const Text('答案'), content: Text(question.answer!),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))])),
          child: const Text('查看答案')),
      ],
    ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('关闭（标记已答）'))]);
  }
}
