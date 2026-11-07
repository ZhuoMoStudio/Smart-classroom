import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_classroom/providers/settings_provider.dart';
import 'package:smart_classroom/services/storage_service.dart';

/// 设置持久化。
///
/// 旧实现只把设置放在内存里（`update()` 直接赋值），密码进了 Keystore，
/// 而账号/地址/开关全都没落盘：重启后 WebDAV 回到「未配置」，
/// 老师每次开机都要重填一遍。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsState JSON', () {
    test('往返序列化保留所有字段', () {
      const s = SettingsState(
        localeTag: 'en',
        is24Hour: false,
        isDarkMode: true,
        soundEnabled: false,
        hapticFeedback: false,
        autoSync: true,
        autoSave: false,
        wallpaperSource: 'url',
        wallpaperUrl: 'https://example.com/a.jpg',
        wallpaperInterval: 30,
        layoutMode: 'landscape',
        timerPresets: [1, 3, 5],
        cloudServiceType: 'Nextcloud',
        webdavUrl: 'https://cloud.example.com/dav/',
        webdavUsername: 'teacher@example.com',
        remoteFolder: '/MyData/',
        autoSyncInterval: 15,
        syncStrategy: 'upload_only',
        conflictStrategy: 'local',
        autoSaveInterval: 60,
        usbDataPath: '/mnt/usb',
        downloadSource: 'github',
      );

      final back = SettingsState.fromJson(s.toJson());
      expect(back.localeTag, 'en');
      expect(back.isDarkMode, isTrue);
      expect(back.soundEnabled, isFalse);
      expect(back.wallpaperUrl, 'https://example.com/a.jpg');
      expect(back.layoutMode, 'landscape');
      expect(back.timerPresets, [1, 3, 5]);
      expect(back.webdavUrl, 'https://cloud.example.com/dav/');
      expect(back.webdavUsername, 'teacher@example.com');
      expect(back.syncStrategy, 'upload_only');
      expect(back.downloadSource, 'github');
      expect(back.usbDataPath, '/mnt/usb');
    });

    test('空 JSON 回退到默认值', () {
      final s = SettingsState.fromJson(const <String, dynamic>{});
      expect(s.localeTag, 'zh');
      expect(s.isDarkMode, isFalse);
      expect(s.timerPresets, [5, 10, 15]);
      expect(s.webdavUrl, 'https://dav.jianguoyun.com/dav/');
    });

    test('字段类型不对时逐项回退，不抛异常', () {
      final s = SettingsState.fromJson(const <String, dynamic>{
        'isDarkMode': 'yes',
        'autoSaveInterval': '30',
        'timerPresets': ['a', 5, 10],
      });
      expect(s.isDarkMode, isFalse);
      expect(s.autoSaveInterval, 30);
      expect(s.timerPresets, [5, 10]);
    });
  });

  group('SettingsNotifier 落盘', () {
    test('update 后新建 notifier 能读回', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = StorageService();
      await storage.init();

      final first = SettingsNotifier(storage);
      first.update(first.state.copyWith(
        isDarkMode: true,
        webdavUsername: 'teacher@example.com',
        timerPresets: const [2, 4, 6],
      ));
      // setString 是异步的，等它落盘
      await Future<void>.delayed(Duration.zero);

      final second = SettingsNotifier(storage);
      expect(second.state.isDarkMode, isTrue);
      expect(second.state.webdavUsername, 'teacher@example.com');
      expect(second.state.timerPresets, [2, 4, 6]);
    });

    test('存档损坏时用默认值启动', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SettingsNotifier.storageKey: '{ 这不是 JSON',
      });
      final storage = StorageService();
      await storage.init();

      final n = SettingsNotifier(storage);
      expect(n.state.localeTag, 'zh');
      expect(n.state.soundEnabled, isTrue);
    });
  });
}
