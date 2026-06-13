import 'package:http/http.dart' as http;

class NetworkTimeService {
  static Future<DateTime?> getNetworkTime() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.timeapi.io/api/Time/current/zone?timeZone=UTC'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final dateHeader = response.headers['date'];
        if (dateHeader != null) return DateTime.parse(dateHeader);
        return DateTime.now().toUtc();
      }
    } catch (_) {}
    return null;
  }
}