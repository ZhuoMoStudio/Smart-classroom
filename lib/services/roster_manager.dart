import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_log.dart';

/// 一个名单文件在保留策略中需要的信息。
///
/// 只抽取出「决策所需的全部输入」，让保留规则成为纯函数、可以直接单元测试。
class RosterFileInfo {
  final String path;
  final DateTime modified;
  final String identityKey;

  const RosterFileInfo({
    required this.path,
    required this.modified,
    required this.identityKey,
  });

  String get name => p.basename(path);
}

/// 保留决策的结果。
class RetentionPlan {
  /// 应当保留的文件路径
  final List<String> keep;

  /// 应当淘汰的文件路径
  final List<String> drop;

  const RetentionPlan({required this.keep, required this.drop});

  bool get isEmpty => keep.isEmpty && drop.isEmpty;
  int get dropped => drop.length;
}

/// 名单文件的年级班级识别 + 同名保留策略。
///
/// 为什么需要
/// ----------
/// `学生信息/` 同时充当导入投放点和应用落点（见 WorkspaceService 的注释）。
/// 老师的习惯是把「三年级1班_学生名单.xlsx」这类文件直接丢进来，
/// 而应用自己保存的是「三年级1班.xlsx」—— 于是同一个班级会随时间和
/// 手动导入不断堆积出许多份，文件名里的年级班级信息却是判断
/// 「哪些文件其实是同一个班」的唯一可靠线索（表格内容里未必写全）。
///
/// 因此：文件名 → (年级, 班级) → 分组；同一组内保留「最旧 1 份 + 最新 5 份」。
///
/// 与旧实现的差异（刻意的）
/// ----------------------
/// 1. 旧实现只支持 `\d+班`，但中国学校更常见的是「三年二班」。这里把中文数字
///    也纳入识别，并在分组键里归一成阿拉伯数字，使「三年二班」与「3年2班」
///    归入同一组。
/// 2. 旧实现无法识别时把**单个文件名**当作分组键，等于每份文件自成一組、
///    永远不会被清理；而它的文档却说「无法识别的保留最近 5 个」—— 两者矛盾。
///    这里选择更保守的一侧：识别不出年级班级的文件**不参与淘汰**。
///    理由是分组一旦搞错就会删掉另一个班的名单，属于不可逆的数据损失，
///    宁可少清理也不能删错。
class RosterManager {
  RosterManager._();

  /// 同一组里保留最近多少份
  static const int keepRecent = 5;

  /// 同一组里保留最旧多少份（「最初始的那一份」）
  static const int keepOldest = 1;

  /// 无法识别年级班级时使用的分组键前缀。
  /// 带上这个前缀的组不会被淘汰。
  static const String unrecognizedPrefix = '?';

  // ==================== 识别（纯函数） ====================

  /// 从文件名识别年级与班级。
  ///
  /// 例：
  ///   "三年级1班_学生名单.xlsx" → ("三年级", "1班")
  ///   "三年二班.xlsx"          → ("三年",   "二班")
  ///   "高一3班_名单.xlsx"      → ("高一",   "3班")
  ///   "小学五年级（2）班.xlsx"  → ("五年级", "2班")
  static (String?, String?) extractGradeClass(String fileName) {
    final name = normalize(fileName);
    if (name.isEmpty) return (null, null);

    // 班级部分：阿拉伯数字或中文数字，后面跟「班」
    // 捕获组把「班」一起收进来，便于界面/日志直接显示识别结果。
    const cls = r'((?:[0-9]+|[一二三四五六七八九十]+)班)';
    // 年级部分。注意备选顺序：更长/更具体的写在前面，
    // 否则「高一年级」会被「一年级」抢先匹配掉、「高」被丢掉，
    // 进而把「高一年级3班」和「一年级3班」错误地归为同一组。
    const grade = r'(高[一二三]|初[一二三]|小[一二三四五六]'
        r'|(?:高|初)?[0-9]+年级'
        r'|(?:高|初)?[一二三四五六七八九十]+年级'
        r'|[0-9]+年'
        r'|[一二三四五六七八九十]+年)';

    // 允许年级与班级之间夹着「（）」等修饰，例如 五年级（2）班
    final patterns = <RegExp>[
      RegExp('$grade[（(]?$cls'),
      // 只写了班级没写年级，例如 "1班_学生名单"
      RegExp('^$cls'),
    ];

    for (final pattern in patterns) {
      final m = pattern.firstMatch(name);
      if (m == null) continue;
      if (m.groupCount >= 2) {
        final g = m.group(1);
        final c = m.group(2);
        if (g != null && c != null) return (g, c);
      } else if (m.groupCount == 1) {
        // 只识别出班级
        final c = m.group(1);
        if (c != null) return (null, c);
      }
    }
    return (null, null);
  }

  /// 归一化文件名，消除全角字符、空格与常见分隔符带来的干扰。
  static String normalize(String fileName) {
    var s = p.basenameWithoutExtension(fileName);
    s = s.replaceAll(RegExp(r'[_\-—–\s（）()【】\[\]]'), '');
    // 全角数字/字母 → 半角
    final buf = StringBuffer();
    for (final rune in s.runes) {
      if (rune >= 0xFF10 && rune <= 0xFF19) {
        buf.writeCharCode(rune - 0xFF10 + 0x30); // ０-９
      } else if (rune >= 0xFF21 && rune <= 0xFF3A) {
        buf.writeCharCode(rune - 0xFF21 + 0x41); // Ａ-Ｚ
      } else if (rune >= 0xFF41 && rune <= 0xFF5A) {
        buf.writeCharCode(rune - 0xFF41 + 0x61); // ａ-ｚ
      } else {
        buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }

  /// 分组键：把「年级 + 班级」归一成可比较的串。
  ///
  /// 中文数字会被转成阿拉伯数字，因此「三年二班」与「3年2班」同组。
  static String identityKey(String fileName) {
    final (grade, cls) = extractGradeClass(fileName);
    if (grade == null && cls == null) {
      return '$unrecognizedPrefix${normalize(fileName)}';
    }
    final g = _normalizeGrade(grade);
    final c = _normalizeClass(cls);
    return '${g}_$c';
  }

  static bool isRecognized(String fileName) =>
      !identityKey(fileName).startsWith(unrecognizedPrefix);

  /// 用于云同步目录的 ASCII 路径段。
  ///
  /// WebDAV 各家实现（坚果云 / Nextcloud / 自建）对非 ASCII 路径的处理并不一致，
  /// 而文件名规范又明令禁止 `\ / : * ? " < > |`。
  /// 因此把年级前缀映射成 ASCII：高→S、初→J、小→P；数字部分保持不变。
  /// 例：高1_3 → S1_3；初2_2 → J2_2；3_1 → 3_1；识别不出 → _unsorted
  static String pathSegment(String fileName) {
    final key = identityKey(fileName);
    if (key.startsWith(unrecognizedPrefix)) return '_unsorted';
    return key.replaceAll('高', 'S').replaceAll('初', 'J').replaceAll('小', 'P');
  }

  /// 把年级归一成「前缀 + 数字」的规范形式。
  ///
  /// 目的是让同一学段的不同写法落到同一个键上，同时**不丢掉学段信息**：
  ///   高一年级 / 高一 / 高中一年级 → 高1
  ///   初二年级 / 初二              → 初2
  ///   五年级   / 5年级             → 5
  /// 如果丢掉前缀，「高一年级3班」与「一年级3班」会合并，
  /// 而合并意味着其中一份会被当作旧文件删掉 —— 那是删错班。
  static String _normalizeGrade(String? grade) {
    if (grade == null || grade.isEmpty) return '-';

    var s = grade.trim();
    String prefix = '';
    if (s.startsWith('高')) {
      prefix = '高';
      s = s.substring(1);
    } else if (s.startsWith('初')) {
      prefix = '初';
      s = s.substring(1);
    } else if (s.startsWith('小')) {
      prefix = '小';
      s = s.substring(1);
    }
    // 高中一年级 / 初中二年级 这类写法：去掉「中」
    s = s.replaceAll('中', '');
    s = s.replaceAll('年级', '').replaceAll('年', '');

    final n = _cnToInt(s);
    if (n == null) return '$prefix$s';
    return '$prefix$n';
  }

  static String _normalizeClass(String? cls) {
    if (cls == null || cls.isEmpty) return '-';
    final c = cls.replaceAll('班', '');
    final n = _cnToInt(c);
    return n == null ? c : '$n';
  }

  /// 中文数字 → 整数（支持 一 ~ 九十九）。
  /// 无法解析时返回 null，调用方保留原文。
  static int? _cnToInt(String s) {
    if (s.isEmpty) return null;
    final direct = int.tryParse(s);
    if (direct != null) return direct;

    const digits = {
      '零': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
    };

    if (s == '十') return 10;
    if (s.startsWith('十')) {
      final rest = digits[s.substring(1)];
      return rest == null ? null : 10 + rest;
    }
    if (s.contains('十')) {
      final parts = s.split('十');
      final tens = digits[parts[0]];
      if (tens == null) return null;
      if (parts.length < 2 || parts[1].isEmpty) return tens * 10;
      final ones = digits[parts[1]];
      return ones == null ? null : tens * 10 + ones;
    }
    if (s.length == 1) return digits[s];
    // 多字但无「十」的写法（如「二三」）不视为数字，避免误判
    return null;
  }

  // ==================== 保留策略（纯函数） ====================

  /// 计算保留计划。纯函数，便于单元测试。
  ///
  /// 规则：
  /// - 按 [RosterFileInfo.identityKey] 分组；
  /// - 组内按修改时间倒序（最新在前）；
  /// - 保留最新 [keepRecent] 份 + 最旧 [keepOldest] 份；
  /// - 组内文件数不超过 keepRecent + keepOldest 时不淘汰任何文件；
  /// - 识别不出年级班级的组（键以 [unrecognizedPrefix] 开头）不淘汰。
  static RetentionPlan planRetention(List<RosterFileInfo> files) {
    final groups = <String, List<RosterFileInfo>>{};
    for (final f in files) {
      groups.putIfAbsent(f.identityKey, () => []).add(f);
    }

    final keep = <String>[];
    final drop = <String>[];

    for (final entry in groups.entries) {
      final group = entry.value;

      final limit = keepRecent + keepOldest;
      if (group.length <= limit) {
        keep.addAll(group.map((f) => f.path));
        continue;
      }

      // 识别不出年级班级的组：不淘汰（删错班的代价不可逆）
      if (entry.key.startsWith(unrecognizedPrefix)) {
        keep.addAll(group.map((f) => f.path));
        AppLog.warn(
          '名单保留',
          '有 ${group.length} 份名单无法从文件名识别年级班级，已全部保留：'
              '${group.map((f) => f.name).join('、')}',
        );
        continue;
      }

      final sorted = List<RosterFileInfo>.from(group)
        ..sort((a, b) => b.modified.compareTo(a.modified));

      final retained = <String>{
        ...sorted.take(keepRecent).map((f) => f.path), // 最近的
        ...sorted.reversed.take(keepOldest).map((f) => f.path), // 最初始的
      };

      for (final f in sorted) {
        if (retained.contains(f.path)) {
          keep.add(f.path);
        } else {
          drop.add(f.path);
        }
      }
    }

    return RetentionPlan(keep: keep, drop: drop);
  }

  // ==================== IO 包装 ====================

  /// 扫描目录、计算计划并执行淘汰。
  ///
  /// 返回被淘汰的文件数。
  /// 淘汰采取**删除**（按既有策略），但每一次删除都会写进运行日志，
  /// 以便老师在发现问题时至少有据可查。
  static Future<int> applyRetention(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;

    final infos = <RosterFileInfo>[];
    await for (final e in dir.list()) {
      if (e is! File) continue;
      if (!e.path.toLowerCase().endsWith('.xlsx')) continue;
      try {
        final stat = await e.stat();
        infos.add(RosterFileInfo(
          path: e.path,
          modified: stat.modified,
          identityKey: identityKey(p.basename(e.path)),
        ));
      } catch (e2, st) {
        AppLog.error('名单保留', '读取文件信息失败 ${p.basename(e.path)}', e2, st);
      }
    }

    if (infos.length <= keepRecent + keepOldest) return 0;

    final plan = planRetention(infos);
    int removed = 0;

    for (final path in plan.drop) {
      try {
        final f = File(path);
        if (!await f.exists()) continue;
        await f.delete();
        removed++;
        AppLog.warn(
          '名单保留',
          '已删除旧名单（同年级班级仅保留最旧 1 份 + 最新 $keepRecent 份）: '
              '${p.basename(path)}',
        );
      } catch (e, st) {
        AppLog.error('名单保留', '删除失败 ${p.basename(path)}', e, st);
      }
    }

    if (removed > 0) {
      AppLog.info('名单保留', '本次清理删除 $removed 份旧名单');
    }
    return removed;
  }
}
