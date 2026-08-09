import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:district_live/core/network/page_response.dart';
import 'package:district_live/core/network/api_client.dart';
import 'package:district_live/features/venues/domain/venue.dart';

part 'venues_api.g.dart';

class VenuesApi {
  final Dio dio;

  VenuesApi(this.dio);

  /// Get paginated list of venues with optional neighborhood filter
  Future<PageResponse<Venue>> getVenues({
    int page = 0,
    int size = 20,
    String? neighborhood,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    if (neighborhood != null) {
      queryParams['neighborhood'] = neighborhood;
    }

    final response = await dio.get(
      '/venues',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    return PageResponse<Venue>.fromJson(
      data,
      (json) => Venue.fromJson(json as Map<String, dynamic>),
    );
  }
}

@riverpod
VenuesApi venuesApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return VenuesApi(dio);
}
