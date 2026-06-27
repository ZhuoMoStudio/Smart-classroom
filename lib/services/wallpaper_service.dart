import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WallpaperService {
  String? _path;
  Timer? _timer;
  String? get current => _path;

  Future<String?> fetchBing() async {
    try {
      final r = await http.get(
        Uri.parse(
          'https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1',
        ),
      );
      if (r.statusCode == 200)
        return 'https://www.bing.com${jsonDecode(r.body)['images'][0]['url']}';
    } catch (_) {}
    return null;
  }

  Future<String?> fetchUnsplash() async =>
      'https://source.unsplash.com/featured/1920x1080/?classroom';

  Future<void> download(String url) async {
    try {
      final r = await http.get(Uri.parse(url));
      if (r.statusCode == 200) {
        final f = File(
          '${(await getApplicationDocumentsDirectory()).path}/wallpaper.jpg',
        );
        await f.writeAsBytes(r.bodyBytes);
        _path = f.path;
      }
    } catch (_) {}
  }

  Future<void> setLocal(String path) async => _path = path;

  void schedule(int mins, Future<String?> Function() fetcher) {
    _timer?.cancel();
    if (mins <= 0) return;
    _timer = Timer.periodic(Duration(minutes: mins), (_) async {
      final url = await fetcher();
      if (url != null) await download(url);
    });
  }

  void dispose() => _timer?.cancel();
}
