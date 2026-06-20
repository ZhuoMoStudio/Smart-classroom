import 'package:http/http.dart' as http;
class NetworkTimeService {
  static Future<DateTime?> getNetworkTime() async {
    try {
      final r = await http.get(Uri.parse('https://www.timeapi.io/api/Time/current/zone?timeZone=UTC'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final dh = r.headers['date']; if (dh != null) return DateTime.parse(dh);
        return DateTime.now().toUtc();
      }
    } catch (_) {} return null;
  }
}
