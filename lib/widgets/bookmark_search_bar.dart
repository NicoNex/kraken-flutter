// lib/widgets/bookmark_search_bar.dart

import 'package:flutter/material.dart';

/// A search bar that animates in/out.
/// - [initialQuery]: initial text
/// - [onQueryChanged]: called whenever user types
/// - [onPrev]: user tapped “up arrow” to go to previous match
/// - [onNext]: user tapped “down arrow” to go to next match
/// - [onClose]: user tapped “close” icon
class BookmarkSearchBar extends StatelessWidget {
  final String initialQuery;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const BookmarkSearchBar({
    Key? key,
    required this.initialQuery,
    required this.onQueryChanged,
    required this.onPrev,
    required this.onNext,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('search_bar'),
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
              ),
              onChanged: onQueryChanged,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: onPrev,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            onPressed: onNext,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
