import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:district_live/core/network/page_response.dart';
import 'package:district_live/core/network/api_client.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/events/domain/event_detail.dart';

part 'events_api.g.dart';

class EventsApi {
  final Dio dio;

  EventsApi(this.dio);

  /// Get paginated list of events with optional filters
  Future<PageResponse<Event>> getEvents({
    int page = 0,
    int size = 20,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? venue,
    String? genre,
    String? sort,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    if (dateFrom != null) {
      queryParams['dateFrom'] = dateFrom.toIso8601String();
    }
    if (dateTo != null) {
      queryParams['dateTo'] = dateTo.toIso8601String();
    }
    if (venue != null) {
      queryParams['venue'] = venue;
    }
    if (genre != null) {
      queryParams['genre'] = genre;
    }
    if (sort != null) {
      queryParams['sort'] = sort;
    }

    final response = await dio.get(
      '/events',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    return PageResponse<Event>.fromJson(
      data,
      (json) => Event.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get a single event with full details
  Future<EventDetail> getEventDetail(String id) async {
    final response = await dio.get('/events/$id');
    final data = response.data as Map<String, dynamic>;
    return EventDetail.fromJson(data);
  }
}

@riverpod
EventsApi eventsApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return EventsApi(dio);
}
