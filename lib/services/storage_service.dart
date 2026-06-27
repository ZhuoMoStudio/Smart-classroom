import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  SharedPreferences? _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  Future<void> init() async { _prefs = await SharedPreferences.getInstance(); }

  String getString(String k, [String d='']) => _prefs?.getString(k) ?? d;
  Future<void> setString(String k, String v) async => _prefs?.setString(k, v);
  bool getBool(String k, [bool d=false]) => _prefs?.getBool(k) ?? d;
  Future<void> setBool(String k, bool v) async => _prefs?.setBool(k, v);
  int getInt(String k, [int d=0]) => _prefs?.getInt(k) ?? d;
  Future<void> setInt(String k, int v) async => _prefs?.setInt(k, v);
  Future<void> setSecure(String k, String v) async {
    try { await _secure.write(key: k, value: v); } catch (e) { debugPrint('FlutterSecureStorage write error: $e'); }
  }
  Future<String?> getSecure(String k) async {
    try { return await _secure.read(key: k); } catch (e) { debugPrint('FlutterSecureStorage read error: $e'); return null; }
  }
  Future<void> deleteSecure(String k) async {
    try { await _secure.delete(key: k); } catch (e) { debugPrint('FlutterSecureStorage delete error: $e'); }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
