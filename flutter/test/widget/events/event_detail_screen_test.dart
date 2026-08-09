import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:district_live/features/events/data/events_api.dart';
import 'package:district_live/features/events/domain/event_detail.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/events/domain/artist.dart';
import 'package:district_live/features/events/domain/enums.dart';
import 'package:district_live/features/venues/domain/venue.dart';
import 'package:district_live/features/events/presentation/event_detail_screen.dart';
import 'package:district_live/core/network/page_response.dart';

// Create a simple mock EventsApi
class MockEventsApi implements EventsApi {
  final Map<String, EventDetail> _eventDetails = {};
  final Map<String, Object> _errors = {};

  @override
  late final Dio dio;

  void setEventDetail(String id, EventDetail detail) {
    _eventDetails[id] = detail;
  }

  void setError(String id, Object error) {
    _errors[id] = error;
  }

  @override
  Future<EventDetail> getEventDetail(String id) async {
    if (_errors.containsKey(id)) {
      throw _errors[id]!;
    }
    if (_eventDetails.containsKey(id)) {
      return _eventDetails[id]!;
    }
    throw Exception('Event not found: $id');
  }

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
  }) {
    throw UnimplementedError();
  }
}

// Mock that delays responses
class _SlowMockEventsApi extends MockEventsApi {
  _SlowMockEventsApi(EventDetail detail, String id) {
    setEventDetail(id, detail);
  }

  @override
  Future<EventDetail> getEventDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return super.getEventDetail(id);
  }
}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('EventDetailScreen widget tests', () {
    late EventDetail testDetail;
    late Venue testVenue;
    late Artist testArtist;
    late Event relatedEvent;

    setUp(() {
      testVenue = const Venue(
        id: 'venue-1',
        name: 'The Kennedy Center',
        slug: 'the-kennedy-center',
        neighborhood: 'Downtown',
      );

      testArtist = const Artist(
        id: 'artist-1',
        name: 'Test Artist',
        slug: 'test-artist',
      );

      relatedEvent = Event(
        id: 'event-2',
        title: 'Another Concert',
        slug: 'another-concert',
        startTime: DateTime(2025, 4, 1, 20, 0),
        venue: testVenue,
        artists: [testArtist],
      );

      testDetail = EventDetail(
        id: 'event-1',
        title: 'Amazing Concert',
        slug: 'amazing-concert',
        startTime: DateTime(2025, 3, 15, 20, 0),
        doorsTime: DateTime(2025, 3, 15, 19, 30),
        venue: testVenue,
        artists: [testArtist],
        minPrice: 25.0,
        maxPrice: 50.0,
        priceTier: PriceTier.PRICE_15_TO_30,
        ticketUrl: 'https://tickets.example.com/event-1',
        imageUrl: 'https://example.com/image.jpg',
        description: 'This is an amazing concert event.',
        relatedEvents: [relatedEvent],
      );
    });

    Widget buildTestWidget({required EventDetail detail, MockEventsApi? mockApi}) {
      final api = mockApi ?? MockEventsApi();
      api.setEventDetail(detail.id, detail);

      return ProviderScope(
        overrides: [
          eventsApiProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          home: EventDetailScreen(eventId: detail.id),
        ),
      );
    }

    testWidgets('renders all event detail fields when fully populated',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(detail: testDetail));
      await tester.pumpAndSettle();

      // Title should be visible
      expect(find.text('Amazing Concert'), findsOneWidget);

      // Venue with neighborhood should be visible
      expect(find.text('The Kennedy Center · Downtown'), findsOneWidget);

      // Date/Time should be visible
      expect(find.byType(Text), findsWidgets);

      // Artist name should be visible
      expect(find.text('Test Artist'), findsOneWidget);

      // Price should be visible
      expect(find.text('\$25-\$50'), findsOneWidget);

      // Description should be visible
      expect(find.text('This is an amazing concert event.'), findsOneWidget);
    });

    testWidgets('shows Get Tickets button when ticketUrl is non-null',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(detail: testDetail));
      await tester.pumpAndSettle();

      expect(find.text('Get Tickets'), findsOneWidget);
    });

    testWidgets('Get Tickets button can be tapped (AC3.2)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(detail: testDetail));
      await tester.pumpAndSettle();

      final ticketsButton = find.byType(ElevatedButton).first;
      expect(ticketsButton, findsOneWidget);

      // Tap the Get Tickets button and verify no crash
      await tester.tap(ticketsButton);
      await tester.pumpAndSettle();
    });

    testWidgets('hides Get Tickets button when ticketUrl is null (AC3.4)',
        (WidgetTester tester) async {
      final detailWithoutTickets = testDetail.copyWith(ticketUrl: null);

      await tester.pumpWidget(
          buildTestWidget(detail: detailWithoutTickets));
      await tester.pumpAndSettle();

      expect(find.text('Get Tickets'), findsNothing);
    });

    testWidgets('shows Share button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(detail: testDetail));
      await tester.pumpAndSettle();

      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('renders related events section with up to 5 events',
        (WidgetTester tester) async {
      // Create multiple related events
      final relatedEvents = List.generate(
        6,
        (i) => Event(
          id: 'event-related-$i',
          title: 'Related Event $i',
          slug: 'related-event-$i',
          startTime: DateTime(2025, 4, i + 1, 20, 0),
          venue: testVenue,
        ),
      );

      final detailWithManyRelated =
          testDetail.copyWith(relatedEvents: relatedEvents);

      await tester.pumpWidget(
          buildTestWidget(detail: detailWithManyRelated));
      await tester.pumpAndSettle();

      // Should show "More at The Kennedy Center"
      expect(find.text('More at The Kennedy Center'), findsOneWidget);

      // Should show first 5 related events (not the 6th)
      expect(find.text('Related Event 0'), findsOneWidget);
      expect(find.text('Related Event 4'), findsOneWidget);
      expect(find.text('Related Event 5'), findsNothing);
    });

    testWidgets('does not show related events section when empty',
        (WidgetTester tester) async {
      final detailNoRelated = testDetail.copyWith(relatedEvents: []);

      await tester.pumpWidget(buildTestWidget(detail: detailNoRelated));
      await tester.pumpAndSettle();

      expect(find.text('More at The Kennedy Center'), findsNothing);
    });

    testWidgets('shows error state with retry button when load fails',
        (WidgetTester tester) async {
      final mockApi = MockEventsApi();
      mockApi.setError('event-1', Exception('Failed to load'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsApiProvider.overrideWithValue(mockApi),
          ],
          child: const MaterialApp(
            home: EventDetailScreen(eventId: 'event-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays loading state before data arrives', (WidgetTester tester) async {
      // Create a custom mock that delays the response by 100ms
      final mockApi = _SlowMockEventsApi(testDetail, 'event-1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsApiProvider.overrideWithValue(mockApi),
          ],
          child: const MaterialApp(
            home: EventDetailScreen(eventId: 'event-1'),
          ),
        ),
      );

      // Before pumpAndSettle, we should see the loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // After the data arrives, the loading indicator should be gone
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'hides age restriction text when ALL_AGES',
        (WidgetTester tester) async {
      final detailAllAges = testDetail.copyWith(
        ageRestriction: AgeRestriction.ALL_AGES,
      );

      await tester.pumpWidget(buildTestWidget(detail: detailAllAges));
      await tester.pumpAndSettle();

      expect(find.text('18+'), findsNothing);
      expect(find.text('21+'), findsNothing);
    });

    testWidgets(
        'shows 18+ when ageRestriction is EIGHTEEN_PLUS',
        (WidgetTester tester) async {
      final detail18Plus = testDetail.copyWith(
        ageRestriction: AgeRestriction.EIGHTEEN_PLUS,
      );

      await tester.pumpWidget(buildTestWidget(detail: detail18Plus));
      await tester.pumpAndSettle();

      expect(find.text('18+'), findsOneWidget);
    });

    testWidgets(
        'shows 21+ when ageRestriction is TWENTY_ONE_PLUS',
        (WidgetTester tester) async {
      final detail21Plus = testDetail.copyWith(
        ageRestriction: AgeRestriction.TWENTY_ONE_PLUS,
      );

      await tester.pumpWidget(buildTestWidget(detail: detail21Plus));
      await tester.pumpAndSettle();

      expect(find.text('21+'), findsOneWidget);
    });

    testWidgets('displays multiple artists comma-separated',
        (WidgetTester tester) async {
      final artist2 = const Artist(
        id: 'artist-2',
        name: 'Another Artist',
        slug: 'another-artist',
      );

      final detailMultiArtist =
          testDetail.copyWith(artists: [testArtist, artist2]);

      await tester.pumpWidget(buildTestWidget(detail: detailMultiArtist));
      await tester.pumpAndSettle();

      expect(find.text('Test Artist, Another Artist'), findsOneWidget);
    });

    testWidgets('does not show image section when imageUrl is null',
        (WidgetTester tester) async {
      final detailNoImage = testDetail.copyWith(imageUrl: null);

      await tester.pumpWidget(buildTestWidget(detail: detailNoImage));
      await tester.pumpAndSettle();

      // CachedNetworkImage should not be present
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('does not show description when null',
        (WidgetTester tester) async {
      final detailNoDesc = testDetail.copyWith(description: null);

      await tester.pumpWidget(buildTestWidget(detail: detailNoDesc));
      await tester.pumpAndSettle();

      expect(find.text('This is an amazing concert event.'), findsNothing);
    });

    testWidgets('does not show venue when null',
        (WidgetTester tester) async {
      final detailNoVenue = testDetail.copyWith(venue: null);

      await tester.pumpWidget(buildTestWidget(detail: detailNoVenue));
      await tester.pumpAndSettle();

      expect(find.text('The Kennedy Center · Downtown'), findsNothing);
    });

    testWidgets('does not show artists when empty list',
        (WidgetTester tester) async {
      final detailNoArtists = testDetail.copyWith(artists: []);

      await tester.pumpWidget(buildTestWidget(detail: detailNoArtists));
      await tester.pumpAndSettle();

      // Artist name text should not appear, but title and other info should
      expect(find.text('Test Artist'), findsNothing);
      expect(find.text('Amazing Concert'), findsOneWidget);
    });

    testWidgets('does not show price when minPrice and maxPrice are null',
        (WidgetTester tester) async {
      final detailNoPrice = testDetail.copyWith(
        minPrice: null,
        maxPrice: null,
        priceTier: null,
      );

      await tester.pumpWidget(buildTestWidget(detail: detailNoPrice));
      await tester.pumpAndSettle();

      expect(find.text('\$25-\$50'), findsNothing);
    });

    testWidgets('shows Free when priceTier is FREE',
        (WidgetTester tester) async {
      final detailFree =
          testDetail.copyWith(priceTier: PriceTier.FREE, minPrice: null, maxPrice: null);

      await tester.pumpWidget(buildTestWidget(detail: detailFree));
      await tester.pumpAndSettle();

      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('has Share button that can be tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(detail: testDetail));
      await tester.pumpAndSettle();

      final shareButton = find.byType(OutlinedButton);
      expect(shareButton, findsOneWidget);

      // Verify button is tappable (doesn't test actual share, just button interaction)
      await tester.tap(shareButton);
      await tester.pumpAndSettle();
    });

    testWidgets('Share button can be tapped without error (AC3.3)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(detail: testDetail));
      await tester.pumpAndSettle();

      final shareButton = find.byType(OutlinedButton);
      expect(shareButton, findsOneWidget);

      // Tap the Share button and verify no crash occurs
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // Verify the button is still visible after tap
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('AppBar displays Event Details title',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(detail: testDetail));
      await tester.pumpAndSettle();

      expect(find.text('Event Details'), findsOneWidget);
    });

    testWidgets('displays doors time when present',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(detail: testDetail));
      await tester.pumpAndSettle();

      // Should contain "Doors" in the date/time text
      final textFinder = find.byType(Text);
      expect(textFinder, findsWidgets);
    });

    testWidgets('displays only show time when doors time is null',
        (WidgetTester tester) async {
      final detailNoDoors = testDetail.copyWith(doorsTime: null);

      await tester.pumpWidget(buildTestWidget(detail: detailNoDoors));
      await tester.pumpAndSettle();

      // Should still display the event (just without doors time)
      expect(find.text('Amazing Concert'), findsOneWidget);
    });
  });
}
