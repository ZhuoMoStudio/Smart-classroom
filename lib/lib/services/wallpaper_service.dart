import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WallpaperService {
  String? _currentWallpaperPath;
  Timer? _timer;

  String? get currentWallpaper => _currentWallpaperPath;

  Future<String?> fetchBingWallpaper() async {
    try {
      final response = await http.get(Uri.parse('https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return 'https://www.bing.com${json['images'][0]['url']}';
      }
    } catch (_) {}
    return null;
  }

  Future<String?> fetchUnsplashWallpaper() async {
    return 'https://source.unsplash.com/featured/1920x1080/?classroom';
  }

  Future<void> downloadWallpaper(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/wallpaper.jpg');
        await file.writeAsBytes(response.bodyBytes);
        _currentWallpaperPath = file.path;
      }
    } catch (_) {}
  }

  Future<void> setLocalWallpaper(String path) async => _currentWallpaperPath = path;

  void scheduleAutoChange(int intervalMinutes, Future<String?> Function() fetcher) {
    _timer?.cancel();
    if (intervalMinutes <= 0) return;
    _timer = Timer.periodic(Duration(minutes: intervalMinutes), (_) async {
      final url = await fetcher();
      if (url != null) await downloadWallpaper(url);
    });
  }

  void dispose() => _timer?.cancel();
}