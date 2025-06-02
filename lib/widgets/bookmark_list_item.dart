import 'package:flutter/material.dart';

/// A single “bookmark” card in the list.
/// - [cardKey] is used by the parent to scroll to this card.
/// - [data] is a Map<String, dynamic> with fields 'text' and 'note'.
/// - [searchQuery] is used to highlight matching substrings.
/// - [isMatch] toggles a colored border when searching.
class BookmarkListItem extends StatelessWidget {
  final GlobalKey cardKey;
  final Map<String, dynamic> data;
  final String searchQuery;
  final bool isMatch;

  const BookmarkListItem({
    Key? key,
    required this.cardKey,
    required this.data,
    required this.searchQuery,
    required this.isMatch,
  }) : super(key: key);

  /// If [query] is empty, returns a normal SelectableText.
  /// Otherwise builds a SelectableText.rich with highlighted spans.
  Widget _buildSelectableHighlightedText(
      BuildContext context, String text, String query) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge;
    if (query.isEmpty) {
      return SelectableText(text, style: baseStyle);
    }

    final regExp = RegExp(RegExp.escape(query), caseSensitive: false);
    final spans = <TextSpan>[];
    int start = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: baseStyle?.copyWith(
          backgroundColor:
              Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          fontWeight: FontWeight.bold,
        ),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return SelectableText.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String bmText = (data['text'] ?? '').toString();
    final String bmNote = (data['note'] ?? '').toString();

    return Card(
      key: cardKey,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMatch
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectableHighlightedText(context, bmText, searchQuery),
            if (bmNote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildSelectableHighlightedText(
                    context, bmNote, searchQuery),
              ),
          ],
        ),
      ),
    );
  }
}
