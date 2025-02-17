import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bookmarks.dart';
import 'settings.dart'; // Use the persistent settings

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<List<String>> _jsonListFuture;

  @override
  void initState() {
    super.initState();
    _jsonListFuture = fetchJsonList(); // Cache the future.
  }

  /// Fetches the list of JSON file names using the base URL from settings.
  /// On success, caches the result; on failure, tries to return cached data.
  Future<List<String>> fetchJsonList() async {
    final prefs = await SharedPreferences.getInstance();
    const String cacheKey = 'cache_list';
    try {
      final response = await http.get(Uri.parse("${AppSettings.baseUrl}/list"));
      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        // Update cache.
        await prefs.setString(cacheKey, decodedResponse);
        final List<dynamic> files = json.decode(decodedResponse);
        return files.cast<String>();
      } else {
        throw Exception('Failed to load JSON file list');
      }
    } catch (e) {
      // On error, try to return cached data.
      final String? cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final List<dynamic> files = json.decode(cachedData);
        return files.cast<String>();
      } else {
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              setState(() {}); // Refresh UI if settings changed.
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _jsonListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final files = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: files.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  childAspectRatio: 3 / 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final filename = files[index];
                  final displayName = filename.endsWith('.json')
                      ? filename.substring(0, filename.length - 5)
                      : filename;
                  List<String> parts = displayName.split(' - ');
                  String bookTitle = parts[0];
                  String bookAuthor =
                      parts.length > 1 ? parts.sublist(1).join(' - ') : '';

                  return Card(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        // Start prefetching bookmark data.
                        Future<Map<String, dynamic>> prefetchedData =
                            BookmarkPage.prefetchDataFor(filename);
                        // Wait a little so the ripple animation shows.
                        await Future.delayed(const Duration(milliseconds: 150));
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookmarkPage(
                              filename: filename,
                              prefetchData: prefetchedData,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              bookTitle,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (bookAuthor.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  bookAuthor,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
