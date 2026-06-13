import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  SharedPreferences? _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String getString(String key, [String defaultValue = '']) => _prefs?.getString(key) ?? defaultValue;
  Future<void> setString(String key, String value) async => _prefs?.setString(key, value);

  bool getBool(String key, [bool defaultValue = false]) => _prefs?.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) async => _prefs?.setBool(key, value);

  int getInt(String key, [int defaultValue = 0]) => _prefs?.getInt(key) ?? defaultValue;
  Future<void> setInt(String key, int value) async => _prefs?.setInt(key, value);

  Future<void> setSecure(String key, String value) => _secure.write(key: key, value: value);
  Future<String?> getSecure(String key) => _secure.read(key: key);
  Future<void> deleteSecure(String key) => _secure.delete(key: key);
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());