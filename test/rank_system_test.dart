import 'package:flutter_test/flutter_test.dart';
import 'package:smart_classroom/models/class_model.dart';

/// RankSystem.getRank 是全项目唯一干净的纯函数接缝：
/// 没有 I/O、没有 provider、没有 Flutter 依赖，却一直是零测试。
/// 它是「积分 -> 段位」的唯一实现，段位错乱会被老师和学生同时看到，
/// 所以先把它的边界钉住。
void main() {
  group('RankSystem.getRank', () {
    test('0 分是倔强青铜 V', () {
      final (name, level) = RankSystem.getRank(0);
      expect(name, '倔强青铜 V');
      expect(level, 0);
    });

    test('每个大段位内部从 V 递增到 I（以倔强青铜为例）', () {
      expect(RankSystem.getRank(0).$1, '倔强青铜 V');
      expect(RankSystem.getRank(10).$1, '倔强青铜 IV');
      expect(RankSystem.getRank(20).$1, '倔强青铜 III');
      expect(RankSystem.getRank(30).$1, '倔强青铜 II');
      expect(RankSystem.getRank(40).$1, '倔强青铜 I');
    });

    test('跨过 50 分进入秩序白银', () {
      expect(RankSystem.getRank(50).$1, '秩序白银 V');
      expect(RankSystem.getRank(90).$1, '秩序白银 I');
    });

    test('小数分向下取整，49.9 仍属倔强青铜 I', () {
      final (name, level) = RankSystem.getRank(49.9);
      expect(name, '倔强青铜 I');
      expect(level, 4);
    });

    test('负分被夹到 0，不产生越界段位', () {
      final (name, level) = RankSystem.getRank(-5);
      expect(name, '倔强青铜 V');
      expect(level, 0);
    });

    test('290 分是至尊星耀 I，300 分起进入最强王者', () {
      expect(RankSystem.getRank(290).$1, '至尊星耀 I');
      expect(RankSystem.getRank(299.9).$1, '至尊星耀 I');
      expect(RankSystem.getRank(300).$1, '最强王者');
      expect(RankSystem.getRank(349).$1, '最强王者');
    });

    test('350 分及以上封顶荣耀王者，level 不再增长', () {
      final (n1, l1) = RankSystem.getRank(350);
      final (n2, l2) = RankSystem.getRank(100000);
      expect(n1, '荣耀王者');
      expect(n2, '荣耀王者');
      expect(l1, 35);
      expect(l2, 35);
    });
  });

  group('模型派生值', () {
    test('Group.totalScore 是成员分数之和', () {
      const g = Group(uid: 'g', name: '一组', members: [
        Member(uid: 'a', name: '甲', score: 1.5),
        Member(uid: 'b', name: '乙', score: 2.5),
      ]);
      expect(g.totalScore, 4.0);
      expect(g.memberCount, 2);
    });

    test('Classroom.allMembers 展开全部小组', () {
      const c = Classroom(uid: 'c', name: '三年二班', groups: [
        Group(uid: 'g1', name: '一组', members: [
          Member(uid: 'a', name: '甲'),
          Member(uid: 'b', name: '乙'),
        ]),
        Group(uid: 'g2', name: '二组', members: [
          Member(uid: 'c', name: '丙'),
        ]),
      ]);
      expect(c.allMembers.length, 3);
      expect(c.allMembers.map((m) => m.name).toList(), ['甲', '乙', '丙']);
    });

    test('Member.copyWith 不改 uid，只改传入字段', () {
      const m = Member(uid: 'u1', name: '甲', score: 1);
      final m2 = m.copyWith(score: 7);
      expect(m2.uid, 'u1');
      expect(m2.name, '甲');
      expect(m2.score, 7);
      expect(m.score, 1); // 原对象不被改动
    });
  });
}
