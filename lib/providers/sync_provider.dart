import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_models.dart';

class SyncState {
  final SyncStatus status;
  final String? message, lastSyncTime;
  final double progress;
  final List<String> recentErrors;
  const SyncState({this.status = SyncStatus.idle, this.message, this.progress = 0.0,
      this.lastSyncTime, this.recentErrors = const []});
  SyncState copyWith({SyncStatus? status, String? message, double? progress,
      String? lastSyncTime, List<String>? recentErrors}) =>
      SyncState(status: status ?? this.status, message: message ?? this.message,
          progress: progress ?? this.progress, lastSyncTime: lastSyncTime ?? this.lastSyncTime,
          recentErrors: recentErrors ?? this.recentErrors);
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState());
  void startSync() => state = state.copyWith(status: SyncStatus.syncing, message: '正在同步...', progress: 0.0);
  void updateProgress(double p, [String? m]) => state = state.copyWith(progress: p, message: m);
  void syncComplete() => state = state.copyWith(status: SyncStatus.online, message: '同步完成',
      progress: 1.0, lastSyncTime: DateTime.now().toIso8601String());
  void syncError(String e) => state = state.copyWith(status: SyncStatus.error, message: e,
      recentErrors: [...state.recentErrors, e]);
  void setStatus(SyncStatus s) => state = state.copyWith(status: s);
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) => SyncNotifier());
