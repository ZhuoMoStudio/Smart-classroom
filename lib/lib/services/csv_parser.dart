import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/question_bank.dart';

class CsvParser {
  static QuestionBank parse(String csvContent, String bankName) {
    final lines = LineSplitter.split(csvContent).toList();
    if (lines.isEmpty) return QuestionBank(uid: const Uuid().v4(), name: bankName);

    int startIndex = 0;
    if (lines[0].startsWith('\uFEFF')) lines[0] = lines[0].substring(1);
    final firstLineLower = lines[0].toLowerCase();
    if (firstLineLower.contains('题目') || firstLineLower.contains('答案') || firstLineLower.contains('风险')) {
      startIndex = 1;
    }

    final questions = <Question>[];
    for (int i = startIndex; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.isEmpty) continue;
      final text = parts[0].trim();
      if (text.isEmpty) continue;
      final answer = parts.length > 1 && parts[1].trim().isNotEmpty ? parts[1].trim() : null;
      bool isRisk = false;
      if (parts.length > 2) {
        final riskStr = parts[2].trim().toLowerCase();
        isRisk = riskStr == '是' || riskStr == 'y' || riskStr == 'yes' || riskStr == '1';
      }
      questions.add(Question(
        uid: const Uuid().v4(),
        index: questions.length + 1,
        text: text,
        answer: answer,
        isRisk: isRisk,
      ));
    }
    return QuestionBank(uid: const Uuid().v4(), name: bankName, questions: questions);
  }

  static Future<QuestionBank> parseFromFile(String path) async {
    final file = File(path);
    final content = await file.readAsString(encoding: utf8);
    final name = path.split('/').last.replaceAll('.csv', '');
    return parse(content, name);
  }
}