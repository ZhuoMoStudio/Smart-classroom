import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkTimeService {
  static Future<DateTime?> getNetworkTime() async {
    try {
      final r = await http
          .get(
            Uri.parse(
              'https://www.timeapi.io/api/Time/current/zone?timeZone=UTC',
            ),
          )
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final datetimeStr = body['datetime'] as String?;
        if (datetimeStr != null) {
          return DateTime.parse(datetimeStr);
        }
      }
    } catch (_) {}
    return null;
  }
}
