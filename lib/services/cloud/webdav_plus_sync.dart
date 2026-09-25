import 'dart:io';
import 'dart:typed_data';

import 'package:webdav_plus/webdav_plus.dart';

import '../../providers/settings_provider.dart';

/// 远端目录结构（固定，不再散落各处字符串）
///
/// 约定：
///   <remoteFolder>/SmartClassroom/          ← 主目录 = 应用名称
///   <remoteFolder>/SmartClassroom/students/<年级班级>/<班级>.xlsx
///   <remoteFolder>/SmartClassroom/students/_unsorted/<班级>.xlsx
///   <remoteFolder>/SmartClassroom/questions/<题库>.xlsx
///
/// 为什么主目录用英文 `SmartClassroom` 而不是中文「灵动课堂」：
/// WebDAV 各家实现（坚果云 / Nextcloud / 自建）对非 ASCII 路径的处理并不一致，
/// 用英文名可以避开一整类只在某些服务端才出现的怪问题。
/// 年级子目录同样只用 ASCII（见 RosterManager.pathSegment）。
class RemoteLayout {
  RemoteLayout._();

  /// 应用主目录名
  static const String appRoot = 'SmartClassroom';
  static const String students = 'students';
  static const String questions = 'questions';

  /// 无法识别年级班级时的兜底子目录
  static const String unsorted = '_unsorted';
}

/// 一个远端条目。带上 modified/etag 才能做增量判断，
/// 而不是把整个目录来回覆盖。
class RemoteEntry {
  final String relativePath; // 相对 <remoteFolder>/SmartClassroom/
  final String fileName;
  final DateTime? modified;
  final int contentLength;
  final String? etag;

  const RemoteEntry({
    required this.relativePath,
    required this.fileName,
    this.modified,
    this.contentLength = 0,
    this.etag,
  });
}

/// WebDAV 同步服务（基于开源库 webdav_plus）
///
/// 只负责「传输」：连接、列目录、上传、下载、建目录。
/// 「同步策略」（谁更新、谁覆盖谁、冲突如何留底）在 SyncEngine 里，
/// 两者分开是为了让策略能独立演进、也能被单独推敲。
///
/// 关于 webdav_plus 自带的 Sync Collection（RFC 6578 增量同步）：
/// 本实现没有使用它，而是用 DavResource.modified/etag 自行比对。
/// 原因是 RFC 6578 需要服务端支持，而坚果云等常见服务是否实现无法在本项目中验证；
/// 一旦服务端不支持，整套同步会直接失效。用 lastModified 比对虽然多几次 PROPFIND，
/// 但在任何 WebDAV 服务上都成立。
class WebdavPlusSyncService {
  const WebdavPlusSyncService();

  /// 清洗一个路径段，使其不含 WebDAV 禁止的字符 `\ / : * ? " < > |`。
  ///
  /// 注意：**只能用于单个路径段**。
  /// 早期实现对整串路径做这一步，把 `/` 也替换成了 `_`，
  /// 结果 `学生信息/三年二班.xlsx` 被上传成根目录的 `学生信息_三年二班.xlsx`，
  /// 而下载端却在子目录里找 —— 两边永远对不上，云同步实际上从未成功过。
  static String safeSegment(String segment) =>
      segment.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_').trim();

  /// 拼出远端完整路径。只对「段」做清洗，保留 `/` 分隔符。
  static String remotePath(SettingsState settings, String relativePath) {
    final base = settings.remoteFolder.replaceAll(RegExp(r'/+$'), '');
    final segments = <String>[
      if (base.isNotEmpty) ...base.split('/').where((s) => s.isNotEmpty),
      RemoteLayout.appRoot,
      ...relativePath
          .split(RegExp(r'[/\\]+'))
          .where((s) => s.isNotEmpty && s != '.')
          .map(safeSegment),
    ];
    return '/${segments.join('/')}';
  }

  static Future<WebdavClient> createClient(
    SettingsState settings,
    String password,
  ) async {
    final client = WebdavClient.withCredentials(
      settings.webdavUsername,
      password,
    );
    client.setBaseUrl(settings.webdavUrl);
    return client;
  }

  /// 坚果云的固定连接参数，供界面预填与提示使用。
  ///
  /// 这些值来自坚果云的官方说明：
  ///   - 服务地址必须是 https://dav.jianguoyun.com/dav/ （端口 443，走 HTTPS）
  ///   - 用户名是注册邮箱/手机号
  ///   - 密码必须是「第三方应用密码」，不能用登录密码
  /// 最后一条是最常踩的坑：用登录密码填进去只会得到 401，
  /// 而 401 在界面上表现为「无法连接云端」，很难自己想到原因。
  static const String jianguoyunUrl = 'https://dav.jianguoyun.com/dav/';
  static const String jianguoyunRegisterUrl =
      'https://www.jianguoyun.com/signup';
  static const String jianguoyunAppPasswordHelp =
      '注册后进入「账户信息 → 安全选项 → 添加应用密码」，'
      '把生成的应用密码填到这里（不要用登录密码）。';

  /// 测试连接
  Future<bool> testConnection({
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      await client.list('/');
      await client.createDirectory(remotePath(settings, ''));
      await client.list(remotePath(settings, ''));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 确保应用主目录与各子目录存在
  Future<bool> ensureAppFolders({
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      for (final dir in const ['', RemoteLayout.students, RemoteLayout.questions]) {
        try {
          await client.createDirectory(remotePath(settings, dir));
        } catch (_) {
          // 目录已存在时不同服务端返回码不一，忽略即可；
          // 真正的失败会在后面的 list 里暴露出来。
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 列出一个远端目录下的文件（带 modified / etag）
  Future<List<RemoteEntry>> listDir({
    required SettingsState settings,
    required String password,
    required String relativeDir,
  }) async {
    try {
      final client = await createClient(settings, password);
      final resources = await client.list(remotePath(settings, relativeDir));
      final prefix = relativeDir.isEmpty ? '' : '$relativeDir/';
      return resources
          .where((r) => !r.isDirectory)
          .map((r) => RemoteEntry(
                relativePath: '$prefix${safeSegment(r.name)}',
                fileName: r.name,
                modified: r.modified,
                contentLength: r.contentLength,
                etag: r.etag,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// 递归列出名单目录：`students/` 本身 + 一层年级子目录。
  ///
  /// 只展开一层，是因为目录结构就是 `students/<年级班级>/<文件>`；
  /// 无限制递归会让每次同步都发大量 PROPFIND 请求，对移动网络不友好。
  Future<List<RemoteEntry>> listStudentsRecursive({
    required SettingsState settings,
    required String password,
  }) async {
    final out = <RemoteEntry>[];

    List<DavResource> top;
    try {
      final client = await createClient(settings, password);
      top = await client.list(remotePath(settings, RemoteLayout.students));
    } catch (_) {
      return out;
    }

    for (final r in top) {
      final seg = safeSegment(r.name);
      if (r.isDirectory) {
        out.addAll(await listDir(
          settings: settings,
          password: password,
          relativeDir: '${RemoteLayout.students}/$seg',
        ));
      } else if (r.name.toLowerCase().endsWith('.xlsx')) {
        // 兼容早期版本直接平铺在 students/ 下的文件
        out.add(RemoteEntry(
          relativePath: '${RemoteLayout.students}/$seg',
          fileName: r.name,
          modified: r.modified,
          contentLength: r.contentLength,
          etag: r.etag,
        ));
      }
    }
    return out;
  }

  /// 上传本地文件到指定的远端相对路径
  Future<bool> uploadFile({
    required String localPath,
    required String relativePath,
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      final file = File(localPath);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      await client.put(remotePath(settings, relativePath), bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 下载远端文件
  Future<Uint8List?> downloadFile({
    required String relativePath,
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      return await client.get(remotePath(settings, relativePath));
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteRemoteFile({
    required String relativePath,
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      await client.delete(remotePath(settings, relativePath));
      return true;
    } catch (_) {
      return false;
    }
  }
}
