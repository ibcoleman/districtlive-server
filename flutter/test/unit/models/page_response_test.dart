import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/core/network/page_response.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/events/domain/enums.dart';

void main() {
  group('PageResponse', () {
    test('PageResponse<Event> round-trip serialization', () {
      // Create a sample event
      final event = Event(
        id: 'event-123',
        title: 'Test Concert',
        slug: 'test-concert',
        startTime: DateTime.parse('2026-03-15T20:00:00Z'),
        venue: null,
        artists: const [],
        status: EventStatus.ACTIVE,
        ageRestriction: AgeRestriction.ALL_AGES,
      );

      // Create a PageResponse with one event
      final pageResponse = PageResponse(
        content: [event],
        number: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        first: true,
        last: true,
        empty: false,
      );

      // Serialize to JSON
      final json = pageResponse.toJson(
        (event) => event.toJson(),
      );

      // Verify JSON structure
      expect(json['content'], isA<List>());
      expect(json['number'], 0);
      expect(json['size'], 20);
      expect(json['totalElements'], 1);
      expect(json['totalPages'], 1);
      expect(json['first'], true);
      expect(json['last'], true);
      expect(json['empty'], false);

      // Deserialize back from JSON
      final pageResponseRoundTrip = PageResponse<Event>.fromJson(
        json,
        (eventJson) => Event.fromJson(eventJson as Map<String, dynamic>),
      );

      // Verify round-trip equality
      expect(pageResponseRoundTrip.number, pageResponse.number);
      expect(pageResponseRoundTrip.size, pageResponse.size);
      expect(pageResponseRoundTrip.totalElements, pageResponse.totalElements);
      expect(pageResponseRoundTrip.totalPages, pageResponse.totalPages);
      expect(pageResponseRoundTrip.first, pageResponse.first);
      expect(pageResponseRoundTrip.last, pageResponse.last);
      expect(pageResponseRoundTrip.empty, pageResponse.empty);
      expect(pageResponseRoundTrip.content.length, 1);
      expect(pageResponseRoundTrip.content[0].id, event.id);
      expect(pageResponseRoundTrip.content[0].title, event.title);
    });

    test('PageResponse with empty content', () {
      final pageResponse = PageResponse(
        content: const [],
        number: 0,
        size: 20,
        totalElements: 0,
        totalPages: 0,
        first: true,
        last: true,
        empty: true,
      );

      final json = pageResponse.toJson(
        (event) => event.toJson(),
      );

      final roundTrip = PageResponse<Event>.fromJson(
        json,
        (eventJson) => Event.fromJson(eventJson as Map<String, dynamic>),
      );

      expect(roundTrip.content, isEmpty);
      expect(roundTrip.empty, true);
      expect(roundTrip.totalElements, 0);
    });

    test('PageResponse with multiple items', () {
      final events = [
        Event(
          id: 'event-1',
          title: 'Concert 1',
          slug: 'concert-1',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          venue: null,
          artists: const [],
          status: EventStatus.ACTIVE,
          ageRestriction: AgeRestriction.ALL_AGES,
        ),
        Event(
          id: 'event-2',
          title: 'Concert 2',
          slug: 'concert-2',
          startTime: DateTime.parse('2026-03-16T20:00:00Z'),
          venue: null,
          artists: const [],
          status: EventStatus.ACTIVE,
          ageRestriction: AgeRestriction.ALL_AGES,
        ),
        Event(
          id: 'event-3',
          title: 'Concert 3',
          slug: 'concert-3',
          startTime: DateTime.parse('2026-03-17T20:00:00Z'),
          venue: null,
          artists: const [],
          status: EventStatus.ACTIVE,
          ageRestriction: AgeRestriction.ALL_AGES,
        ),
      ];

      final pageResponse = PageResponse(
        content: events,
        number: 0,
        size: 20,
        totalElements: 3,
        totalPages: 1,
        first: true,
        last: true,
        empty: false,
      );

      final json = pageResponse.toJson(
        (event) => event.toJson(),
      );

      final roundTrip = PageResponse<Event>.fromJson(
        json,
        (eventJson) => Event.fromJson(eventJson as Map<String, dynamic>),
      );

      expect(roundTrip.content.length, 3);
      expect(roundTrip.content[0].id, 'event-1');
      expect(roundTrip.content[1].id, 'event-2');
      expect(roundTrip.content[2].id, 'event-3');
      expect(roundTrip.totalElements, 3);
    });

    test('PageResponse pagination properties', () {
      final pageResponse = PageResponse(
        content: const [],
        number: 2,
        size: 10,
        totalElements: 100,
        totalPages: 10,
        first: false,
        last: false,
        empty: false,
      );

      final json = pageResponse.toJson(
        (event) => event.toJson(),
      );

      final roundTrip = PageResponse<Event>.fromJson(
        json,
        (eventJson) => Event.fromJson(eventJson as Map<String, dynamic>),
      );

      expect(roundTrip.number, 2);
      expect(roundTrip.size, 10);
      expect(roundTrip.totalElements, 100);
      expect(roundTrip.totalPages, 10);
      expect(roundTrip.first, false);
      expect(roundTrip.last, false);
    });
  });
}
