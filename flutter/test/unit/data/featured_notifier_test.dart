import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:district_live/core/network/page_response.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/featured/domain/featured_event.dart';
import 'package:district_live/features/featured/data/featured_notifier.dart';
import 'package:district_live/features/featured/data/featured_api.dart';
import 'package:district_live/features/events/data/events_api.dart';
import 'package:district_live/features/featured/domain/featured_ui_state.dart';
import 'package:district_live/features/events/domain/event_detail.dart';

// Mock API implementations
class MockFeaturedApi extends FeaturedApi {
  FeaturedEvent? _result;
  Exception? _error;

  MockFeaturedApi() : super(Dio());

  void setResult(FeaturedEvent? result) => _result = result;
  void setError(Exception error) => _error = error;

  @override
  Future<FeaturedEvent?> getCurrentFeatured() async {
    if (_error != null) throw _error!;
    return _result;
  }
}

class MockEventsApi extends EventsApi {
  final Map<String, PageResponse<Event>> _responses = {};
  Exception? _error;

  MockEventsApi() : super(Dio());

  void setEventsForRange(DateTime dateFrom, PageResponse<Event> response) {
    _responses[dateFrom.toIso8601String()] = response;
  }

  void setError(Exception error) => _error = error;

  @override
  Future<PageResponse<Event>> getEvents({
    int page = 0,
    int size = 20,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? venue,
    String? genre,
    String? neighborhood,
    String? sort,
  }) async {
    if (_error != null) throw _error!;
    if (dateFrom != null) {
      return _responses[dateFrom.toIso8601String()] ??
          PageResponse<Event>(
            content: [],
            number: 0,
            size: size,
            totalElements: 0,
            totalPages: 0,
            first: true,
            last: true,
            empty: true,
          );
    }
    return PageResponse<Event>(
      content: [],
      number: 0,
      size: size,
      totalElements: 0,
      totalPages: 0,
      first: true,
      last: true,
      empty: true,
    );
  }

  @override
  Future<EventDetail> getEventDetail(String id) async {
    throw UnimplementedError();
  }
}

void main() {
  group('FeaturedNotifier', () {
    late MockFeaturedApi mockFeaturedApi;
    late MockEventsApi mockEventsApi;

    setUp(() {
      mockFeaturedApi = MockFeaturedApi();
      mockEventsApi = MockEventsApi();
    });

    test('Returns curated featured event when API provides one', () async {
      // Arrange
      final eventDetail = EventDetail(
        id: 'event-1',
        title: 'Concert',
        slug: 'concert-slug',
        startTime: DateTime.now().add(const Duration(days: 1)),
        venue: null,
        artists: const [],
        description: 'A great concert',
        imageUrl: 'https://example.com/image.jpg',
      );

      final featured = FeaturedEvent(
        id: 'featured-1',
        event: eventDetail,
        blurb: 'Don\'t miss this!',
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      mockFeaturedApi.setResult(featured);

      final container = ProviderContainer(overrides: [
        featuredApiProvider.overrideWithValue(mockFeaturedApi),
        eventsApiProvider.overrideWithValue(mockEventsApi),
      ]);

      // Act
      final state = await container.read(featuredProvider.future);

      // Assert
      expect(state, isA<FeaturedCurated>());
      final curated = state as FeaturedCurated;
      expect(curated.featuredEvent.id, 'featured-1');
      expect(curated.featuredEvent.blurb, 'Don\'t miss this!');
      expect(curated.isRefreshing, false);
    });

    test('Cascades to today\'s events when no curated featured event', () async {
      // Arrange
      mockFeaturedApi.setResult(null);

      final todayEvent = Event(
        id: 'today-event-1',
        title: 'Tonight Show',
        slug: 'tonight-show',
        startTime: DateTime.now().add(const Duration(hours: 4)),
        artists: const [],
        imageUrl: 'https://example.com/tonight.jpg',
        description: 'Great show tonight',
      );

      final todayRange = DateTime.utc(DateTime.now().year, DateTime.now().month,
          DateTime.now().day);
      mockEventsApi.setEventsForRange(
        todayRange,
        PageResponse<Event>(
          content: [todayEvent],
          number: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
          first: true,
          last: true,
          empty: false,
        ),
      );

      final container = ProviderContainer(overrides: [
        featuredApiProvider.overrideWithValue(mockFeaturedApi),
        eventsApiProvider.overrideWithValue(mockEventsApi),
      ]);

      // Act
      final state = await container.read(featuredProvider.future);

      // Assert
      expect(state, isA<FeaturedFallbackHero>());
      final fallback = state as FeaturedFallbackHero;
      expect(fallback.event, isNotNull);
      expect(fallback.event!.id, 'today-event-1');
      expect(fallback.isRefreshing, false);
    });

    test('Cascades to weekend events when no curated and no today events',
        () async {
      // Arrange
      mockFeaturedApi.setResult(null);

      final todayRange = DateTime.utc(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      mockEventsApi.setEventsForRange(
        todayRange,
        PageResponse<Event>(
          content: [],
          number: 0,
          size: 50,
          totalElements: 0,
          totalPages: 0,
          first: true,
          last: true,
          empty: true,
        ),
      );

      final weekendEvent = Event(
        id: 'weekend-event-1',
        title: 'Weekend Concert',
        slug: 'weekend-concert',
        startTime: DateTime.now().add(const Duration(days: 5)),
        artists: const [],
        imageUrl: 'https://example.com/weekend.jpg',
      );

      // Calculate weekend Friday
      final now = DateTime.now();
      final weekday = now.weekday;
      late int daysUntilFriday;
      if (weekday >= 5) {
        daysUntilFriday = 5 - weekday;
      } else {
        daysUntilFriday = 5 - weekday;
      }
      final fridayStart = DateTime.utc(now.year, now.month, now.day)
          .add(Duration(days: daysUntilFriday));

      mockEventsApi.setEventsForRange(
        fridayStart,
        PageResponse<Event>(
          content: [weekendEvent],
          number: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
          first: true,
          last: true,
          empty: false,
        ),
      );

      final container = ProviderContainer(overrides: [
        featuredApiProvider.overrideWithValue(mockFeaturedApi),
        eventsApiProvider.overrideWithValue(mockEventsApi),
      ]);

      // Act
      final state = await container.read(featuredProvider.future);

      // Assert
      expect(state, isA<FeaturedFallbackHero>());
      final fallback = state as FeaturedFallbackHero;
      expect(fallback.event, isNotNull);
      expect(fallback.event!.id, 'weekend-event-1');
    });

    test('Returns fallback with null event when no events anywhere', () async {
      // Arrange
      mockFeaturedApi.setResult(null);

      final todayRange = DateTime.utc(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      mockEventsApi.setEventsForRange(
        todayRange,
        PageResponse<Event>(
          content: [],
          number: 0,
          size: 50,
          totalElements: 0,
          totalPages: 0,
          first: true,
          last: true,
          empty: true,
        ),
      );

      // Calculate weekend Friday
      final now = DateTime.now();
      final weekday = now.weekday;
      late int daysUntilFriday;
      if (weekday >= 5) {
        daysUntilFriday = 5 - weekday;
      } else {
        daysUntilFriday = 5 - weekday;
      }
      final fridayStart = DateTime.utc(now.year, now.month, now.day)
          .add(Duration(days: daysUntilFriday));

      mockEventsApi.setEventsForRange(
        fridayStart,
        PageResponse<Event>(
          content: [],
          number: 0,
          size: 50,
          totalElements: 0,
          totalPages: 0,
          first: true,
          last: true,
          empty: true,
        ),
      );

      final container = ProviderContainer(overrides: [
        featuredApiProvider.overrideWithValue(mockFeaturedApi),
        eventsApiProvider.overrideWithValue(mockEventsApi),
      ]);

      // Act
      final state = await container.read(featuredProvider.future);

      // Assert
      expect(state, isA<FeaturedFallbackHero>());
      final fallback = state as FeaturedFallbackHero;
      expect(fallback.event, isNull);
    });

    test('Handles network errors gracefully', () async {
      // Arrange - Set up so featured API fails but events API returns data
      mockFeaturedApi.setError(Exception('Network error'));

      final todayEvent = Event(
        id: 'today-event-1',
        title: 'Tonight Show',
        slug: 'tonight-show',
        startTime: DateTime.now().add(const Duration(hours: 4)),
        artists: const [],
        imageUrl: 'https://example.com/tonight.jpg',
      );

      final todayRange = DateTime.utc(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      mockEventsApi.setEventsForRange(
        todayRange,
        PageResponse<Event>(
          content: [todayEvent],
          number: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
          first: true,
          last: true,
          empty: false,
        ),
      );

      final container = ProviderContainer(overrides: [
        featuredApiProvider.overrideWithValue(mockFeaturedApi),
        eventsApiProvider.overrideWithValue(mockEventsApi),
      ]);

      // Act - When featured API fails, should fall back to events
      final state = await container.read(featuredProvider.future);

      // Assert - Should cascade to today's events despite featured API error
      expect(state, isA<FeaturedFallbackHero>());
      final fallback = state as FeaturedFallbackHero;
      expect(fallback.event, isNotNull);
      expect(fallback.event!.id, 'today-event-1');
    });

    test('Refresh updates state correctly', () async {
      // Arrange
      mockFeaturedApi.setResult(null);

      final todayEvent = Event(
        id: 'today-event-1',
        title: 'Tonight Show',
        slug: 'tonight-show',
        startTime: DateTime.now().add(const Duration(hours: 4)),
        artists: const [],
        imageUrl: 'https://example.com/tonight.jpg',
      );

      final todayRange = DateTime.utc(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      mockEventsApi.setEventsForRange(
        todayRange,
        PageResponse<Event>(
          content: [todayEvent],
          number: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
          first: true,
          last: true,
          empty: false,
        ),
      );

      final container = ProviderContainer(overrides: [
        featuredApiProvider.overrideWithValue(mockFeaturedApi),
        eventsApiProvider.overrideWithValue(mockEventsApi),
      ]);

      // Act - Initial load
      final initialState =
          await container.read(featuredProvider.future);
      expect(initialState, isA<FeaturedFallbackHero>());

      // Act - Call refresh
      final notifier = container.read(featuredProvider.notifier);
      await notifier.refresh();

      // Get updated state
      FeaturedUiState? updatedState;
      final asyncValue = container.read(featuredProvider);
      asyncValue.whenData((data) {
        updatedState = data;
      });

      // Assert
      expect(updatedState, isA<FeaturedFallbackHero>());
      final fallback = updatedState as FeaturedFallbackHero;
      expect(fallback.event, isNotNull);
      expect(fallback.event!.id, 'today-event-1');
    });
  });
}
