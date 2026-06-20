enum SyncStatus { idle, syncing, online, offline, error }
class ConflictInfo {
  final String itemName, localVersion, remoteVersion;
  const ConflictInfo({required this.itemName, required this.localVersion, required this.remoteVersion});
}
