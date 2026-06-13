import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import 'class_provider.dart';

class DrawState {
  final bool noReplacement;
  final String? lockedGroupUid;
  final List<String> removedMembers;
  final List<String> removedGroups;

  const DrawState({
    this.noReplacement = false,
    this.lockedGroupUid,
    this.removedMembers = const [],
    this.removedGroups = const [],
  });

  DrawState copyWith({
    bool? noReplacement,
    String? lockedGroupUid,
    List<String>? removedMembers,
    List<String>? removedGroups,
    bool clearLocked = false,
  }) =>
      DrawState(
        noReplacement: noReplacement ?? this.noReplacement,
        lockedGroupUid: clearLocked ? null : lockedGroupUid ?? this.lockedGroupUid,
        removedMembers: removedMembers ?? this.removedMembers,
        removedGroups: removedGroups ?? this.removedGroups,
      );
}

class DrawNotifier extends StateNotifier<DrawState> {
  final Ref _ref;
  DrawNotifier(this._ref) : super(const DrawState());

  Classroom? get _class => _ref.read(classProvider).selectedClass;

  void toggleNoReplacement() => state = state.copyWith(noReplacement: !state.noReplacement);

  void lockGroup(String groupUid) => state = state.copyWith(lockedGroupUid: groupUid);

  void unlockGroup() => state = state.copyWith(clearLocked: true);

  void addRemovedMember(String uid) => state = state.copyWith(removedMembers: [...state.removedMembers, uid]);

  void addRemovedGroup(String uid) => state = state.copyWith(removedGroups: [...state.removedGroups, uid]);

  void resetPools() => state = state.copyWith(removedMembers: [], removedGroups: []);

  List<Member> get availableMembers {
    final cls = _class;
    if (cls == null) return [];
    List<Member> pool;
    if (state.lockedGroupUid != null) {
      final g = cls.groups.cast<Group?>().firstWhere((g) => g!.uid == state.lockedGroupUid, orElse: () => null);
      pool = g?.members ?? [];
    } else {
      pool = cls.allMembers;
    }
    if (state.noReplacement) pool = pool.where((m) => !state.removedMembers.contains(m.uid)).toList();
    return pool;
  }

  List<Group> get availableGroups {
    final cls = _class;
    if (cls == null) return [];
    List<Group> pool = cls.groups;
    if (state.noReplacement) pool = pool.where((g) => !state.removedGroups.contains(g.uid)).toList();
    return pool;
  }

  Member? drawMember() {
    final pool = availableMembers;
    if (pool.isEmpty) return null;
    final result = pool[Random().nextInt(pool.length)];
    if (state.noReplacement) addRemovedMember(result.uid);
    return result;
  }

  Group? drawGroup() {
    final pool = availableGroups;
    if (pool.isEmpty) return null;
    final result = pool[Random().nextInt(pool.length)];
    if (state.noReplacement) addRemovedGroup(result.uid);
    return result;
  }
}

final drawProvider = StateNotifierProvider<DrawNotifier, DrawState>((ref) => DrawNotifier(ref));