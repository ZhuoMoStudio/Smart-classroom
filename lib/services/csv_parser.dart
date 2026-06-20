import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/question_bank.dart';

class CsvParser {
  static QuestionBank parse(String content, String bankName) {
    final lines = LineSplitter.split(content).toList();
    if (lines.isEmpty) return QuestionBank(uid: const Uuid().v4(), name: bankName);
    int si = 0;
    if (lines[0].startsWith('\uFEFF')) lines[0] = lines[0].substring(1);
    final fl = lines[0].toLowerCase();
    if (fl.contains('题目') || fl.contains('答案') || fl.contains('风险')) si = 1;
    final qs = <Question>[];
    for (int i = si; i < lines.length; i++) {
      final parts = lines[i].split(','); if (parts.isEmpty) continue;
      final text = parts[0].trim(); if (text.isEmpty) continue;
      final answer = parts.length > 1 && parts[1].trim().isNotEmpty ? parts[1].trim() : null;
      bool isRisk = false;
      if (parts.length > 2) {
        final rs = parts[2].trim().toLowerCase();
        isRisk = rs == '是' || rs == 'y' || rs == 'yes' || rs == '1';
      }
      qs.add(Question(uid: const Uuid().v4(), index: qs.length + 1, text: text, answer: answer, isRisk: isRisk));
    }
    return QuestionBank(uid: const Uuid().v4(), name: bankName, questions: qs);
  }

  static Future<QuestionBank> parseFromFile(String path) async {
    final content = await File(path).readAsString(encoding: utf8);
    return parse(content, path.split('/').last.replaceAll('.csv', ''));
  }
}
