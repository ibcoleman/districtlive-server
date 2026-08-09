import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:district_live/core/network/api_client.dart';
import 'package:district_live/features/featured/domain/featured_event.dart';

part 'featured_api.g.dart';

class FeaturedApi {
  final Dio dio;

  FeaturedApi(this.dio);

  /// Get the currently featured event
  /// Returns null if no featured event is active (404 response)
  Future<FeaturedEvent?> getCurrentFeatured() async {
    try {
      final response = await dio.get('/featured/current');
      final data = response.data as Map<String, dynamic>;
      return FeaturedEvent.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}

@riverpod
FeaturedApi featuredApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return FeaturedApi(dio);
}
