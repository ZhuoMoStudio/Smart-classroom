import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final bool is24Hour;
  final bool isDarkMode;
  final String wallpaperSource;
  final String? wallpaperUrl;
  final int wallpaperInterval;
  final bool soundEnabled;
  final String layoutMode;
  final List<int> timerPresets;
  final String cloudServiceType;
  final String webdavUrl;
  final String webdavUsername;
  final String remoteFolder;
  final bool autoSync;
  final int autoSyncInterval;
  final String syncStrategy;
  final String conflictStrategy;
  final bool autoSave;
  final int autoSaveInterval;

  const SettingsState({
    this.is24Hour = true,
    this.isDarkMode = false,
    this.wallpaperSource = 'none',
    this.wallpaperUrl,
    this.wallpaperInterval = 0,
    this.soundEnabled = true,
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
  });

  SettingsState copyWith({
    bool? is24Hour,
    bool? isDarkMode,
    String? wallpaperSource,
    String? wallpaperUrl,
    int? wallpaperInterval,
    bool? soundEnabled,
    String? layoutMode,
    List<int>? timerPresets,
    String? cloudServiceType,
    String? webdavUrl,
    String? webdavUsername,
    String? remoteFolder,
    bool? autoSync,
    int? autoSyncInterval,
    String? syncStrategy,
    String? conflictStrategy,
    bool? autoSave,
    int? autoSaveInterval,
  }) =>
      SettingsState(
        is24Hour: is24Hour ?? this.is24Hour,
        isDarkMode: isDarkMode ?? this.isDarkMode,
        wallpaperSource: wallpaperSource ?? this.wallpaperSource,
        wallpaperUrl: wallpaperUrl ?? this.wallpaperUrl,
        wallpaperInterval: wallpaperInterval ?? this.wallpaperInterval,
        soundEnabled: soundEnabled ?? this.soundEnabled,
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
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier([SettingsState? initial]) : super(initial ?? const SettingsState());

  void update(SettingsState newState) => state = newState;
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());