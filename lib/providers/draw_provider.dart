import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import 'class_provider.dart';

class DrawState {
  final bool noReplacement;
  final bool excludeDrawn;
  final String? lockedGroupUid;
  final List<String> removedMembers, removedGroups;
  final Set<String> drawnMemberUids;
  final Set<String> drawnGroupUids;

  const DrawState({
    this.noReplacement = false,
    this.excludeDrawn = false,
    this.lockedGroupUid,
    this.removedMembers = const [],
    this.removedGroups = const [],
    this.drawnMemberUids = const {},
    this.drawnGroupUids = const {},
  });

  DrawState copyWith({
    bool? noReplacement,
    bool? excludeDrawn,
    String? lockedGroupUid,
    List<String>? removedMembers,
    List<String>? removedGroups,
    Set<String>? drawnMemberUids,
    Set<String>? drawnGroupUids,
    bool clearLocked = false,
  }) =>
      DrawState(
        noReplacement: noReplacement ?? this.noReplacement,
        excludeDrawn: excludeDrawn ?? this.excludeDrawn,
        lockedGroupUid:
            clearLocked ? null : lockedGroupUid ?? this.lockedGroupUid,
        removedMembers: removedMembers ?? this.removedMembers,
        removedGroups: removedGroups ?? this.removedGroups,
        drawnMemberUids: drawnMemberUids ?? this.drawnMemberUids,
        drawnGroupUids: drawnGroupUids ?? this.drawnGroupUids,
      );
}

class DrawNotifier extends StateNotifier<DrawState> {
  final Ref _ref;
  DrawNotifier(this._ref) : super(const DrawState());

  Classroom? get _class => _ref.read(classProvider).selectedClass;

  void toggleNoReplacement() =>
      state = state.copyWith(noReplacement: !state.noReplacement);

  void toggleExcludeDrawn() =>
      state = state.copyWith(excludeDrawn: !state.excludeDrawn);

  void lockGroup(String gid) => state = state.copyWith(lockedGroupUid: gid);
  void unlockGroup() => state = state.copyWith(clearLocked: true);

  void addRemovedMember(String uid) =>
      state = state.copyWith(
          removedMembers: [...state.removedMembers, uid]);

  void addRemovedGroup(String uid) =>
      state = state.copyWith(
          removedGroups: [...state.removedGroups, uid]);

  void markMemberDrawn(String uid) =>
      state = state.copyWith(
          drawnMemberUids: {...state.drawnMemberUids, uid});

  void markGroupDrawn(String uid) =>
      state = state.copyWith(
          drawnGroupUids: {...state.drawnGroupUids, uid});

  void resetPools() => state = state.copyWith(
        removedMembers: [],
        removedGroups: [],
        drawnMemberUids: {},
        drawnGroupUids: {},
      );

  void resetDrawnOnly() => state = state.copyWith(
        drawnMemberUids: {},
        drawnGroupUids: {},
      );

  List<Member> get availableMembers {
    final cls = _class;
    if (cls == null) return [];
    List<Member> pool = state.lockedGroupUid != null
        ? (cls.groups
                .cast<Group?>()
                .firstWhere(
                  (g) => g!.uid == state.lockedGroupUid,
                  orElse: () => null,
                )
                ?.members ??
            [])
        : cls.allMembers;

    if (state.noReplacement) {
      pool = pool
          .where((m) => !state.removedMembers.contains(m.uid))
          .toList();
    }

    if (state.excludeDrawn) {
      pool = pool
          .where((m) => !state.drawnMemberUids.contains(m.uid))
          .toList();
    }

    return pool;
  }

  List<Group> get availableGroups {
    final cls = _class;
    if (cls == null) return [];
    List<Group> pool = cls.groups;

    if (state.noReplacement) {
      pool = pool
          .where((g) => !state.removedGroups.contains(g.uid))
          .toList();
    }

    if (state.excludeDrawn) {
      pool = pool
          .where((g) => !state.drawnGroupUids.contains(g.uid))
          .toList();
    }

    return pool;
  }

  Member? drawMember() {
    final pool = availableMembers;
    if (pool.isEmpty) return null;
    final r = pool[Random().nextInt(pool.length)];
    if (state.noReplacement) addRemovedMember(r.uid);
    if (state.excludeDrawn) markMemberDrawn(r.uid);
    return r;
  }

  Group? drawGroup() {
    final pool = availableGroups;
    if (pool.isEmpty) return null;
    final r = pool[Random().nextInt(pool.length)];
    if (state.noReplacement) addRemovedGroup(r.uid);
    if (state.excludeDrawn) markGroupDrawn(r.uid);
    return r;
  }
}

final drawProvider =
    StateNotifierProvider<DrawNotifier, DrawState>(
  (ref) => DrawNotifier(ref),
);
