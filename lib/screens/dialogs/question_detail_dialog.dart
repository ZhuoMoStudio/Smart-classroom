import 'package:flutter/material.dart';
import '../../models/question_bank.dart';

class QuestionDetailDialog extends StatelessWidget {
  final Question question;
  const QuestionDetailDialog({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: question.isRisk
                  ? Colors.red.shade50
                  : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#${question.index}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: question.isRisk ? Colors.red.shade700 : theme.colorScheme.primary,
              ),
            ),
          ),
          if (question.isRisk) ...[
            const SizedBox(width: 8),
            const Icon(Icons.warning_amber, color: Colors.red, size: 22),
            const SizedBox(width: 4),
            Text('风险题', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
          if (question.used) ...[
            const Spacer(),
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
            const SizedBox(width: 4),
            Text('已答', style: TextStyle(color: Colors.green.shade600, fontSize: 13)),
          ],
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.isRisk)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此题为风险题（难题），答对可获得额外加分',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              question.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontSize: 17,
              ),
            ),
          ),
          if (question.answer != null && question.answer!.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('查看答案'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade300),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Row(children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 6),
                    const Text('参考答案'),
                  ]),
                  content: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(question.answer!, style: const TextStyle(fontSize: 16)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check, size: 18),
          label: const Text('关闭（标记已答）'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
