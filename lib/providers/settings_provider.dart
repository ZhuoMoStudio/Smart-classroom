import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier([SettingsState? initial])
    : super(initial ?? const SettingsState());
  void update(SettingsState newState) => state = newState;
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
