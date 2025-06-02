import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/api_service.dart';
import '../widgets/bookmark_card.dart';
import 'settings.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<List<String>> _filesFuture;

  @override
  void initState() {
    super.initState();
    _filesFuture = ApiService.fetchJsonList();
  }

  Future<void> _refreshFiles() async {
    // Force a fresh fetch from network
    setState(() {
      _filesFuture = ApiService.fetchJsonList();
    });
    await _filesFuture;
  }

  @override
  Widget build(BuildContext context) {
    final outlineColor = Theme.of(context).colorScheme.primary;

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
              setState(() {
                // In case baseUrl changed
                _filesFuture = ApiService.fetchJsonList();
              });
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _filesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final files = snapshot.data;
          if (files == null || files.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: RefreshIndicator(
                onRefresh: _refreshFiles,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Center(child: Text('No data available')),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshFiles,
            edgeOffset: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: MasonryGridView.count(
                physics: const AlwaysScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  return BookmarkCard(
                    filename: files[index],
                    outlineColor: outlineColor,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
