import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../models/score_history.dart';

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
    try {
      return classrooms.firstWhere((c) => c.uid == selectedClassUid);
    } catch (_) {
      return null;
    }
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

  void loadFromData(List<Classroom> classrooms, String? uid) => state =
      state.copyWith(
        classrooms: classrooms,
        selectedClassUid: uid,
        isDirty: false,
      );

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
    state = state.copyWith(
      classrooms: state.classrooms
          .map((c) => c.uid == uid ? c.copyWith(name: newName) : c)
          .toList(),
      isDirty: true,
    );
  }

  void deleteClass(String uid) {
    state = state.copyWith(
      classrooms:
          state.classrooms.where((c) => c.uid != uid).toList(),
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
            .map((g) =>
                g.uid == gid ? g.copyWith(name: newName) : g)
            .toList(),
      ),
    );
  }

  void deleteGroup(String cid, String gid) {
    _up(
      cid,
      (c) => c.copyWith(
          groups: c.groups.where((g) => g.uid != gid).toList()),
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
                        .map((m) => m.uid == mid
                            ? m.copyWith(name: newName)
                            : m)
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
                    members: g.members
                        .where((m) => m.uid != mid)
                        .toList(),
                  )
                : g)
            .toList(),
      ),
    );
  }

  /// 加减积分（含历史记录）
  void changeScore(String cid, String gid, String mid, double delta) {
    final cls = state.classrooms.firstWhere(
      (c) => c.uid == cid,
      orElse: () => state.classrooms.first,
    );
    final group = cls.groups.firstWhere(
      (g) => g.uid == gid,
      orElse: () => cls.groups.first,
    );
    final member = group.members.firstWhere(
      (m) => m.uid == mid,
      orElse: () => group.members.first,
    );

    final oldScore = member.score;
    double ns = oldScore + delta;
    if (ns < 0) ns = 0;

    // 记录历史
    state.history.addRecord(ScoreChangeRecord(
      memberName: member.name,
      groupName: group.name,
      className: cls.name,
      oldScore: oldScore,
      newScore: ns,
      delta: delta,
      timestamp: DateTime.now(),
    ));

    _up(
      cid,
      (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(
                    members: g.members.map((m) {
                      if (m.uid == mid) {
                        return m.copyWith(score: ns);
                      }
                      return m;
                    }).toList(),
                  )
                : g)
            .toList(),
      ),
    );
  }

  /// 撤销最近一次积分变动
  ScoreChangeRecord? undoLastScoreChange() {
    final record = state.history.undoLast();
    if (record == null) return null;

    // 找到对应成员并反向操作
    for (final cls in state.classrooms) {
      if (cls.name != record.className) continue;
      for (final group in cls.groups) {
        if (group.name != record.groupName) continue;
        for (final member in group.members) {
          if (member.name != record.memberName) continue;
          // 恢复到旧分数（不记录历史）
          _upRaw(
            cls.uid,
            (c) => c.copyWith(
              groups: c.groups
                  .map((g) => g.uid == group.uid
                      ? g.copyWith(
                          members: g.members.map((m) {
                            if (m.uid == member.uid) {
                              return m.copyWith(
                                  score: record.oldScore);
                            }
                            return m;
                          }).toList(),
                        )
                      : g)
                  .toList(),
            ),
          );
          return record;
        }
      }
    }
    return null;
  }

  /// 直接设置积分值（用于 Excel 导入等场景，不记录历史）
  void setScore(String cid, String gid, String mid, double newScore) {
    _up(
      cid,
      (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(
                    members: g.members
                        .map((m) => m.uid == mid
                            ? m.copyWith(score: newScore)
                            : m)
                        .toList(),
                  )
                : g)
            .toList(),
      ),
    );
  }

  void changeScoreRaw(String cid, String gid, String mid, double newScore) {
    setScore(cid, gid, mid, newScore);
  }

  void resetAllScores() {
    state = state.copyWith(
      classrooms: state.classrooms
          .map((c) => c.copyWith(
                groups: c.groups
                    .map((g) => g.copyWith(
                          members: g.members
                              .map((m) => m.copyWith(score: 0))
                              .toList(),
                        ))
                    .toList(),
              ))
          .toList(),
      isDirty: true,
    );
  }

  /// 批量加减分 (v1.31)
  void batchChangeScore(String cid, List<String> mids, double delta) {
    final cls = state.classrooms.firstWhere((c) => c.uid == cid);
    _up(cid, (c) => c.copyWith(
      groups: c.groups.map((g) => g.copyWith(
        members: g.members.map((m) {
          if (mids.contains(m.uid)) {
            double ns = m.score + delta;
            if (ns < 0) ns = 0;
            state.history.addRecord(ScoreChangeRecord(
              memberName: m.name, groupName: g.name, className: cls.name,
              oldScore: m.score, newScore: ns, delta: delta, timestamp: DateTime.now(),
            ));
            return m.copyWith(score: ns);
          }
          return m;
        }).toList(),
      )).toList(),
    ));
  }

  /// 清除所有积分历史
  void clearHistory() => state.history.clear();

  void clearDirty() => state = state.copyWith(isDirty: false);

  void _up(String cid, Classroom Function(Classroom) f) {
    state = state.copyWith(
      classrooms:
          state.classrooms.map((c) => c.uid == cid ? f(c) : c).toList(),
      isDirty: true,
    );
  }

  /// 不标记 dirty 的更新（用于撤销等内部操作）
  void _upRaw(String cid, Classroom Function(Classroom) f) {
    state = state.copyWith(
      classrooms:
          state.classrooms.map((c) => c.uid == cid ? f(c) : c).toList(),
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
