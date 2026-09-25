import 'package:flutter_test/flutter_test.dart';
import 'package:smart_classroom/services/roster_manager.dart';

/// RosterManager 的纯逻辑测试。
///
/// 这些用例先在等价实现（Python 移植版）上逐条验证过才落到 Dart，
/// 因为这套逻辑一旦判断错，后果是**删掉另一个班的名单**（不可逆）。
/// 特别是这两类必须钉住：
///   - 「高一年级3班」不能与「一年级3班」归为一组；
///   - 「初中二年级2班」不能与「二年级2班」归为一组。
/// 两者都是「前缀被丢掉」造成的，而丢掉前缀就会删错班。
void main() {
  group('extractGradeClass 从文件名识别年级班级', () {
    test('年级+阿拉伯数字班级', () {
      expect(RosterManager.extractGradeClass('三年级1班_学生名单.xlsx'),
          ('三年级', '1班'));
    });

    test('年级+中文数字班级', () {
      expect(RosterManager.extractGradeClass('三年二班.xlsx'), ('三年', '二班'));
    });

    test('高中简称', () {
      expect(RosterManager.extractGradeClass('高一3班_名单.xlsx'), ('高一', '3班'));
    });

    test('小学全称带括号（归一化会去掉括号）', () {
      expect(RosterManager.extractGradeClass('小学五年级（2）班.xlsx'),
          ('五年级', '2班'));
    });

    test('只有班级没有年级', () {
      final (g, c) = RosterManager.extractGradeClass('1班_学生名单.xlsx');
      expect(g, isNull);
      expect(c, '1班');
    });

    test('全角数字按半角处理', () {
      expect(RosterManager.extractGradeClass('三年级１班.xlsx'), ('三年级', '1班'));
    });

    test('识别不出时返回双 null', () {
      expect(RosterManager.extractGradeClass('乱七八糟.xlsx'), (null, null));
    });
  });

  group('identityKey 分组键', () {
    test('三年二班 与 3年2班 归一为同一组', () {
      expect(RosterManager.identityKey('三年二班.xlsx'),
          RosterManager.identityKey('3年2班.xlsx'));
    });

    test('全角与半角数字归一为同一组', () {
      expect(RosterManager.identityKey('三年级1班.xlsx'),
          RosterManager.identityKey('三年级１班.xlsx'));
    });

    test('高一年级3班 与 高一3班 归一为同一组', () {
      expect(RosterManager.identityKey('高一年级3班.xlsx'),
          RosterManager.identityKey('高一3班.xlsx'));
    });

    test('初二年级2班 与 初二2班 归一为同一组', () {
      expect(RosterManager.identityKey('初二年级2班.xlsx'),
          RosterManager.identityKey('初二2班.xlsx'));
    });

    test('关键：高一年级3班 不能与 一年级3班 同组（否则会误删另一个年级）', () {
      expect(RosterManager.identityKey('高一年级3班.xlsx'),
          isNot(RosterManager.identityKey('一年级3班.xlsx')));
    });

    test('关键：初中二年级2班 不能与 二年级2班 同组', () {
      expect(RosterManager.identityKey('初中二年级2班.xlsx'),
          isNot(RosterManager.identityKey('二年级2班.xlsx')));
    });

    test('「初中二年级」这类夹了「中」的写法要保留学段前缀', () {
      // 这条是被 flutter test 抓出来的真实缺陷：
      // 年级备选里没有覆盖「初中X年级」，正则于是从「二年级」处才开始匹配，
      // 前缀「初」被丢掉，导致「初中二年级2班」与「二年级2班」同组 ——
      // 同组就意味着其中一个会被当作旧名单删掉。
      expect(RosterManager.identityKey('初中二年级2班.xlsx'), '初2_2');
      expect(RosterManager.identityKey('初中二年级2班.xlsx'),
          RosterManager.identityKey('初二年级2班.xlsx'));
      expect(RosterManager.identityKey('初中一年级1班.xlsx'), '初1_1');
      expect(RosterManager.identityKey('高中一年级3班.xlsx'), '高1_3');
      expect(RosterManager.identityKey('高中一年级3班.xlsx'),
          RosterManager.identityKey('高一年级3班.xlsx'));
    });

    test('识别不出时带 ? 前缀，便于保留策略跳过淘汰', () {
      expect(RosterManager.identityKey('随便什么名字.xlsx'),
          startsWith(RosterManager.unrecognizedPrefix));
      expect(RosterManager.isRecognized('随便什么名字.xlsx'), isFalse);
      expect(RosterManager.isRecognized('三年级1班.xlsx'), isTrue);
    });
  });

  group('pathSegment 供云同步目录使用（必须是纯 ASCII）', () {
    test('年级前缀映射成 ASCII', () {
      expect(RosterManager.pathSegment('高一年级3班.xlsx'), 'S1_3');
      expect(RosterManager.pathSegment('初二年级2班.xlsx'), 'J2_2');
      expect(RosterManager.pathSegment('初中二年级2班.xlsx'), 'J2_2');
      expect(RosterManager.pathSegment('高中一年级3班.xlsx'), 'S1_3');
    });

    test('「小学」前缀会被丢掉，只剩年级数字', () {
      // 这不是缺陷：五年级本来就只可能是小学，不会与高/初的年级混淆，
      // 因此丢掉「小」不会造成跨学段误合并。
      // （与「高一」必须保留前缀形成对比：丢掉就与「一年级」撞车。）
      expect(RosterManager.pathSegment('小学五年级2班.xlsx'), '5_2');
    });

    test('纯数字年级班级保持原样', () {
      expect(RosterManager.pathSegment('三年级1班.xlsx'), '3_1');
      expect(RosterManager.pathSegment('三年二班.xlsx'), '3_2');
    });

    test('识别不出时落到 _unsorted', () {
      expect(RosterManager.pathSegment('乱七八糟.xlsx'), '_unsorted');
    });

    test('结果不含 WebDAV 禁止的字符，也不含非 ASCII', () {
      final forbidden = RegExp(r'[\\/:*?"<>|]');
      final nonAscii = RegExp(r'[^\x20-\x7E]');
      for (final name in [
        '三年级1班.xlsx',
        '三年二班.xlsx',
        '高一年级3班.xlsx',
        '初二年级2班.xlsx',
        '初中二年级2班.xlsx',
        '小学五年级2班.xlsx',
        '乱七八糟.xlsx',
      ]) {
        final seg = RosterManager.pathSegment(name);
        expect(forbidden.hasMatch(seg), isFalse, reason: '$seg 含禁止字符');
        expect(nonAscii.hasMatch(seg), isFalse, reason: '$seg 含非 ASCII 字符');
      }
    });
  });

  group('planRetention 保留策略（最旧 1 份 + 最新 5 份）', () {
    /// 造一批同组文件，mtime 越大越新
    List<RosterFileInfo> sameGroup(int count) => [
          for (int i = 0; i < count; i++)
            RosterFileInfo(
              path: '/d/三年级1班_$i.xlsx',
              modified: DateTime(2026, 1, 1).add(Duration(days: i)),
              identityKey: RosterManager.identityKey('三年级1班_$i.xlsx'),
            ),
        ];

    test('7 份：保留 6、淘汰中间那 1 份', () {
      final plan = RosterManager.planRetention(sameGroup(7));
      expect(plan.keep.length, 6);
      expect(plan.drop.length, 1);
    });

    test('恰好 6 份：一份都不淘汰', () {
      final plan = RosterManager.planRetention(sameGroup(6));
      expect(plan.drop, isEmpty);
    });

    test('少于 6 份：一份都不淘汰', () {
      expect(RosterManager.planRetention(sameGroup(3)).drop, isEmpty);
    });

    test('最旧的一份始终被保留（这就是「最初始的那一份」）', () {
      final plan = RosterManager.planRetention(sameGroup(10));
      expect(plan.keep, contains('/d/三年级1班_0.xlsx'));
    });

    test('最新的一份始终被保留', () {
      final plan = RosterManager.planRetention(sameGroup(10));
      expect(plan.keep, contains('/d/三年级1班_9.xlsx'));
    });

    test('不同年级/班级互不影响', () {
      final files = <RosterFileInfo>[
        ...sameGroup(7),
        for (int i = 0; i < 7; i++)
          RosterFileInfo(
            path: '/d/高一3班_$i.xlsx',
            modified: DateTime(2026, 1, 1).add(Duration(days: i)),
            identityKey: RosterManager.identityKey('高一3班_$i.xlsx'),
          ),
      ];
      final plan = RosterManager.planRetention(files);
      expect(plan.drop.length, 2); // 两组各淘汰 1 份
    });

    test('三年二班 与 3年2班 混排时视为同一组', () {
      final files = <RosterFileInfo>[
        for (int i = 0; i < 4; i++)
          RosterFileInfo(
            path: '/d/三年二班_$i.xlsx',
            modified: DateTime(2026, 1, 1).add(Duration(days: i)),
            identityKey: RosterManager.identityKey('三年二班_$i.xlsx'),
          ),
        for (int i = 4; i < 8; i++)
          RosterFileInfo(
            path: '/d/3年2班_$i.xlsx',
            modified: DateTime(2026, 1, 1).add(Duration(days: i)),
            identityKey: RosterManager.identityKey('3年2班_$i.xlsx'),
          ),
      ];
      final plan = RosterManager.planRetention(files);
      expect(plan.keep.length, 6);
      expect(plan.drop.length, 2);
    });

    test('识别不出年级班级的文件永不淘汰', () {
      final files = [
        for (int i = 0; i < 20; i++)
          RosterFileInfo(
            path: '/d/随手记$i.xlsx',
            modified: DateTime(2026, 1, 1).add(Duration(days: i)),
            identityKey: RosterManager.identityKey('随手记$i.xlsx'),
          ),
      ];
      expect(RosterManager.planRetention(files).drop, isEmpty);
    });
  });
}
