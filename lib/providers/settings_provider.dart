import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final String localeTag;
  final String? currentGrade;
  final String? currentSubject;
  final bool is24Hour, isDarkMode, soundEnabled, autoSync, autoSave;
  final String wallpaperSource, layoutMode, cloudServiceType, webdavUrl;
  final String webdavUsername, remoteFolder, syncStrategy, conflictStrategy;
  final String? wallpaperUrl;
  final int wallpaperInterval, autoSyncInterval, autoSaveInterval;
  final List<int> timerPresets;
  final String? usbDataPath;

  const SettingsState({
    this.localeTag = 'zh',
    this.currentGrade,
    this.currentSubject,
    this.is24Hour = true,
    this.isDarkMode = false,
    this.soundEnabled = true,
    this.wallpaperSource = 'none',
    this.wallpaperUrl,
    this.wallpaperInterval = 0,
    this.layoutMode = 'auto',
    this.timerPresets = const [5, 10, 15],
    this.cloudServiceType = '坚果云',
    this.webdavUrl = 'https://dav.jianguoyun.com/dav/',
    this.webdavUsername = '',
    this.remoteFolder = '/灵动课堂数据/',
    this.autoSync = false,
    this.autoSyncInterval = 0,
    this.syncStrategy = 'bidirectional',
    this.conflictStrategy = 'remote',
    this.autoSave = true,
    this.autoSaveInterval = 30,
    this.usbDataPath,
  });

  SettingsState copyWith({
    String? localeTag,
    String? currentGrade,
    String? currentSubject,
    bool? is24Hour,
    bool? isDarkMode,
    bool? soundEnabled,
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
  }) => SettingsState(
    localeTag: localeTag ?? this.localeTag,
    currentGrade: currentGrade ?? this.currentGrade,
    currentSubject: currentSubject ?? this.currentSubject,
    is24Hour: is24Hour ?? this.is24Hour,
    isDarkMode: isDarkMode ?? this.isDarkMode,
    soundEnabled: soundEnabled ?? this.soundEnabled,
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
  );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier([SettingsState? initial])
    : super(initial ?? const SettingsState());
  void update(SettingsState newState) => state = newState;
  void setGrade(String? grade) => state = state.copyWith(currentGrade: grade);
  void setSubject(String? subject) =>
      state = state.copyWith(currentSubject: subject);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
