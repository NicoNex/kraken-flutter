import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../pages/settings.dart';

/// Encapsulates all networking + caching logic.
/// Fetches `/list` from AppSettings.baseUrl, caches result in SharedPreferences.
/// On error, returns last‐cached list if available.
class ApiService {
  static const String _cacheKey = 'cache_list';

  /// Returns a `List<String>` of JSON filenames.
  /// If the HTTP GET succeeds (status 200), decode/return JSON and overwrite cache.
  /// If it fails, tries to return whatever was in SharedPreferences under `_cacheKey`.
  static Future<List<String>> fetchJsonList() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Build URI from AppSettings (assumed defined in settings.dart).
      final uri = Uri.parse('${AppSettings.baseUrl}/list');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedString = utf8.decode(response.bodyBytes);
        // Overwrite cache
        await prefs.setString(_cacheKey, decodedString);
        final List<dynamic> raw = json.decode(decodedString);
        return raw.cast<String>();
      } else {
        throw Exception(
            'Failed to load JSON file list (status ${response.statusCode})');
      }
    } catch (e) {
      // On any error, try cached data
      final String? cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final List<dynamic> raw = json.decode(cached);
        return raw.cast<String>();
      }
      rethrow;
    }
  }
}
