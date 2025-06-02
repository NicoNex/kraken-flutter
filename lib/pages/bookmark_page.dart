import 'package:flutter/material.dart';
import '../services/bookmark_service.dart';
import '../widgets/bookmark_list_item.dart';
import '../widgets/bookmark_search_bar.dart';
import 'settings.dart';

class BookmarkPage extends StatefulWidget {
  final String filename;
  final Future<Map<String, dynamic>>? prefetchData;

  const BookmarkPage({
    Key? key,
    required this.filename,
    this.prefetchData,
  }) : super(key: key);

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  late Future<Map<String, dynamic>> _bookmarkFuture;

  bool isSearching = false;
  String searchQuery = '';
  int currentMatchIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // One GlobalKey per bookmark, so we can scroll to that card programmatically.
  List<GlobalKey> cardKeys = [];

  // Key for the title widget, to show full title in a popup.
  final GlobalKey _titleTextKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _bookmarkFuture =
        widget.prefetchData ?? BookmarkService.fetchBookmark(widget.filename);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshBookmark() async {
    setState(() {
      _bookmarkFuture = BookmarkService.fetchBookmark(widget.filename);
    });
    await _bookmarkFuture;
  }

  /// Scroll so that [cardKey] is positioned at the top of the ListView.
  void _scrollToCard(GlobalKey cardKey) {
    final cardContext = cardKey.currentContext;
    if (cardContext == null) return;

    final box = cardContext.findRenderObject() as RenderBox?;
    if (box == null) return;

    final listBox = _scrollController.position.context.storageContext
        .findRenderObject() as RenderBox?;
    if (listBox == null) return;

    final offset = box.localToGlobal(Offset.zero, ancestor: listBox).dy;
    final targetOffset = _scrollController.offset + offset;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Show a small “bubble” menu under the AppBar title with the full title.
  void _showTitleBubble(BuildContext context, String fullTitle) {
    final renderBox =
        _titleTextKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        0.0,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              fullTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the FloatingActionButton (search icon).
  Widget _buildFab() {
    return FloatingActionButton(
      key: const ValueKey('fab'),
      onPressed: () => setState(() => isSearching = true),
      child: const Icon(Icons.search),
    );
  }

  /// Custom transition for AnimatedSwitcher between FAB and SearchBar.
  Widget _transitionBuilder(Widget child, Animation<double> animation) {
    if (child.key == const ValueKey('search_bar')) {
      final offsetAnim = Tween<Offset>(
              begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offsetAnim, child: child),
      );
    } else {
      return FadeTransition(opacity: animation, child: child);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _bookmarkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildScaffold(
            appBarTitle: 'Loading...',
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return _buildScaffold(
            appBarTitle: 'Error',
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final String bookTitle = data['title'] ?? 'No Title';
          final String author = data['author'] ?? 'Unknown Author';
          final List<dynamic> bookmarks =
              (data['bookmarks'] as List<dynamic>?) ?? [];

          // Sync the cardKeys list length with number of bookmark items.
          if (cardKeys.length != bookmarks.length) {
            cardKeys = List.generate(bookmarks.length, (_) => GlobalKey());
          }

          // Build a list of indices matching searchQuery.
          final lowerQuery = searchQuery.toLowerCase();
          final matchingIndices = <int>[];
          for (var i = 0; i < bookmarks.length; i++) {
            final bm = bookmarks[i] as Map<String, dynamic>;
            final text = (bm['text'] ?? '').toString().toLowerCase();
            final note = (bm['note'] ?? '').toString().toLowerCase();
            if (searchQuery.isEmpty ||
                text.contains(lowerQuery) ||
                note.contains(lowerQuery)) {
              matchingIndices.add(i);
            }
          }

          return _buildMainScaffold(
            context,
            bookTitle,
            author,
            bookmarks,
            matchingIndices,
          );
        } else {
          return _buildScaffold(
            appBarTitle: 'No Data',
            body: const Center(child: Text('No data available')),
          );
        }
      },
    );
  }

  /// A simple Scaffold with an AppBar title and a body widget.
  Scaffold _buildScaffold({
    required String appBarTitle,
    required Widget body,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: body,
    );
  }

  /// The main Scaffold after data is loaded: shows AppBar, RefreshIndicator + ListView,
  /// plus the FAB/search-bar switch.
  Scaffold _buildMainScaffold(
    BuildContext context,
    String bookTitle,
    String author,
    List<dynamic> bookmarks,
    List<int> matchingIndices,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              key: _titleTextKey,
              onTap: () => _showTitleBubble(context, bookTitle),
              child: Text(
                bookTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
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
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBookmark,
        edgeOffset: 0,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8.0),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bm = bookmarks[index] as Map<String, dynamic>;
            final isMatch = matchingIndices.contains(index);

            return BookmarkListItem(
              cardKey: cardKeys[index],
              data: bm,
              searchQuery: searchQuery,
              isMatch: isMatch,
            );
          },
        ),
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // FAB (when not searching)
          Positioned(
            bottom: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: _transitionBuilder,
              child: isSearching ? const SizedBox() : _buildFab(),
            ),
          ),
          // Search bar (when searching)
          Positioned(
            bottom: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: _transitionBuilder,
              child: isSearching
                  ? BookmarkSearchBar(
                      initialQuery: searchQuery,
                      onQueryChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          currentMatchIndex = 0;
                        });
                      },
                      onPrev: () {
                        if (matchingIndices.isEmpty) return;
                        setState(() {
                          currentMatchIndex =
                              (currentMatchIndex - 1 + matchingIndices.length) %
                                  matchingIndices.length;
                        });
                        final key =
                            cardKeys[matchingIndices[currentMatchIndex]];
                        _scrollToCard(key);
                      },
                      onNext: () {
                        if (matchingIndices.isEmpty) return;
                        setState(() {
                          currentMatchIndex =
                              (currentMatchIndex + 1) % matchingIndices.length;
                        });
                        final key =
                            cardKeys[matchingIndices[currentMatchIndex]];
                        _scrollToCard(key);
                      },
                      onClose: () {
                        setState(() {
                          isSearching = false;
                          searchQuery = '';
                        });
                      },
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}
