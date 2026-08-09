import 'package:flutter/material.dart';

/// A Material 3 card widget displaying a single venue in a list.
/// Shows venue name, neighborhood (optional), and upcoming event count.
///
/// The card has a Row layout with:
/// - Left side (expanded): venue name (titleMedium, bold) + neighborhood (bodySmall, secondary color, optional)
/// - Right side: upcoming event count badge ("X shows", labelMedium, primary color)
class VenueCard extends StatelessWidget {
  final String name;
  final String? neighborhood;
  final int upcomingEventCount;
  final VoidCallback? onTap;

  const VenueCard({
    super.key,
    required this.name,
    required this.upcomingEventCount,
    this.neighborhood,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (neighborhood != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        neighborhood!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$upcomingEventCount shows',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
