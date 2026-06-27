import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';

class ClassState {
  final List<Classroom> classrooms;
  final String? selectedClassUid;
  final bool isDirty;
  const ClassState(
      {this.classrooms = const [], this.selectedClassUid, this.isDirty = false});

  Classroom? get selectedClass {
    if (selectedClassUid == null) return null;
    try {
      return classrooms.firstWhere((c) => c.uid == selectedClassUid);
    } catch (_) {
      return null;
    }
  }

  ClassState copyWith(
          {List<Classroom>? classrooms, String? selectedClassUid, bool? isDirty}) =>
      ClassState(
          classrooms: classrooms ?? this.classrooms,
          selectedClassUid: selectedClassUid ?? this.selectedClassUid,
          isDirty: isDirty ?? this.isDirty);
}

class ClassNotifier extends StateNotifier<ClassState> {
  ClassNotifier() : super(const ClassState());

  void loadFromData(List<Classroom> classrooms, String? uid) =>
      state = state.copyWith(
          classrooms: classrooms, selectedClassUid: uid, isDirty: false);

  void selectClass(String uid) => state = state.copyWith(selectedClassUid: uid);

  void addClass(String name) {
    final c = Classroom(uid: _uid(), name: name);
    state = state.copyWith(
        classrooms: [...state.classrooms, c],
        selectedClassUid: c.uid,
        isDirty: true);
  }

  void renameClass(String uid, String newName) {
    state = state.copyWith(
        classrooms: state.classrooms
            .map((c) => c.uid == uid ? c.copyWith(name: newName) : c)
            .toList(),
        isDirty: true);
  }

  void deleteClass(String uid) {
    state = state.copyWith(
        classrooms: state.classrooms.where((c) => c.uid != uid).toList(),
        selectedClassUid:
            state.selectedClassUid == uid ? null : state.selectedClassUid,
        isDirty: true);
  }

  void addGroup(String name) {
    final cls = state.selectedClass;
    if (cls == null) return;
    final g = Group(uid: _uid(), name: name);
    _up(cls.uid, (c) => c.copyWith(groups: [...c.groups, g]));
  }

  void renameGroup(String cid, String gid, String newName) {
    _up(cid, (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid ? g.copyWith(name: newName) : g)
            .toList()));
  }

  void deleteGroup(String cid, String gid) {
    _up(cid, (c) => c.copyWith(
        groups: c.groups.where((g) => g.uid != gid).toList()));
  }

  void addMember(String gid, String name, {double score = 0}) {
    final cls = state.selectedClass;
    if (cls == null) return;
    final m = Member(uid: _uid(), name: name, score: score);
    _up(cls.uid, (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(members: [...g.members, m])
                : g)
            .toList()));
  }

  void renameMember(String cid, String gid, String mid, String newName) {
    _up(cid, (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(
                    members: g.members
                        .map((m) =>
                            m.uid == mid ? m.copyWith(name: newName) : m)
                        .toList())
                : g)
            .toList()));
  }

  void deleteMember(String cid, String gid, String mid) {
    _up(cid, (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(
                    members: g.members.where((m) => m.uid != mid).toList())
                : g)
            .toList()));
  }

  void changeScore(String cid, String gid, String mid, double delta) {
    _up(cid, (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(
                    members: g.members.map((m) {
                      if (m.uid == mid) {
                        double ns = m.score + delta;
                        if (ns < 0) ns = 0;
                        return m.copyWith(score: ns);
                      }
                      return m;
                    }).toList())
                : g)
            .toList()));
  }

  /// 直接设置积分值（用于 Excel 导入等场景）
  void setScore(String cid, String gid, String mid, double newScore) {
    _up(cid, (c) => c.copyWith(
        groups: c.groups
            .map((g) => g.uid == gid
                ? g.copyWith(
                    members: g.members
                        .map((m) =>
                            m.uid == mid ? m.copyWith(score: newScore) : m)
                        .toList())
                : g)
            .toList()));
  }

  /// changeScoreRaw: setScore 的别名，保持向后兼容
  void changeScoreRaw(
      String cid, String gid, String mid, double newScore) {
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
                            .toList()))
                    .toList()))
            .toList(),
        isDirty: true);
  }

  void clearDirty() => state = state.copyWith(isDirty: false);

  void _up(String cid, Classroom Function(Classroom) f) {
    state = state.copyWith(
        classrooms: state.classrooms
            .map((c) => c.uid == cid ? f(c) : c)
            .toList(),
        isDirty: true);
  }

  static int _uuidCounter = DateTime.now().microsecondsSinceEpoch;
  static String _uid() => '${++_uuidCounter}-${DateTime.now().millisecondsSinceEpoch % 100000}';
}

final classProvider = StateNotifierProvider<ClassNotifier, ClassState>((ref) => ClassNotifier());
