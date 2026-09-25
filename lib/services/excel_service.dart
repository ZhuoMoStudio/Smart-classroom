import 'dart:io';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../models/question_bank.dart';
import '../models/class_model.dart';

/// 名单 xlsx 的列布局。
///
/// 为什么要把这套定义集中到一处：
/// 写入端（writeRosterWithScores）写了「班级/小组/姓名/积分」四列，
/// 而读取端（parseRoster）只读了前三列、从未读积分列 —— 两边没有任何共享约束，
/// 于是「保存时写进去、再次打开就归零」这个致命错误可以安然活到 v1.31。
/// 现在表头、列索引、识别规则都从这里取，读写不可能再漂移。
abstract final class RosterLayout {
  static const int className = 0;
  static const int groupName = 1;
  static const int memberName = 2;
  static const int score = 3;

  /// 本应用自己写出的名单文件一定用这个表头
  static const List<String> header = ['班级', '小组', '姓名', '积分'];

  /// 表中出现这个列名即认为小组列存在
  static const String groupMarker = '组';
}

/// 一个名单文件的解析结果。
///
/// [isAppFormat] 区分「本应用保存的文件」与「老师自己导入的原始名单」。
/// 工作区目录同时充当导入投放点与持久化目标，同一个班级可能同时存在于
/// 两类文件里（例如导入的 `我的名单.xlsx` 与保存出的 `三年二班.xlsx`），
/// 不加区分地拼接会让班级列表出现重复项，因此需要这个标记来定权威。
class ParsedRosterFile {
  final String filePath;
  final List<Classroom> classrooms;
  final bool isAppFormat;

  const ParsedRosterFile({
    required this.filePath,
    required this.classrooms,
    required this.isAppFormat,
  });
}

class ExcelService {
  // ========== 题库导入 ==========
  static Future<QuestionBank> parseQuestionBank(
    String filePath,
    String bankName,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final table = _dataSheet(excel);
    final questions = <Question>[];
    int qi = 0;
    for (int i = 0; i < table.maxRows; i++) {
      if (i == 0 && _looksLikeQuestionHeader(_cell(table, i, 0))) continue;
      final text = _cell(table, i, 0).trim();
      if (text.isEmpty) continue;
      qi++;
      final answer = _cell(table, i, 1).trim();
      questions.add(
        Question(
          uid: _uid(),
          index: qi,
          text: text,
          answer: answer.isNotEmpty ? answer : null,
          isRisk: _isTruthy(_cell(table, i, 2)),
        ),
      );
    }
    return QuestionBank(uid: _uid(), name: bankName, questions: questions);
  }

  // ========== 名单导入 ==========
  static Future<List<Classroom>> parseRoster(String filePath) async =>
      (await parseRosterFile(filePath)).classrooms;

  /// 解析名单文件，并告知它是不是本应用自己保存出来的。
  static Future<ParsedRosterFile> parseRosterFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final table = _dataSheet(excel);

    final layout = _detectRosterLayout(table);
    final classMap = <String, Classroom>{};
    final classMembers = <String, Map<String, List<Member>>>{};

    for (int i = 0; i < table.maxRows; i++) {
      if (layout.headerRow == i) continue;

      final cn = _cell(table, i, layout.classCol).trim();
      final mn = _cell(table, i, layout.nameCol).trim();
      if (cn.isEmpty || mn.isEmpty) continue;

      final rawGroup = layout.hasGroup
          ? _cell(table, i, layout.groupCol).trim()
          : '';
      final gn = rawGroup.isEmpty
          ? (layout.hasGroup ? '默认小组' : '全体')
          : rawGroup;

      // 关键修复：积分列以前从未被读取，Member.score 一律落到默认值 0.0，
      // 于是老师加了一节课的分，重启后全部归零。
      final score = layout.hasScore ? _cellNum(table, i, layout.scoreCol) : 0.0;

      classMap.putIfAbsent(cn, () => Classroom(uid: _uid(), name: cn));
      classMembers.putIfAbsent(cn, () => {});
      classMembers[cn]!.putIfAbsent(gn, () => []);
      classMembers[cn]![gn]!.add(Member(uid: _uid(), name: mn, score: score));
    }

    final classrooms = classMap.entries.map((e) {
      final groups = (classMembers[e.key] ?? {}).entries
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

    return ParsedRosterFile(
      filePath: filePath,
      classrooms: classrooms,
      isAppFormat: layout.matchesAppHeader,
    );
  }

  // ========== 积分导出 ==========
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
    return _writeWorkbook(excel, outputPath);
  }

  // ========== 积分导入 ==========
  static Future<Map<String, Map<String, Map<String, double>>>> importScores(
    String filePath,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final table = _dataSheet(excel);
    final res = <String, Map<String, Map<String, double>>>{};
    for (int i = 0; i < table.maxRows; i++) {
      final cn = _cell(table, i, 0).trim();
      final gn = _cell(table, i, 1).trim();
      final mn = _cell(table, i, 2).trim();
      if (cn.isEmpty || mn.isEmpty) continue;
      if (i == 0 && cn.contains('班')) continue; // 表头
      final gnf = gn.isEmpty ? '默认小组' : gn;
      res.putIfAbsent(cn, () => {});
      res[cn]!.putIfAbsent(gnf, () => {});
      res[cn]![gnf]![mn] = _cellNum(table, i, 3);
    }
    return res;
  }

  // ========== 写入班级名单（含积分）到 xlsx ==========

  /// 表头必须与 [RosterLayout.header] 完全一致：
  /// loadAllRosters 靠它识别「这是应用自己的文件」，从而判定权威与陈旧。
  static Future<File> writeRosterWithScores(
    Classroom classroom,
    String outputPath,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['班级数据'];
    sheet.appendRow(<dynamic>[...RosterLayout.header]);
    for (final group in classroom.groups) {
      for (final member in group.members) {
        sheet.appendRow(<dynamic>[
          classroom.name,
          group.name,
          member.name,
          member.score,
        ]);
      }
    }
    return _writeWorkbook(excel, outputPath);
  }

  // ========== 模板导出 ==========
  static Future<File> exportMemberTemplate(String outputPath) async {
    final excel = Excel.createExcel();
    final sheet = excel['学生名单'];
    sheet.appendRow(<dynamic>['班级', '姓名', '积分']);
    sheet.appendRow(<dynamic>['示例班级', '示例学生', '0']);
    return _writeWorkbook(excel, outputPath);
  }

  static Future<File> exportQuestionTemplate(String outputPath) async {
    final excel = Excel.createExcel();
    final sheet = excel['题库'];
    sheet.appendRow(<dynamic>['题目', '答案', '是否为风险题']);
    sheet.appendRow(<dynamic>['1+1', '', '否']);
    sheet.appendRow(<dynamic>['2+2', '', '否']);
    sheet.appendRow(<dynamic>['中国的首都是哪里？', '北京', '是']);
    return _writeWorkbook(excel, outputPath);
  }

  // ========== 一键导出全班积分报表 ==========
  static Future<File> exportFullReport(
    List<Classroom> classrooms,
    String outputPath,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['积分总报表'];
    sheet.appendRow(<dynamic>['班级', '小组', '姓名', '积分', '段位', '班级排名', '小组排名']);

    for (final cls in classrooms) {
      final allMembers = cls.allMembers
        ..sort((a, b) => b.score.compareTo(a.score));

      for (int ci = 0; ci < allMembers.length; ci++) {
        final m = allMembers[ci];
        final (rankName, _) = RankSystem.getRank(m.score);

        String groupName = '';
        int groupRank = 0;
        for (final g in cls.groups) {
          if (!g.members.any((x) => x.uid == m.uid)) continue;
          groupName = g.name;
          final sorted = List<Member>.from(g.members)
            ..sort((a, b) => b.score.compareTo(a.score));
          groupRank = sorted.indexWhere((x) => x.uid == m.uid) + 1;
          break;
        }

        sheet.appendRow(<dynamic>[
          cls.name,
          groupName,
          m.name,
          m.score,
          rankName,
          ci + 1,
          groupRank,
        ]);
      }
    }
    return _writeWorkbook(excel, outputPath);
  }

  // ==================== 内部工具 ====================

  /// 选出真正有数据的那张表。
  ///
  /// `Excel.createExcel()` 会留下一个默认的空表，而 `excel.tables.keys.first`
  /// 很可能正好是它 —— 用它读名单会一行都读不到，表现为「重启后班级全没了」。
  /// 这里改成按内容选：行数最多的优先，同分时优先已知表名。
  static Sheet _dataSheet(Excel excel) {
    if (excel.tables.isEmpty) {
      throw const FormatException('工作簿里没有任何工作表');
    }

    const preferred = {'班级数据', '学生名单', '积分数据', '题库', '积分总报表'};

    String? best;
    int bestRows = -1;
    bool bestPreferred = false;

    for (final entry in excel.tables.entries) {
      final rows = entry.value.maxRows;
      final isPreferred = preferred.contains(entry.key);
      final better = rows > bestRows ||
          (rows == bestRows && isPreferred && !bestPreferred);
      if (better) {
        best = entry.key;
        bestRows = rows;
        bestPreferred = isPreferred;
      }
    }

    return excel.tables[best ?? excel.tables.keys.first]!;
  }

  /// 定位名单里各列的列号。优先按表头名字定位，认不出来再退化为按位置。
  static _RosterColumnLayout _detectRosterLayout(Sheet table) {
    if (table.maxRows == 0) {
      return const _RosterColumnLayout(headerRow: -1);
    }

    final headerRow = _rowLooksLikeHeader(table, 0) ? 0 : -1;

    if (headerRow >= 0) {
      int classCol = -1, groupCol = -1, nameCol = -1, scoreCol = -1;
      for (int c = 0; c < 4; c++) {
        final cell = _cell(table, 0, c).trim();
        final h = cell.toLowerCase();
        if (classCol < 0 && (cell.contains('班级') || h.contains('class'))) {
          classCol = c;
        } else if (nameCol < 0 &&
            (cell.contains('姓名') ||
                cell.contains('名字') ||
                cell.contains('学生') ||
                h.contains('name'))) {
          nameCol = c;
        } else if (groupCol < 0 &&
            (cell.contains('组') || h.contains('group'))) {
          groupCol = c;
        } else if (scoreCol < 0 &&
            (cell.contains('积分') ||
                cell.contains('分数') ||
                h.contains('score'))) {
          scoreCol = c;
        }
      }

      if (nameCol >= 0) {
        final resolvedClass = classCol >= 0 ? classCol : 0;
        return _RosterColumnLayout(
          headerRow: 0,
          classCol: resolvedClass,
          groupCol: groupCol,
          nameCol: nameCol,
          scoreCol: scoreCol,
          hasGroup: groupCol >= 0,
          hasScore: scoreCol >= 0,
          matchesAppHeader: resolvedClass == RosterLayout.className &&
              groupCol == RosterLayout.groupName &&
              nameCol == RosterLayout.memberName &&
              scoreCol == RosterLayout.score,
        );
      }
    }

    // 没有可识别的表头：按文档约定的位置解析，且第 0 行就是数据，不能当表头跳过。
    // 第 4 列有内容 = 班级/小组/姓名/积分（应用自己的格式），
    // 否则 = 班级/姓名/积分（导入模板格式）。
    final wide = _hasContentAt(table, 3);
    return wide
        ? const _RosterColumnLayout(
            headerRow: -1,
            classCol: 0,
            groupCol: 1,
            nameCol: 2,
            scoreCol: 3,
            hasGroup: true,
            hasScore: true,
          )
        : const _RosterColumnLayout(
            headerRow: -1,
            classCol: 0,
            groupCol: -1,
            nameCol: 1,
            scoreCol: 2,
            hasGroup: false,
            hasScore: true,
          );
  }

  /// 第 0 行是否像表头。
  ///
  /// 这里的分寸很关键：判错的代价是不对称的。
  /// - 把数据行当成表头 → 第一个学生被静默丢掉，谁也发现不了；
  /// - 把表头当成数据行 → 多出一个叫「姓名」的成员，一眼就能看见并删掉。
  /// 所以宁可漏判，不可误判。具体要求命中两个表头词，或整格正好等于表头词。
  /// （也正因如此不能用 `contains('班')`：「三年二班」这种正常班名就含「班」。）
  static bool _rowLooksLikeHeader(Sheet table, int row) {
    const zhKeys = ['班级', '小组', '姓名', '名字', '学生', '积分', '分数', '序号', '学号'];
    const enKeys = ['class', 'group', 'name', 'score', 'no.', 'index'];
    const exactZh = ['班级', '班', '小组', '组', '组别', '姓名', '名字', '学生', '积分', '分数', '序号', '学号'];

    int hits = 0;
    for (int c = 0; c < 4; c++) {
      final cell = _cell(table, row, c).trim();
      if (cell.isEmpty) continue;
      if (exactZh.contains(cell)) return true;
      final lower = cell.toLowerCase();
      final zh = zhKeys.any(cell.contains);
      final en = enKeys.any(lower.contains);
      if (zh || en) hits++;
    }
    return hits >= 2;
  }

  static bool _hasContentAt(Sheet table, int col) {
    for (int r = 0; r < (table.maxRows < 3 ? table.maxRows : 3); r++) {
      if (_cell(table, r, col).trim().isNotEmpty) return true;
    }
    return false;
  }

  static double? _numeric(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final direct = double.tryParse(t);
    if (direct != null) return direct;
    final m = RegExp(r'[-+]?\d*\.?\d+').firstMatch(t);
    return m == null ? null : double.tryParse(m.group(0)!);
  }

  static bool _looksLikeQuestionHeader(String s) =>
      s.contains('题目') ||
      s.contains('问题') ||
      s.contains('题干') ||
      s.toLowerCase().contains('question');

  static bool _isTruthy(String s) {
    final v = s.trim().toLowerCase();
    return v == '是' ||
        v == 'y' ||
        v == 'yes' ||
        v == '1' ||
        v == 'true' ||
        v == '√' ||
        v == '✓';
  }

  static String _cell(Sheet sheet, int row, int col) {
    final c = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    return c?.value?.toString() ?? '';
  }

  /// 读单元格里的数字。
  ///
  /// 有些 CellValue 实现的 toString() 形如 `DoubleCellValue(12.5)`，
  /// 直接 tryParse 会静默得到 0，所以这里再兜一层数字提取。
  static double _cellNum(Sheet sheet, int row, int col) =>
      _numeric(_cell(sheet, row, col)) ?? 0;

  static Future<File> _writeWorkbook(Excel excel, String outputPath) async {
    final dir = Directory(outputPath).parent;
    if (!await dir.exists()) await dir.create(recursive: true);
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Excel 编码失败');
    final f = File(outputPath);
    await f.writeAsBytes(bytes);
    return f;
  }

  static String _uid() => const Uuid().v4();
}

/// 由表头推导出的列位置。
class _RosterColumnLayout {
  final int headerRow;
  final int classCol;
  final int groupCol;
  final int nameCol;
  final int scoreCol;
  final bool hasGroup;
  final bool hasScore;

  /// 表头是否正好等于本应用写出的表头（决定这个文件是不是权威来源）
  final bool matchesAppHeader;

  const _RosterColumnLayout({
    required this.headerRow,
    this.classCol = 0,
    this.groupCol = -1,
    this.nameCol = 1,
    this.scoreCol = -1,
    this.hasGroup = false,
    this.hasScore = false,
    this.matchesAppHeader = false,
  });
}
