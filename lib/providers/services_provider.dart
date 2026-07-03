import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';
import '../services/cloud/webdav_plus_sync.dart';
import '../services/cloud/cloud_storage_service.dart';

final fileServiceProvider = Provider<FileService>((ref) => FileService());

/// WebdavPlusSyncService 是无状态的常量服务，无需 Provider 包裹
final webdavSyncServiceProvider = Provider<WebdavPlusSyncService>(
  (ref) => const WebdavPlusSyncService(),
);

final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  return CloudStorageService(ref, ref.watch(webdavSyncServiceProvider));
});
