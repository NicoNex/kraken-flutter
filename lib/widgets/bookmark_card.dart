import 'package:flutter/material.dart';
import '../services/bookmark_service.dart';
import '../pages/bookmark_page.dart';

/// A reusable “card” widget that displays a single filename.
/// Tapping it will navigate to BookmarkPage (from bookmark_page.dart).
class BookmarkCard extends StatelessWidget {
  final String filename;
  final Color outlineColor;

  const BookmarkCard({
    super.key,
    required this.filename,
    required this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    // Remove “.json” for display, split on “ - ” into title + author
    final displayName = filename.endsWith('.json')
        ? filename.substring(0, filename.length - 5)
        : filename;
    final parts = displayName.split(' - ');
    final bookTitle = parts.isNotEmpty ? parts[0] : '';
    final bookAuthor = (parts.length > 1) ? parts.sublist(1).join(' - ') : '';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outlineColor, width: 2),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Use BookmarkService to prefetch
          final prefetchData = BookmarkService.fetchBookmark(filename);
          // Allow ripple animation to show briefly
          await Future.delayed(const Duration(milliseconds: 150));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookmarkPage(
                filename: filename,
                prefetchData: prefetchData,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bookTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              ),
              if (bookAuthor.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    bookAuthor,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
