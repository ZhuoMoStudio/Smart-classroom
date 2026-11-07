import 'package:flutter_test/flutter_test.dart';
import 'package:smart_classroom/models/score_history.dart';

/// 撤销的语义必须钉住：**先确认能定位到人，再把记录从队列里拿走**。
/// 旧实现先 `removeAt(0)` 再找人，找不到人时记录已经没了 ——
/// 老师看到的是「撤销失败，而且这条历史也消失了」。
void main() {
  ScoreChangeRecord record(String name, {double delta = 1}) => ScoreChangeRecord(
        memberName: name,
        groupName: '一组',
        className: '三年级1班',
        oldScore: 10,
        newScore: 10 + delta,
        delta: delta,
        timestamp: DateTime(2026, 11, 7),
        memberUid: 'uid-$name',
      );

  test('peekLast 只看不取', () {
    final h = ScoreHistoryManager();
    h.addRecord(record('甲'));
    h.addRecord(record('乙'));

    expect(h.peekLast()?.memberName, '乙');
    expect(h.length, 2, reason: 'peek 不应该改变队列');
  });

  test('undoLast 取出最新一条，并支持连续撤销', () {
    final h = ScoreHistoryManager();
    h.addRecord(record('甲'));
    h.addRecord(record('乙'));

    expect(h.undoLast()?.memberName, '乙');
    expect(h.undoLast()?.memberName, '甲');
    expect(h.undoLast(), isNull);
    expect(h.isEmpty, isTrue);
  });

  test('记录按时间倒序（最新在前）', () {
    final h = ScoreHistoryManager();
    for (var i = 0; i < 5; i++) {
      h.addRecord(record('第$i个'));
    }
    expect(h.records.first.memberName, '第4个');
    expect(h.records.last.memberName, '第0个');
  });

  test('超过上限后丢弃最旧的，防止内存无限增长', () {
    final h = ScoreHistoryManager();
    for (var i = 0; i < 205; i++) {
      h.addRecord(record('第$i个'));
    }
    expect(h.length, 200);
    expect(h.records.first.memberName, '第204个');
    expect(h.records.last.memberName, '第5个');
  });

  test('recentRecords 只暴露最近 50 条', () {
    final h = ScoreHistoryManager();
    for (var i = 0; i < 60; i++) {
      h.addRecord(record('第$i个'));
    }
    expect(h.recentRecords.length, 50);
    expect(h.recentRecords.first.memberName, '第59个');
  });

  test('clear 之后队列为空', () {
    final h = ScoreHistoryManager();
    h.addRecord(record('甲'));
    h.clear();
    expect(h.isEmpty, isTrue);
    expect(h.peekLast(), isNull);
  });

  test('delta 正负判断', () {
    expect(record('甲', delta: 2).isPositive, isTrue);
    expect(record('乙', delta: -2).isNegative, isTrue);
    expect(record('丙', delta: 0).isPositive, isFalse);
    expect(record('丙', delta: 0).isNegative, isFalse);
  });
}
