import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../models/score_history.dart';
import '../services/app_log.dart';

/// 在可迭代对象里找第一个满足条件的元素，找不到返回 null。
///
/// Dart 的 `firstWhere` 只接受 `orElse`，而 `orElse` 必须返回一个合法元素，
/// 于是「找不到」只能伪造成「返回第一个」或直接抛异常 —— 这两条路都会出事：
/// 前者会把分加错人，后者会让界面崩掉。所以这里自己提供 null 语义。
T? _firstOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

class ClassState {
  final List<Classroom> classrooms;
  final String? selectedClassUid;
  final bool isDirty;
  final ScoreHistoryManager history;

  ClassState({
    this.classrooms = const [],
    this.selectedClassUid,
    this.isDirty = false,
    ScoreHistoryManager? history,
  }) : history = history ?? ScoreHistoryManager();

  Classroom? get selectedClass {
    if (selectedClassUid == null) return null;
    return _firstOrNull(classrooms, (c) => c.uid == selectedClassUid);
  }

  ClassState copyWith({
    List<Classroom>? classrooms,
    String? selectedClassUid,
    bool? isDirty,
    ScoreHistoryManager? history,
  }) =>
      ClassState(
        classrooms: classrooms ?? this.classrooms,
        selectedClassUid: selectedClassUid ?? this.selectedClassUid,
        isDirty: isDirty ?? this.isDirty,
        history: history ?? this.history,
      );
}

class ClassNotifier extends StateNotifier<ClassState> {
  ClassNotifier() : super(ClassState());

  /// 用新数据整体替换当前状态。
  ///
  /// [markDirty] 为 true 表示「这份数据还需要落盘」。
  /// 导入名单后必须置脏，否则自动保存不会触发，导入结果下次启动就没了。
  /// 同时清空积分历史：历史里的 oldScore 对应的是上一份数据，留着会让撤销改错值。
  void loadFromData(
    List<Classroom> classrooms,
    String? uid, {
    bool markDirty = false,
  }) {
    state = ClassState(
      classrooms: classrooms,
      selectedClassUid: uid,
      isDirty: markDirty,
    );
    AppLog.info(
      '班级',
      '载入数据: ${classrooms.length} 个班级、'
          '${classrooms.fold<int>(0, (s, c) => s + c.allMembers.length)} 名学生',
    );
  }

  void selectClass(String uid) =>
      state = state.copyWith(selectedClassUid: uid);

  void addClass(String name) {
    final c = Classroom(uid: _uid(), name: name);
    state = state.copyWith(
      classrooms: [...state.classrooms, c],
      selectedClassUid: c.uid,
      isDirty: true,
    );
  }

  void renameClass(String uid, String newName) {
    if (_firstOrNull(state.classrooms, (c) => c.uid == uid) == null) return;
    state = state.copyWith(
      classrooms: state.classrooms
          .map((c) => c.uid == uid ? c.copyWith(name: newName) : c)
          .toList(),
      isDirty: true,
    );
  }

  void deleteClass(String uid) {
    state = state.copyWith(
      classrooms: state.classrooms.where((c) => c.uid != uid).toList(),
      selectedClassUid:
          state.selectedClassUid == uid ? null : state.selectedClassUid,
      isDirty: true,
    );
  }

  void addGroup(String name) {
    final cls = state.selectedClass;
    if (cls == null) return;
    final g = Group(uid: _uid(), name: name);
    _up(cls.uid, (c) => c.copyWith(groups: [...c.groups, g]));
  }

  void renameGroup(String cid, String gid, String newName) {
    _up(
      cid,
      (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid ? g.copyWith(name: newName) : g)
            .toList(),
      ),
    );
  }

  void deleteGroup(String cid, String gid) {
    _up(
      cid,
      (c) => c.copyWith(groups: c.groups.where((g) => g.uid != gid).toList()),
    );
  }

  void addMember(String gid, String name, {double score = 0}) {
    final cls = state.selectedClass;
    if (cls == null) return;
    final m = Member(uid: _uid(), name: name, score: score);
    _up(
      cls.uid,
      (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(members: [...g.members, m])
                : g)
            .toList(),
      ),
    );
  }

  void renameMember(String cid, String gid, String mid, String newName) {
    _up(
      cid,
      (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(
                    members: g.members
                        .map((m) =>
                            m.uid == mid ? m.copyWith(name: newName) : m)
                        .toList(),
                  )
                : g)
            .toList(),
      ),
    );
  }

  void deleteMember(String cid, String gid, String mid) {
    _up(
      cid,
      (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(
                    members: g.members.where((m) => m.uid != mid).toList(),
                  )
                : g)
            .toList(),
      ),
    );
  }

  /// 加减积分（含历史记录）。返回是否真的改动了。
  ///
  /// 旧实现用 `firstWhere(..., orElse: () => 第一个)` 兜底：
  /// 一旦 uid 对不上（例如班级刚被切换、成员刚被删除），
  /// 它会默默把分加到第一个班级的第一个小组的第一个人身上，
  /// 而界面显示的却仍是老师点的那位同学。这是最危险的一类错误：
  /// 分数被改错了，老师和学生都看不出来。
  bool changeScore(String cid, String gid, String mid, double delta) {
    final cls = _firstOrNull(state.classrooms, (c) => c.uid == cid);
    if (cls == null) {
      AppLog.warn('积分', '找不到班级 cid=$cid，已放弃本次加减分');
      return false;
    }
    final group = _firstOrNull(cls.groups, (g) => g.uid == gid);
    if (group == null) {
      AppLog.warn('积分', '找不到小组 gid=$gid（班级 ${cls.name}），已放弃本次加减分');
      return false;
    }
    final member = _firstOrNull(group.members, (m) => m.uid == mid);
    if (member == null) {
      AppLog.warn('积分', '找不到成员 mid=$mid（${cls.name}/${group.name}），已放弃本次加减分');
      return false;
    }

    final oldScore = member.score;
    var newScore = oldScore + delta;
    if (newScore < 0) newScore = 0;
    if (newScore == oldScore) return false; // 已经是 0 分再扣，不产生无效历史

    state.history.addRecord(ScoreChangeRecord(
      memberUid: member.uid,
      groupUid: group.uid,
      classUid: cls.uid,
      memberName: member.name,
      groupName: group.name,
      className: cls.name,
      oldScore: oldScore,
      newScore: newScore,
      delta: delta,
      timestamp: DateTime.now(),
    ));

    _applyScore(cid, gid, mid, newScore);
    return true;
  }

  /// 撤销最近一次积分变动。返回被撤销的记录，无法撤销时返回 null。
  ScoreChangeRecord? undoLastScoreChange() {
    final record = state.history.peekLast();
    if (record == null) return null;

    final target = _locate(record);
    if (target == null) {
      // 找不到目标时不要把记录吃掉，否则这条改动既没撤销、也从历史里消失了
      AppLog.warn('积分', '撤销失败：找不到 ${record.className}/${record.groupName}/${record.memberName}');
      return null;
    }

    state.history.undoLast(); // 确认能撤销之后才移除记录
    _applyScore(target.classUid, target.groupUid, target.memberUid, record.oldScore);
    return record;
  }

  ({String classUid, String groupUid, String memberUid})? _locate(
    ScoreChangeRecord record,
  ) {
    if (record.classUid != null) {
      final cls = _firstOrNull(state.classrooms, (c) => c.uid == record.classUid);
      final group = cls == null
          ? null
          : _firstOrNull(cls.groups, (g) => g.uid == record.groupUid);
      final member = group == null
          ? null
          : _firstOrNull(group.members, (m) => m.uid == record.memberUid);
      if (cls != null && group != null && member != null) {
        return (
          classUid: cls.uid,
          groupUid: group.uid,
          memberUid: member.uid,
        );
      }
    }

    // 没有 uid 的历史记录（旧数据）才退化为按名字匹配
    for (final cls in state.classrooms) {
      if (cls.name != record.className) continue;
      for (final group in cls.groups) {
        if (group.name != record.groupName) continue;
        for (final member in group.members) {
          if (member.name != record.memberName) continue;
          return (
            classUid: cls.uid,
            groupUid: group.uid,
            memberUid: member.uid,
          );
        }
      }
    }
    return null;
  }

  /// 直接设置积分值（用于 Excel 导入等场景，不记录历史）
  void setScore(String cid, String gid, String mid, double newScore) {
    _applyScore(cid, gid, mid, newScore);
  }

  void changeScoreRaw(String cid, String gid, String mid, double newScore) {
    setScore(cid, gid, mid, newScore);
  }

  /// 清零当前所有班级的积分。
  ///
  /// 同时清空历史：清零之后旧记录的 oldScore 已经没有意义，
  /// 留着它去撤销只会把某一个人恢复到清零前的分数，其他人仍是 0 —— 比不能撤销更让人困惑。
  void resetAllScores() {
    final affected = state.history.length;
    state.history.clear();
    state = state.copyWith(
      classrooms: state.classrooms
          .map((c) => c.copyWith(
                groups: c.groups
                    .map((g) => g.copyWith(
                          members:
                              g.members.map((m) => m.copyWith(score: 0)).toList(),
                        ))
                    .toList(),
              ))
          .toList(),
      isDirty: true,
    );
    AppLog.info('积分', '已清零全部积分（同时清空 $affected 条历史）');
  }

  /// 批量加减分。返回实际改动的学生人数。
  ///
  /// 旧实现用不带 orElse 的 `firstWhere` 找班级，班级不存在时直接抛 StateError；
  /// 而且返回 void，界面只能自己猜改了几个人（结果一直显示 0 人）。
  int batchChangeScore(String cid, List<String> mids, double delta) {
    if (mids.isEmpty) return 0;
    final cls = _firstOrNull(state.classrooms, (c) => c.uid == cid);
    if (cls == null) {
      AppLog.warn('积分', '批量加减分失败：找不到班级 cid=$cid');
      return 0;
    }

    final targets = mids.toSet();
    final records = <ScoreChangeRecord>[];
    int changed = 0;

    for (final group in cls.groups) {
      for (final member in group.members) {
        if (!targets.contains(member.uid)) continue;
        final oldScore = member.score;
        var newScore = oldScore + delta;
        if (newScore < 0) newScore = 0;
        if (newScore == oldScore) continue;
        changed++;
        records.add(ScoreChangeRecord(
          memberUid: member.uid,
          groupUid: group.uid,
          classUid: cls.uid,
          memberName: member.name,
          groupName: group.name,
          className: cls.name,
          oldScore: oldScore,
          newScore: newScore,
          delta: delta,
          timestamp: DateTime.now(),
        ));
      }
    }

    if (changed == 0) return 0;

    final newScoreByUid = {
      for (final r in records) r.memberUid!: r.newScore,
    };

    for (final r in records) {
      state.history.addRecord(r);
    }

    _up(
      cid,
      (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.copyWith(
                  members: g.members
                      .map((m) => newScoreByUid.containsKey(m.uid)
                          ? m.copyWith(score: newScoreByUid[m.uid]!)
                          : m)
                      .toList(),
                ))
            .toList(),
      ),
    );
    return changed;
  }

  /// 清除所有积分历史
  void clearHistory() => state.history.clear();

  void clearDirty() => state = state.copyWith(isDirty: false);

  void _applyScore(String cid, String gid, String mid, double newScore) {
    _up(
      cid,
      (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(
                    members: g.members
                        .map((m) =>
                            m.uid == mid ? m.copyWith(score: newScore) : m)
                        .toList(),
                  )
                : g)
            .toList(),
      ),
    );
  }

  void _up(String cid, Classroom Function(Classroom) f) {
    state = state.copyWith(
      classrooms: state.classrooms.map((c) => c.uid == cid ? f(c) : c).toList(),
      isDirty: true,
    );
  }

  static int _uuidCounter = DateTime.now().microsecondsSinceEpoch;
  static String _uid() =>
      '${++_uuidCounter}-${DateTime.now().millisecondsSinceEpoch % 100000}';
}

final classProvider =
    StateNotifierProvider<ClassNotifier, ClassState>(
  (ref) => ClassNotifier(),
);
