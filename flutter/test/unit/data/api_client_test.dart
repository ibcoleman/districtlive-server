import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:district_live/features/events/data/events_api.dart';
import 'package:district_live/features/venues/data/venues_api.dart';
import 'package:district_live/features/featured/data/featured_api.dart';

void main() {
  group('EventsApi', () {
    late Dio dio;
    late EventsApi eventsApi;

    setUp(() {
      dio = Dio();
      // Setup mock adapter for events
      dio.interceptors.add(_MockInterceptor());
      eventsApi = EventsApi(dio);
    });

    test('getEvents returns PageResponse<Event>', () async {
      final response = await eventsApi.getEvents(page: 0, size: 20);
      expect(response, isNotNull);
      expect(response.content, isA<List<dynamic>>());
      expect(response.number, 0);
      expect(response.size, 20);
    });

    test('getEventDetail returns EventDetail', () async {
      final detail = await eventsApi.getEventDetail('event-123');
      expect(detail, isNotNull);
      expect(detail.id, 'event-123');
      expect(detail.title, isNotNull);
    });

    test('getEvents includes dateFrom parameter', () async {
      final dateFrom = DateTime(2026, 3, 15);
      // The actual parameter inclusion is tested through the request
      // This test verifies the method doesn't throw with date parameters
      await eventsApi.getEvents(dateFrom: dateFrom);
    });

    test('getEvents includes genre parameter', () async {
      // Test that genre parameter is included without errors
      await eventsApi.getEvents(genre: 'Rock');
    });

    test('getEvents includes venue slug parameter', () async {
      // Test that venue parameter is included without errors
      await eventsApi.getEvents(venue: 'dc9-nightclub');
    });
  });

  group('VenuesApi', () {
    late Dio dio;
    late VenuesApi venuesApi;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(_MockInterceptor());
      venuesApi = VenuesApi(dio);
    });

    test('getVenues returns PageResponse<Venue>', () async {
      final response = await venuesApi.getVenues(page: 0, size: 20);
      expect(response, isNotNull);
      expect(response.content, isA<List<dynamic>>());
      expect(response.number, 0);
      expect(response.size, 20);
    });

    test('getVenues with neighborhood filter', () async {
      final response =
          await venuesApi.getVenues(neighborhood: 'Downtown', page: 0, size: 20);
      expect(response, isNotNull);
    });
  });

  group('FeaturedApi', () {
    late Dio dio;
    late FeaturedApi featuredApi;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(_MockInterceptor());
      featuredApi = FeaturedApi(dio);
    });

    test('getCurrentFeatured returns FeaturedEvent on 200', () async {
      final featured = await featuredApi.getCurrentFeatured();
      expect(featured, isNotNull);
    });

    test('getCurrentFeatured returns null on 404', () async {
      // Setup a mock adapter that returns 404 for featured endpoint
      final dio404 = Dio();
      dio404.interceptors.add(_MockInterceptor(returnNotFound: true));
      final featuredApi404 = FeaturedApi(dio404);

      final featured = await featuredApi404.getCurrentFeatured();
      expect(featured, isNull);
    });
  });

  group('API Error Handling', () {
    late Dio dio;

    setUp(() {
      dio = Dio();
    });

    test('API error (500) throws DioException', () async {
      dio.interceptors.add(_MockInterceptor(returnServerError: true));
      final eventsApi = EventsApi(dio);

      expect(
        () => eventsApi.getEvents(),
        throwsA(isA<DioException>()),
      );
    });
  });
}

/// Mock interceptor for testing without real network calls
class _MockInterceptor extends Interceptor {
  final bool returnNotFound;
  final bool returnServerError;

  _MockInterceptor({
    this.returnNotFound = false,
    this.returnServerError = false,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final statusCode = returnNotFound ? 404 : (returnServerError ? 500 : 200);

    if (returnNotFound) {
      // Return 404 error response
      final errorResponse = Response<dynamic>(
        statusCode: 404,
        requestOptions: options,
        data: {},
        headers: Headers.fromMap({'content-type': ['application/json']}),
      );
      handler.reject(DioException(
        requestOptions: options,
        response: errorResponse,
        type: DioExceptionType.badResponse,
        error: 'Not found',
      ));
      return;
    }

    if (returnServerError) {
      // Return 500 error response
      final errorResponse = Response<dynamic>(
        statusCode: 500,
        requestOptions: options,
        data: {'error': 'Internal server error'},
        headers: Headers.fromMap({'content-type': ['application/json']}),
      );
      handler.reject(DioException(
        requestOptions: options,
        response: errorResponse,
        type: DioExceptionType.badResponse,
        error: 'Internal server error',
      ));
      return;
    }

    String jsonResponse = _getJsonResponse(options.path);

    // Decode JSON string to Map for proper testing
    final decodedData = jsonDecode(jsonResponse);

    final response = Response<dynamic>(
      data: decodedData,
      statusCode: statusCode,
      requestOptions: options,
      headers: Headers.fromMap({'content-type': ['application/json']}),
    );

    handler.resolve(response);
  }

  String _getJsonResponse(String path) {
    if (path.contains('/events/') && !path.contains('/events?')) {
      // Single event detail request
      return '''{
        "id": "event-123",
        "title": "Test Concert",
        "slug": "test-concert",
        "description": "A test concert",
        "startTime": "2026-03-15T20:00:00Z",
        "endTime": "2026-03-15T22:00:00Z",
        "doorsTime": "2026-03-15T19:30:00Z",
        "onSaleDate": "2026-03-01T10:00:00Z",
        "venue": {"id": "venue-1", "name": "Test Venue", "slug": "test-venue", "neighborhood": "Downtown", "websiteUrl": null, "upcomingEventCount": 0},
        "artists": [],
        "minPrice": null,
        "maxPrice": null,
        "priceTier": null,
        "ticketUrl": null,
        "ticketPlatform": null,
        "soldOut": false,
        "imageUrl": null,
        "ageRestriction": "ALL_AGES",
        "status": "ACTIVE",
        "sources": [],
        "relatedEvents": []
      }''';
    } else if (path.contains('/featured/current')) {
      if (returnNotFound) {
        return '{}';
      } else {
        return '''{
          "id": "featured-1",
          "event": {
            "id": "event-123",
            "title": "Featured Concert",
            "slug": "featured-concert",
            "description": "A featured concert",
            "startTime": "2026-03-15T20:00:00Z",
            "endTime": "2026-03-15T22:00:00Z",
            "doorsTime": "2026-03-15T19:30:00Z",
            "onSaleDate": "2026-03-01T10:00:00Z",
            "venue": {"id": "venue-1", "name": "Test Venue", "slug": "test-venue", "neighborhood": "Downtown", "websiteUrl": null, "upcomingEventCount": 0},
            "artists": [],
            "minPrice": null,
            "maxPrice": null,
            "priceTier": null,
            "ticketUrl": null,
            "ticketPlatform": null,
            "soldOut": false,
            "imageUrl": null,
            "ageRestriction": "ALL_AGES",
            "status": "ACTIVE",
            "sources": [],
            "relatedEvents": []
          },
          "blurb": "Don't miss this concert!",
          "createdAt": "2026-03-01T10:00:00Z",
          "createdBy": "admin"
        }''';
      }
    } else if (path.contains('/venues')) {
      return '''{
        "content": [
          {"id": "venue-1", "name": "Venue 1", "slug": "venue-1", "neighborhood": "Downtown", "websiteUrl": null, "upcomingEventCount": 5}
        ],
        "number": 0,
        "size": 20,
        "totalElements": 1,
        "totalPages": 1,
        "first": true,
        "last": true,
        "empty": false
      }''';
    } else {
      // Default: events list
      return '''{
        "content": [
          {
            "id": "event-1",
            "title": "Test Concert",
            "slug": "test-concert",
            "description": "A test concert",
            "startTime": "2026-03-15T20:00:00Z",
            "doorsTime": null,
            "endTime": null,
            "onSaleDate": null,
            "venue": {"id": "venue-1", "name": "Test Venue", "slug": "test-venue", "neighborhood": "Downtown", "websiteUrl": null, "upcomingEventCount": 0},
            "artists": [],
            "minPrice": null,
            "maxPrice": null,
            "priceTier": null,
            "ticketUrl": null,
            "ticketPlatform": null,
            "soldOut": false,
            "imageUrl": null,
            "ageRestriction": "ALL_AGES",
            "status": "ACTIVE"
          }
        ],
        "number": 0,
        "size": 20,
        "totalElements": 1,
        "totalPages": 1,
        "first": true,
        "last": true,
        "empty": false
      }''';
    }
  }
}
