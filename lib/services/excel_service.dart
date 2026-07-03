import 'dart:io';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../models/question_bank.dart';
import '../models/class_model.dart';

class ExcelService {
  // ========== 题库导入 ==========
  static Future<QuestionBank> parseQuestionBank(
    String filePath,
    String bankName,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet]!;
    final questions = <Question>[];
    int qi = 0;
    for (int i = 0; i < table.maxRows; i++) {
      if (i == 0) {
        final fc = _cell(table, i, 0);
        if (fc.contains('题目') ||
            fc.contains('问题') ||
            fc.contains('Question') ||
            fc.contains('题干'))
          continue;
      }
      final text = _cell(table, i, 0).trim();
      if (text.isEmpty) continue;
      qi++;
      final answer = _cell(table, i, 1).trim();
      final riskStr = _cell(table, i, 2).trim().toLowerCase();
      final isRisk =
          riskStr == '是' ||
          riskStr == 'y' ||
          riskStr == 'yes' ||
          riskStr == '1' ||
          riskStr == 'true' ||
          riskStr == '√' ||
          riskStr == '✓';
      questions.add(
        Question(
          uid: _uid(),
          index: qi,
          text: text,
          answer: answer.isNotEmpty ? answer : null,
          isRisk: isRisk,
        ),
      );
    }
    return QuestionBank(uid: _uid(), name: bankName, questions: questions);
  }

  // ========== 名单导入 ==========
  static Future<List<Classroom>> parseRoster(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet]!;
    final classMap = <String, Classroom>{};
    final classMembers = <String, Map<String, List<Member>>>{};
    for (int i = 0; i < table.maxRows; i++) {
      if (i == 0) {
        final fc = _cell(table, i, 0);
        if (fc.contains('班级') || fc.contains('班') || fc.contains('Class'))
          continue;
      }
      final cn = _cell(table, i, 0).trim(),
          gn = _cell(table, i, 1).trim(),
          mn = _cell(table, i, 2).trim();
      if (cn.isEmpty || mn.isEmpty) continue;
      final gnf = gn.isEmpty ? '默认小组' : gn;
      if (!classMap.containsKey(cn)) {
        classMap[cn] = Classroom(uid: _uid(), name: cn);
        classMembers[cn] = {};
      }
      if (!classMembers[cn]!.containsKey(gnf)) {
        classMembers[cn]![gnf] = [];
      }
      classMembers[cn]![gnf]!.add(Member(uid: _uid(), name: mn));
    }
    return classMap.entries.map((e) {
      final cn = e.key;
      final groups =
          (classMembers[cn] ?? {}).entries
              .map(
                (ge) => Group(
                  uid: _uid(),
                  name: ge.key,
                  members: List.unmodifiable(ge.value),
                ),
              )
              .toList();
      return e.value.copyWith(groups: groups);
    }).toList();
  }

  // ========== 积分导出 (excel 3.x API: List<dynamic>) ==========
  static Future<File> exportScores(
    List<Classroom> classrooms,
    String outputPath,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['积分数据'];
    sheet.appendRow(<dynamic>['班级', '小组', '姓名', '积分', '段位']);
    for (final c in classrooms) {
      for (final g in c.groups) {
        final sorted = List<Member>.from(g.members)
          ..sort((a, b) => b.score.compareTo(a.score));
        for (final m in sorted) {
          final (rn, _) = RankSystem.getRank(m.score);
          sheet.appendRow(<dynamic>[c.name, g.name, m.name, m.score, rn]);
        }
      }
    }
    final b = excel.encode()!;
    final f = File(outputPath);
    await f.writeAsBytes(b);
    return f;
  }

  // ========== 积分导入 ==========
  static Future<Map<String, Map<String, Map<String, double>>>> importScores(
    String filePath,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet]!;
    final res = <String, Map<String, Map<String, double>>>{};
    for (int i = 1; i < table.maxRows; i++) {
      final cn = _cell(table, i, 0).trim(),
          gn = _cell(table, i, 1).trim(),
          mn = _cell(table, i, 2).trim(),
          ss = _cell(table, i, 3).trim();
      if (cn.isEmpty || mn.isEmpty || ss.isEmpty) continue;
      final gnf = gn.isEmpty ? '默认小组' : gn;
      final sc = double.tryParse(ss) ?? 0;
      res.putIfAbsent(cn, () => {});
      res[cn]!.putIfAbsent(gnf, () => {});
      res[cn]![gnf]![mn] = sc;
    }
    return res;
  }

  // ========== 模板导出 ==========
  static Future<File> exportMemberTemplate(String outputPath) async {
    // 确保目录存在
    final dir = Directory(outputPath).parent;
    if (!await dir.exists()) await dir.create(recursive: true);
    final excel = Excel.createExcel();
    final sheet = excel['学生名单'];
    sheet.appendRow(<dynamic>['班级', '小组', '姓名']);
    sheet.appendRow(<dynamic>['三年级1班', '第一组', '张三']);
    sheet.appendRow(<dynamic>['三年级1班', '第一组', '李四']);
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel 编码失败');
    final f = File(outputPath);
    await f.writeAsBytes(bytes);
    return f;
  }

  static Future<File> exportQuestionTemplate(String outputPath) async {
    // 确保目录存在
    final dir = Directory(outputPath).parent;
    if (!await dir.exists()) await dir.create(recursive: true);
    final excel = Excel.createExcel();
    final sheet = excel['题库'];
    sheet.appendRow(<dynamic>['题目', '答案', '是否为风险题']);
    sheet.appendRow(<dynamic>['1+1等于几？', '2', '否']);
    sheet.appendRow(<dynamic>['中国的首都是哪里？', '北京', '是']);
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel 编码失败');
    final f = File(outputPath);
    await f.writeAsBytes(bytes);
    return f;
  }

  static String _cell(Sheet sheet, int row, int col) {
    final c = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    return c?.value?.toString() ?? '';
  }

  static String _uid() => const Uuid().v4();
}
