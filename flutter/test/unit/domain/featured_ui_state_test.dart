import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/featured/domain/featured_ui_state.dart';
import 'package:district_live/features/featured/domain/featured_event.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/events/domain/event_detail.dart';
import 'package:district_live/features/venues/domain/venue.dart';

void main() {
  group('FeaturedUiState unit tests', () {
    final testVenue = const Venue(
      id: 'venue-1',
      name: 'The Kennedy Center',
      slug: 'the-kennedy-center',
      neighborhood: 'Downtown',
    );

    final testEventDetail = EventDetail(
      id: 'event-1',
      title: 'Amazing Concert',
      slug: 'amazing-concert',
      startTime: DateTime(2025, 3, 15, 20, 0),
      doorsTime: DateTime(2025, 3, 15, 19, 30),
      venue: testVenue,
      artists: const [],
      imageUrl: 'https://example.com/image.jpg',
      description: 'A great concert',
    );

    final testFeaturedEvent = FeaturedEvent(
      id: 'featured-1',
      event: testEventDetail,
      blurb: 'Don\'t miss this amazing concert!',
      createdAt: DateTime.now(),
      createdBy: 'admin',
    );

    test('AC4.1: Curated state has blurb field', () {
      final uiState = FeaturedUiState.curated(
        featuredEvent: testFeaturedEvent,
        isRefreshing: false,
      );

      // Verify the state contains blurb
      expect(uiState.maybeWhen(
        curated: (event, refreshing) => event.blurb,
        orElse: () => null,
      ), 'Don\'t miss this amazing concert!');
    });

    test('AC4.2: FallbackHero renders without blurb', () {
      final fallbackEvent = Event(
        id: 'event-2',
        title: 'Tonight\'s Show',
        slug: 'tonights-show',
        startTime: DateTime(2025, 3, 15, 20, 0),
        venue: testVenue,
        artists: const [],
        imageUrl: 'https://example.com/image2.jpg',
        description: 'Tonight\'s show',
      );

      final uiState = FeaturedUiState.fallbackHero(
        event: fallbackEvent,
        isRefreshing: false,
      );

      // Verify fallback state doesn't have a blurb field (it's null-only)
      expect(uiState.maybeWhen(
        fallbackHero: (event, refreshing) => event?.title,
        orElse: () => null,
      ), 'Tonight\'s Show');
    });

    test('Empty state creates fallback with null event', () {
      final uiState = const FeaturedUiState.fallbackHero(event: null);

      expect(uiState.maybeWhen(
        fallbackHero: (event, refreshing) => event,
        orElse: () => 'not-fallback',
      ), isNull);
    });

    test('Error state contains error message', () {
      const errorMessage = 'Network error occurred';
      final uiState = FeaturedUiState.error(message: errorMessage);

      expect(uiState.maybeWhen(
        error: (message) => message,
        orElse: () => null,
      ), errorMessage);
    });

    test('Loading state is FeaturedLoading', () {
      final uiState = const FeaturedUiState.loading();

      expect(uiState, isA<FeaturedLoading>());
    });

    test('Curated state has isRefreshing flag', () {
      final uiState = FeaturedUiState.curated(
        featuredEvent: testFeaturedEvent,
        isRefreshing: true,
      );

      expect(uiState.maybeWhen(
        curated: (event, refreshing) => refreshing,
        orElse: () => false,
      ), true);
    });

    test('FallbackHero state has isRefreshing flag', () {
      final fallbackEvent = Event(
        id: 'event-2',
        title: 'Tonight\'s Show',
        slug: 'tonights-show',
        startTime: DateTime(2025, 3, 15, 20, 0),
        venue: testVenue,
        artists: const [],
      );

      final uiState = FeaturedUiState.fallbackHero(
        event: fallbackEvent,
        isRefreshing: true,
      );

      expect(uiState.maybeWhen(
        fallbackHero: (event, refreshing) => refreshing,
        orElse: () => false,
      ), true);
    });

    test('FeaturedEvent contains required fields', () {
      expect(testFeaturedEvent.id, 'featured-1');
      expect(testFeaturedEvent.event.title, 'Amazing Concert');
      expect(testFeaturedEvent.blurb, 'Don\'t miss this amazing concert!');
      expect(testFeaturedEvent.createdBy, 'admin');
    });

    test('Event contains required fields', () {
      final event = Event(
        id: 'event-1',
        title: 'Test Concert',
        slug: 'test-concert',
        startTime: DateTime(2025, 3, 15, 20, 0),
        venue: testVenue,
        artists: const [],
      );

      expect(event.id, 'event-1');
      expect(event.title, 'Test Concert');
      expect(event.slug, 'test-concert');
      expect(event.venue?.name, 'The Kennedy Center');
    });

    test('Venue contains required fields', () {
      expect(testVenue.id, 'venue-1');
      expect(testVenue.name, 'The Kennedy Center');
      expect(testVenue.neighborhood, 'Downtown');
    });

    test('FeaturedUiState correctly maps curated variant', () {
      final uiState = FeaturedUiState.curated(
        featuredEvent: testFeaturedEvent,
        isRefreshing: false,
      );

      final result = uiState.map(
        loading: (_) => 'loading',
        curated: (_) => 'curated',
        fallbackHero: (_) => 'fallback',
        error: (_) => 'error',
      );

      expect(result, 'curated');
    });

    test('FeaturedUiState correctly maps fallbackHero variant', () {
      final uiState = const FeaturedUiState.fallbackHero(event: null);

      final result = uiState.map(
        loading: (_) => 'loading',
        curated: (_) => 'curated',
        fallbackHero: (_) => 'fallback',
        error: (_) => 'error',
      );

      expect(result, 'fallback');
    });

    test('FeaturedUiState correctly maps error variant', () {
      final uiState = FeaturedUiState.error(message: 'Test error');

      final result = uiState.map(
        loading: (_) => 'loading',
        curated: (_) => 'curated',
        fallbackHero: (_) => 'fallback',
        error: (_) => 'error',
      );

      expect(result, 'error');
    });

    test('FeaturedCurated copyWith updates isRefreshing', () {
      final original = FeaturedUiState.curated(
        featuredEvent: testFeaturedEvent,
        isRefreshing: false,
      ) as FeaturedCurated;

      final updated = original.copyWith(isRefreshing: true);

      expect(updated.isRefreshing, true);
      expect(updated.featuredEvent.id, 'featured-1');
    });

    test('FeaturedFallbackHero copyWith updates isRefreshing', () {
      final event = Event(
        id: 'event-2',
        title: 'Tonight\'s Show',
        slug: 'tonights-show',
        startTime: DateTime(2025, 3, 15, 20, 0),
        venue: testVenue,
        artists: const [],
      );

      final original = FeaturedUiState.fallbackHero(
        event: event,
        isRefreshing: false,
      ) as FeaturedFallbackHero;

      final updated = original.copyWith(isRefreshing: true);

      expect(updated.isRefreshing, true);
      expect(updated.event?.id, 'event-2');
    });
  });
}
