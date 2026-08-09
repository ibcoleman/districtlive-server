import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:district_live/core/database/app_database.dart';

/// A star icon button that toggles bookmark state for an event.
/// Watches the bookmark status reactively via Drift stream.
/// Designed to work in AppBar actions.
class BookmarkStar extends ConsumerWidget {
  final String eventId;

  const BookmarkStar({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(appDatabaseProvider);

    return StreamBuilder<bool>(
      stream: database.bookmarkDao.watchIsBookmarked(eventId),
      initialData: false,
      builder: (context, snapshot) {
        final isBookmarked = snapshot.data ?? false;

        return IconButton(
          onPressed: () => database.bookmarkDao.toggle(eventId),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Icon(
              isBookmarked ? Icons.star : Icons.star_border,
              key: ValueKey(isBookmarked),
              color: isBookmarked ? Colors.amber : null,
            ),
          ),
          tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark this event',
        );
      },
    );
  }
}
