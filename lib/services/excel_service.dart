import 'dart:io';
import 'package:excel/excel.dart';
import '../models/question_bank.dart';
import '../models/class_model.dart';

/// Excel 解析服务：支持 xlsx 名单导入、题库导入、模板导出、积分导入导出
/// 使用 excel 3.x 稳定版 API
class ExcelService {
  // ==================== 题库导入 ====================
  /// 从 Excel 文件解析题库
  /// 预期列：题目 | 答案(可选) | 是否为风险题(是/否/1/0/Y/N)
  static Future<QuestionBank> parseQuestionBank(
      String filePath, String bankName) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet]!;

    final questions = <Question>[];
    int questionIndex = 0;
    bool firstRow = true;

    for (int i = 0; i < table.maxRows; i++) {
      if (firstRow) {
        firstRow = false;
        final firstCell = _cell(table, i, 0);
        if (firstCell.contains('题目') ||
            firstCell.contains('问题') ||
            firstCell.contains('Question') ||
            firstCell.contains('题干')) {
          continue;
        }
      }

      final text = _cell(table, i, 0).trim();
      if (text.isEmpty) continue;

      questionIndex++;
      final answer = _cell(table, i, 1).trim();
      final hasAnswer = answer.isNotEmpty;
      final riskStr = _cell(table, i, 2).trim().toLowerCase();
      final isRisk = riskStr == '是' ||
          riskStr == 'y' ||
          riskStr == 'yes' ||
          riskStr == '1' ||
          riskStr == 'true' ||
          riskStr == '√' ||
          riskStr == '✓';

      questions.add(Question(
        uid: _uuid(),
        index: questionIndex,
        text: text,
        answer: hasAnswer ? answer : null,
        isRisk: isRisk,
      ));
    }

    return QuestionBank(
      uid: _uuid(),
      name: bankName,
      questions: questions,
    );
  }

  // ==================== 学生名单导入 ====================
  /// 从 Excel 文件解析班级名单
  /// 预期列：班级 | 小组 | 姓名
  static Future<List<Classroom>> parseRoster(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet]!;

    final classMap = <String, Classroom>{};
    final groupMap = <String, Map<String, Group>>{};
    bool firstRow = true;

    for (int i = 0; i < table.maxRows; i++) {
      if (firstRow) {
        firstRow = false;
        final firstCell = _cell(table, i, 0);
        if (firstCell.contains('班级') ||
            firstCell.contains('班') ||
            firstCell.contains('Class')) {
          continue;
        }
      }

      final className = _cell(table, i, 0).trim();
      final groupName = _cell(table, i, 1).trim();
      final memberName = _cell(table, i, 2).trim();

      if (className.isEmpty || memberName.isEmpty) continue;
      final groupNameFinal = groupName.isEmpty ? '默认小组' : groupName;

      if (!classMap.containsKey(className)) {
        classMap[className] = Classroom(uid: _uuid(), name: className);
        groupMap[className] = {};
      }

      if (!groupMap[className]!.containsKey(groupNameFinal)) {
        final g = Group(uid: _uuid(), name: groupNameFinal);
        groupMap[className]![groupNameFinal] = g;
      }

      final g = groupMap[className]![groupNameFinal]!;
      g.members.add(Member(uid: _uuid(), name: memberName));
    }

    return classMap.entries.map((entry) {
      final cls = entry.value;
      final groups = groupMap[entry.key]!.values.toList();
      return cls.copyWith(groups: groups);
    }).toList();
  }

  // ==================== 积分导出 ====================
  /// 导出积分到 Excel 文件
  /// 列：班级 | 小组 | 姓名 | 积分 | 段位
  static Future<File> exportScores(
      List<Classroom> classrooms, String outputPath) async {
    final excel = Excel.createExcel();
    final sheet = excel['积分数据'];

    // 表头
    sheet.appendRow([
      TextCellValue('班级'),
      TextCellValue('小组'),
      TextCellValue('姓名'),
      TextCellValue('积分'),
      TextCellValue('段位'),
    ]);

    for (final classroom in classrooms) {
      for (final group in classroom.groups) {
        final sorted = List<Member>.from(group.members)
          ..sort((a, b) => b.score.compareTo(a.score));
        for (final member in sorted) {
          final (rankName, _) = RankSystem.getRank(member.score);
          sheet.appendRow([
            TextCellValue(classroom.name),
            TextCellValue(group.name),
            TextCellValue(member.name),
            DoubleCellValue(member.score),
            TextCellValue(rankName),
          ]);
        }
      }
    }

    final bytes = excel.encode()!;
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  // ==================== 积分导入 ====================
  /// 从 Excel 导入积分数据
  /// 预期列：班级 | 小组 | 姓名 | 积分
  static Future<Map<String, Map<String, Map<String, double>>>> importScores(
      String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet]!;

    final result = <String, Map<String, Map<String, double>>>{};
    bool firstRow = true;

    for (int i = 0; i < table.maxRows; i++) {
      if (firstRow) {
        firstRow = false;
        continue;
      }

      final className = _cell(table, i, 0).trim();
      final groupName = _cell(table, i, 1).trim();
      final memberName = _cell(table, i, 2).trim();
      final scoreStr = _cell(table, i, 3).trim();

      if (className.isEmpty || memberName.isEmpty || scoreStr.isEmpty) {
        continue;
      }
      final groupNameFinal = groupName.isEmpty ? '默认小组' : groupName;
      final score = double.tryParse(scoreStr) ?? 0;

      result.putIfAbsent(className, () => {});
      result[className]!.putIfAbsent(groupNameFinal, () => {});
      result[className]![groupNameFinal]![memberName] = score;
    }

    return result;
  }

  // ==================== 模板导出 ====================
  /// 导出学生名单模板
  static Future<File> exportMemberTemplate(String outputPath) async {
    final excel = Excel.createExcel();
    final sheet = excel['学生名单'];

    sheet.appendRow([
      TextCellValue('班级'),
      TextCellValue('小组'),
      TextCellValue('姓名'),
    ]);
    sheet.appendRow([
      TextCellValue('三年级1班'),
      TextCellValue('第一组'),
      TextCellValue('张三'),
    ]);
    sheet.appendRow([
      TextCellValue('三年级1班'),
      TextCellValue('第一组'),
      TextCellValue('李四'),
    ]);

    final bytes = excel.encode()!;
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// 导出题库模板
  static Future<File> exportQuestionTemplate(String outputPath) async {
    final excel = Excel.createExcel();
    final sheet = excel['题库'];

    sheet.appendRow([
      TextCellValue('题目'),
      TextCellValue('答案'),
      TextCellValue('是否为风险题'),
    ]);
    sheet.appendRow([
      TextCellValue('1+1等于几？'),
      TextCellValue('2'),
      TextCellValue('否'),
    ]);
    sheet.appendRow([
      TextCellValue('中国的首都是哪里？'),
      TextCellValue('北京'),
      TextCellValue('是'),
    ]);

    final bytes = excel.encode()!;
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  // ==================== 辅助 ====================
  static String _cell(Sheet sheet, int row, int col) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: col, rowIndex: row));
    return cell?.value?.toString() ?? '';
  }

  static String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = (now * 9301 + 49297) % 233280;
    return '${now.toRadixString(36)}-${rand.toRadixString(36)}-${(rand ^ now).toRadixString(36)}';
  }
}
