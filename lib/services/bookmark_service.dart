// lib/services/bookmark_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/settings.dart';

/// Exposes methods to fetch (and cache) a single JSON “bookmark” file.
/// Both methods return a Map<String, dynamic> parsed from JSON.
class BookmarkService {
  /// Attempts a network GET to “/json/<encodedFilename>”.
  /// On success, writes the raw JSON string into SharedPreferences under cacheKey
  /// (“cache_json_<encodedFilename>”), then returns parsed JSON.
  /// On any error, attempts to read & return the cached JSON (if available).
  static Future<Map<String, dynamic>> fetchBookmark(String filename) async {
    final encoded = Uri.encodeComponent(filename);
    final cacheKey = 'cache_json_$encoded';
    final prefs = await SharedPreferences.getInstance();

    try {
      final uri = Uri.parse('${AppSettings.baseUrl}/json/$encoded');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedString = utf8.decode(response.bodyBytes);
        await prefs.setString(cacheKey, decodedString);
        return json.decode(decodedString) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to load bookmark file (status ${response.statusCode})');
      }
    } catch (_) {
      // On error, try cached data
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        return json.decode(cached) as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  /// A convenience method to “prefetch” and return the same JSON map.
  /// Exactly the same logic as fetchBookmark(), but exposed statically for callers.
  static Future<Map<String, dynamic>> prefetchDataFor(String filename) {
    return fetchBookmark(filename);
  }
}
