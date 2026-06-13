enum SyncStatus { idle, syncing, online, offline, error }

class ConflictInfo {
  final String itemName;
  final String localVersion;
  final String remoteVersion;

  const ConflictInfo({
    required this.itemName,
    required this.localVersion,
    required this.remoteVersion,
  });
}