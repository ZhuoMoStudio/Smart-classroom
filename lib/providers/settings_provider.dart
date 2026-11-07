import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// 应用设置。
///
/// 这些值**必须持久化**：老师花时间配好的 WebDAV 地址、账号、同步策略，
/// 以及深色模式、音效开关，如果每次启动都回到默认值，等于每次开机都要重配。
/// 早期版本只把状态放在内存里（`update()` 直接 `state = ...`），
/// 密码进了 Keystore 而账号根本没落盘 —— 重启后云同步必然「未配置」。
class SettingsState {
  final String localeTag;
  final bool is24Hour, isDarkMode, soundEnabled, hapticFeedback, autoSync, autoSave;
  final String wallpaperSource, layoutMode, cloudServiceType, webdavUrl;
  final String webdavUsername, remoteFolder, syncStrategy, conflictStrategy;
  final String? wallpaperUrl;
  final int wallpaperInterval, autoSyncInterval, autoSaveInterval;
  final List<int> timerPresets;
  final String? usbDataPath;
  /// 下载源：'github' 或 'mirror'（国内镜像）
  final String downloadSource;

  const SettingsState({
    this.localeTag = 'zh',
    this.is24Hour = true,
    this.isDarkMode = false,
    this.soundEnabled = true,
    this.hapticFeedback = true,
    this.wallpaperSource = 'none',
    this.wallpaperUrl,
    this.wallpaperInterval = 0,
    this.layoutMode = 'auto',
    this.timerPresets = const [5, 10, 15],
    this.cloudServiceType = '坚果云',
    this.webdavUrl = 'https://dav.jianguoyun.com/dav/',
    this.webdavUsername = '',
    this.remoteFolder = '/SmartClassroomData/',
    this.autoSync = false,
    this.autoSyncInterval = 0,
    this.syncStrategy = 'bidirectional',
    this.conflictStrategy = 'remote',
    this.autoSave = true,
    this.autoSaveInterval = 30,
    this.usbDataPath,
    this.downloadSource = 'mirror',
  });

  SettingsState copyWith({
    String? localeTag,
    bool? is24Hour,
    bool? isDarkMode,
    bool? soundEnabled,
    bool? hapticFeedback,
    bool? autoSync,
    bool? autoSave,
    String? wallpaperSource,
    String? wallpaperUrl,
    int? wallpaperInterval,
    String? layoutMode,
    List<int>? timerPresets,
    String? cloudServiceType,
    String? webdavUrl,
    String? webdavUsername,
    String? remoteFolder,
    int? autoSyncInterval,
    String? syncStrategy,
    String? conflictStrategy,
    int? autoSaveInterval,
    String? usbDataPath,
    String? downloadSource,
  }) => SettingsState(
    localeTag: localeTag ?? this.localeTag,
    is24Hour: is24Hour ?? this.is24Hour,
    isDarkMode: isDarkMode ?? this.isDarkMode,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    wallpaperSource: wallpaperSource ?? this.wallpaperSource,
    wallpaperUrl: wallpaperUrl ?? this.wallpaperUrl,
    wallpaperInterval: wallpaperInterval ?? this.wallpaperInterval,
    layoutMode: layoutMode ?? this.layoutMode,
    timerPresets: timerPresets ?? this.timerPresets,
    cloudServiceType: cloudServiceType ?? this.cloudServiceType,
    webdavUrl: webdavUrl ?? this.webdavUrl,
    webdavUsername: webdavUsername ?? this.webdavUsername,
    remoteFolder: remoteFolder ?? this.remoteFolder,
    autoSync: autoSync ?? this.autoSync,
    autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
    syncStrategy: syncStrategy ?? this.syncStrategy,
    conflictStrategy: conflictStrategy ?? this.conflictStrategy,
    autoSave: autoSave ?? this.autoSave,
    autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
    usbDataPath: usbDataPath ?? this.usbDataPath,
    downloadSource: downloadSource ?? this.downloadSource,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'localeTag': localeTag,
        'is24Hour': is24Hour,
        'isDarkMode': isDarkMode,
        'soundEnabled': soundEnabled,
        'hapticFeedback': hapticFeedback,
        'autoSync': autoSync,
        'autoSave': autoSave,
        'wallpaperSource': wallpaperSource,
        'wallpaperUrl': wallpaperUrl,
        'wallpaperInterval': wallpaperInterval,
        'layoutMode': layoutMode,
        'timerPresets': timerPresets,
        'cloudServiceType': cloudServiceType,
        'webdavUrl': webdavUrl,
        'webdavUsername': webdavUsername,
        'remoteFolder': remoteFolder,
        'autoSyncInterval': autoSyncInterval,
        'syncStrategy': syncStrategy,
        'conflictStrategy': conflictStrategy,
        'autoSaveInterval': autoSaveInterval,
        'usbDataPath': usbDataPath,
        'downloadSource': downloadSource,
      };

  /// 容错解析：字段缺失/类型不对时回退到默认值，绝不因为一条坏数据就崩溃。
  factory SettingsState.fromJson(Map<String, dynamic> j) {
    T pick<T>(String key, T fallback) {
      final v = j[key];
      return v is T ? v : fallback;
    }

    const d = SettingsState();
    return SettingsState(
      localeTag: pick('localeTag', d.localeTag),
      is24Hour: pick('is24Hour', d.is24Hour),
      isDarkMode: pick('isDarkMode', d.isDarkMode),
      soundEnabled: pick('soundEnabled', d.soundEnabled),
      hapticFeedback: pick('hapticFeedback', d.hapticFeedback),
      autoSync: pick('autoSync', d.autoSync),
      autoSave: pick('autoSave', d.autoSave),
      wallpaperSource: pick('wallpaperSource', d.wallpaperSource),
      wallpaperUrl: pick('wallpaperUrl', d.wallpaperUrl),
      wallpaperInterval: pick('wallpaperInterval', d.wallpaperInterval),
      layoutMode: pick('layoutMode', d.layoutMode),
      timerPresets: (j['timerPresets'] is List)
          ? (j['timerPresets'] as List).whereType<int>().toList()
          : d.timerPresets,
      cloudServiceType: pick('cloudServiceType', d.cloudServiceType),
      webdavUrl: pick('webdavUrl', d.webdavUrl),
      webdavUsername: pick('webdavUsername', d.webdavUsername),
      remoteFolder: pick('remoteFolder', d.remoteFolder),
      autoSyncInterval: pick('autoSyncInterval', d.autoSyncInterval),
      syncStrategy: pick('syncStrategy', d.syncStrategy),
      conflictStrategy: pick('conflictStrategy', d.conflictStrategy),
      autoSaveInterval: pick('autoSaveInterval', d.autoSaveInterval),
      usbDataPath: pick('usbDataPath', d.usbDataPath),
      downloadSource: pick('downloadSource', d.downloadSource),
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._storage) : super(_load(_storage));

  static const String storageKey = 'settings_json';

  final StorageService _storage;

  static SettingsState _load(StorageService storage) {
    final raw = storage.getString(storageKey);
    if (raw.isEmpty) return const SettingsState();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const SettingsState();
      return SettingsState.fromJson(decoded);
    } catch (e) {
      // 设置读不出来时用默认值继续，不能让应用起不来
      debugPrint('读取设置失败，使用默认值：$e');
      return const SettingsState();
    }
  }

  void update(SettingsState newState) {
    if (identical(newState, state)) return;
    state = newState;
    _persist();
  }

  void _persist() {
    // 不做防抖：设置改动频率很低（点开关 / 输完地址），
    // 而丢一次写入的代价是老师下次开机重新配置。
    _storage.setString(storageKey, jsonEncode(state.toJson()));
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref.read(storageServiceProvider)),
);
