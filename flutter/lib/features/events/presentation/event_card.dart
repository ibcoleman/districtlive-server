import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:district_live/features/events/domain/enums.dart';
import 'package:district_live/features/events/presentation/event_format_utils.dart';

/// A Material 3 card widget displaying a single event in a list.
/// Shows event image, title, date/time, venue, and price/age restrictions.
///
/// Generic type T allows flexibility for the event data source (EventsTableData, Event, etc.)
class EventCard<T> extends StatelessWidget {
  final T event;
  final DateTime startTime;
  final DateTime? doorsTime;
  final String title;
  final double? minPrice;
  final double? maxPrice;
  final String? priceTier;
  final String? imageUrl;
  final String ageRestriction;
  final String? venueName;
  final String? neighborhood;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.startTime,
    required this.title,
    required this.ageRestriction,
    this.doorsTime,
    this.minPrice,
    this.maxPrice,
    this.priceTier,
    this.imageUrl,
    this.venueName,
    this.neighborhood,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parse enums from stored string values
    final priceTierEnum = _parsePriceTier(priceTier);
    final ageRestrictionEnum = _parseAgeRestriction(ageRestriction);

    // Format date/time
    final dateTimeText = formatEventDateTime(startTime, doorsTime);

    // Format venue with neighborhood
    final venueWithNeighborhood = formatVenueWithNeighborhood(
      venueName,
      neighborhood,
    );

    // Format price
    final priceText = formatPrice(minPrice, maxPrice, priceTierEnum);

    // Format age
    final ageText = formatAge(ageRestrictionEnum);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image (left side)
              if (imageUrl != null && imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        _buildImagePlaceholder(),
                  ),
                )
              else
                _buildImagePlaceholder(),
              const SizedBox(width: 12),
              // Text content (right side)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date/time line
                    Text(
                      dateTimeText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Venue + neighborhood
                    Text(
                      venueWithNeighborhood.isNotEmpty
                          ? venueWithNeighborhood
                          : 'Venue TBA',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Price and age chips
                    Wrap(
                      spacing: 6,
                      children: [
                        if (priceText.isNotEmpty)
                          Chip(
                            label: Text(priceText),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (ageText.isNotEmpty)
                          Chip(
                            label: Text(ageText),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a placeholder for missing event image
  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.music_note,
        color: Colors.grey[600],
      ),
    );
  }

  /// Parse price tier from string
  PriceTier? _parsePriceTier(String? tierStr) {
    if (tierStr == null) return null;
    try {
      return PriceTier.values.firstWhere(
        (e) => e.toString().split('.').last == tierStr,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse age restriction from string
  AgeRestriction _parseAgeRestriction(String ageStr) {
    try {
      return AgeRestriction.values.firstWhere(
        (e) => e.toString().split('.').last == ageStr,
      );
    } catch (e) {
      return AgeRestriction.ALL_AGES;
    }
  }
}
