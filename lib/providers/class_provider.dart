import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/class_model.dart';

class ClassState {
  final List<Classroom> classrooms;
  final String? selectedClassUid;
  final bool isDirty;
  const ClassState({this.classrooms = const [], this.selectedClassUid, this.isDirty = false});

  Classroom? get selectedClass => selectedClassUid == null ? null
      : classrooms.cast<Classroom?>().firstWhere((c) => c!.uid == selectedClassUid, orElse: () => null);

  ClassState copyWith({List<Classroom>? classrooms, String? selectedClassUid, bool? isDirty}) =>
      ClassState(classrooms: classrooms ?? this.classrooms,
          selectedClassUid: selectedClassUid ?? this.selectedClassUid, isDirty: isDirty ?? this.isDirty);
}

class ClassNotifier extends StateNotifier<ClassState> {
  ClassNotifier() : super(const ClassState());

  void loadFromData(List<Classroom> classrooms, String? uid) =>
      state = state.copyWith(classrooms: classrooms, selectedClassUid: uid, isDirty: false);

  void selectClass(String uid) => state = state.copyWith(selectedClassUid: uid);

  void addClass(String name) {
    final c = Classroom(uid: const Uuid().v4(), name: name);
    state = state.copyWith(classrooms: [...state.classrooms, c], selectedClassUid: c.uid, isDirty: true);
  }

  void renameClass(String uid, String newName) {
    state = state.copyWith(
      classrooms: state.classrooms.map((c) => c.uid == uid ? c.copyWith(name: newName) : c).toList(),
      isDirty: true);
  }

  void deleteClass(String uid) {
    state = state.copyWith(
      classrooms: state.classrooms.where((c) => c.uid != uid).toList(),
      selectedClassUid: state.selectedClassUid == uid ? null : state.selectedClassUid, isDirty: true);
  }

  void addGroup(String name) {
    final cls = state.selectedClass; if (cls == null) return;
    final g = Group(uid: const Uuid().v4(), name: name);
    _up(cls.uid, (c) => c.copyWith(groups: [...c.groups, g]));
  }

  void renameGroup(String cid, String gid, String newName) {
    _up(cid, (c) => c.copyWith(groups: c.groups.map((g) => g.uid == gid ? g.copyWith(name: newName) : g).toList()));
  }

  void deleteGroup(String cid, String gid) {
    _up(cid, (c) => c.copyWith(groups: c.groups.where((g) => g.uid != gid).toList()));
  }

  void addMember(String gid, String name, {double score = 0}) {
    final cls = state.selectedClass; if (cls == null) return;
    final m = Member(uid: const Uuid().v4(), name: name, score: score);
    _up(cls.uid, (c) => c.copyWith(groups: c.groups.map((g) =>
        g.uid == gid ? g.copyWith(members: [...g.members, m]) : g).toList()));
  }

  void renameMember(String cid, String gid, String mid, String newName) {
    _up(cid, (c) => c.copyWith(groups: c.groups.map((g) => g.uid == gid
        ? g.copyWith(members: g.members.map((m) => m.uid == mid ? m.copyWith(name: newName) : m).toList()) : g).toList()));
  }

  void deleteMember(String cid, String gid, String mid) {
    _up(cid, (c) => c.copyWith(groups: c.groups.map((g) => g.uid == gid
        ? g.copyWith(members: g.members.where((m) => m.uid != mid).toList()) : g).toList()));
  }

  void changeScore(String cid, String gid, String mid, double delta) {
    _up(cid, (c) => c.copyWith(groups: c.groups.map((g) => g.uid == gid
        ? g.copyWith(members: g.members.map((m) {
            if (m.uid == mid) { double ns = m.score + delta; if (ns < 0) ns = 0; return m.copyWith(score: ns); }
            return m; }).toList()) : g).toList()));
  }

  void resetAllScores() {
    state = state.copyWith(
      classrooms: state.classrooms.map((c) => c.copyWith(groups: c.groups
          .map((g) => g.copyWith(members: g.members.map((m) => m.copyWith(score: 0)).toList())).toList())).toList(),
      isDirty: true);
  }

  void clearDirty() => state = state.copyWith(isDirty: false);

  void _up(String cid, Classroom Function(Classroom) f) {
    state = state.copyWith(
        classrooms: state.classrooms.map((c) => c.uid == cid ? f(c) : c).toList(), isDirty: true);
  }
}

final classProvider = StateNotifierProvider<ClassNotifier, ClassState>((ref) => ClassNotifier());
