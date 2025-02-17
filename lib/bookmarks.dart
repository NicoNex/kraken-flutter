import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'settings.dart';

class BookmarkPage extends StatefulWidget {
  final String filename;
  final Future<Map<String, dynamic>>? prefetchData;

  const BookmarkPage({
    Key? key,
    required this.filename,
    this.prefetchData,
  }) : super(key: key);

  /// Static helper method to prefetch bookmark data.
  static Future<Map<String, dynamic>> prefetchDataFor(String filename) async {
    final encFilename = Uri.encodeComponent(filename);
    final cacheKey = 'cache_json_$encFilename';
    final prefs = await SharedPreferences.getInstance();
    try {
      final response =
          await http.get(Uri.parse("${AppSettings.baseUrl}/json/$encFilename"));
      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        await prefs.setString(cacheKey, decodedResponse);
        return json.decode(decodedResponse) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load bookmark');
      }
    } catch (e) {
      // On error, try to load cached data.
      final String? cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return json.decode(cachedData) as Map<String, dynamic>;
      } else {
        rethrow;
      }
    }
  }

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  late Future<Map<String, dynamic>> _bookmarkFuture;

  @override
  void initState() {
    super.initState();
    _bookmarkFuture = widget.prefetchData ?? fetchBookmark();
  }

  /// Fetches the bookmark JSON and caches it.
  Future<Map<String, dynamic>> fetchBookmark() async {
    final encFilename = Uri.encodeComponent(widget.filename);
    final cacheKey = 'cache_json_$encFilename';
    final prefs = await SharedPreferences.getInstance();
    try {
      final response =
          await http.get(Uri.parse("${AppSettings.baseUrl}/json/$encFilename"));
      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        await prefs.setString(cacheKey, decodedResponse);
        return json.decode(decodedResponse) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load bookmark');
      }
    } catch (e) {
      // On error, try to load cached data.
      final String? cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return json.decode(cachedData) as Map<String, dynamic>;
      } else {
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _bookmarkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Loading..."),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Error"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (snapshot.hasData) {
          final book = snapshot.data!;
          final String title = book['title'] ?? 'No Title';
          final String author = book['author'] ?? 'Unknown Author';
          final List<dynamic> bookmarks = book['bookmarks'] ?? [];
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    author,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: bookmarks.isNotEmpty
                  ? ListView.builder(
                      itemCount: bookmarks.length,
                      itemBuilder: (context, index) {
                        final bookmark =
                            bookmarks[index] as Map<String, dynamic>;
                        final String text = bookmark['text'] ?? '';
                        final String note = bookmark['note'] ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                if (note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      note,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text("No bookmarks available")),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text("No Data"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
            body: const Center(child: Text("No data available")),
          );
        }
      },
    );
  }
}
