import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/features/reviews/data/models/review.dart';
import 'package:mobile/services/logger_service.dart';

@lazySingleton
class ReviewRemoteDataSource {
  ReviewRemoteDataSource(this._networkClient);
  final NetworkClient _networkClient;

  Future<Review> createReview(
    String targetId,
    String targetType,
    int rating,
    String comment,
  ) async {
    try {
      final response = await _networkClient.dio.post(
        ApiEndpoints.reviews,
        data: {
          'targetId': targetId,
          'targetType': targetType,
          'rating': rating,
          'comment': comment,
        },
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              json
                  as Map<
                    String,
                    dynamic
                  >, // ReviewDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Değerlendirme oluşturulamadı',
          );
        }

        return Review.fromJson(apiResponse.data!);
      }
      // Eski format (direkt ReviewDto)
      return Review.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error creating review', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Review>> getProductReviews(String productId) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.reviewsProduct}/$productId',
        options: Options(
          validateStatus: (status) {
            return status != null &&
                (status >= 200 && status < 300 || status == 404);
          },
        ),
      );

      if (response.statusCode == 404) {
        return [];
      }

      List<dynamic>? data;

      if (response.data is List) {
        data = response.data as List;
      } else if (response.data is Map<String, dynamic>) {
        // Handle ApiResponse wrapped or Summary object wrapped
        final map = response.data as Map<String, dynamic>;
        if (map.containsKey('success') &&
            map['success'] == true &&
            map.containsKey('data')) {
          final innerData = map['data'];
          if (innerData is List) {
            data = innerData;
          } else if (innerData is Map<String, dynamic> &&
              innerData.containsKey('reviews')) {
            data = innerData['reviews'] as List?;
          }
        } else if (map.containsKey('reviews') && map['reviews'] is List) {
          data = map['reviews'] as List;
        }
      }

      if (data != null) {
        return data.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching product reviews', e, stackTrace);
      return [];
    }
  }

  Future<List<Review>> getVendorReviews(String vendorId) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.reviewsVendor}/$vendorId',
      );
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Review.fromJson(json))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor reviews', e, stackTrace);
      return [];
    }
  }

  Future<List<Review>> getPendingReviews() async {
    try {
      final response = await _networkClient.dio.get(
        ApiEndpoints.reviewsPending,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Review.fromJson(json))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching pending reviews', e, stackTrace);
      return [];
    }
  }

  Future<void> approveReview(String reviewId) async {
    try {
      await _networkClient.dio.put(
        '${ApiEndpoints.reviews}/$reviewId/approve',
      ); // Corrected to use ID
    } catch (e, stackTrace) {
      LoggerService().error('Error approving review', e, stackTrace);
      rethrow;
    }
  }

  Future<void> rejectReview(String reviewId) async {
    try {
      await _networkClient.dio.put(
        '${ApiEndpoints.reviews}/$reviewId/reject',
      ); // Corrected to use ID
    } catch (e, stackTrace) {
      LoggerService().error('Error rejecting review', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Review>> getUserReviews() async {
    try {
      final response = await _networkClient.dio.get(ApiEndpoints.reviewsMy);
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              (json as List).map((e) => e as Map<String, dynamic>).toList(),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Değerlendirmeler getirilemedi',
          );
        }

        return apiResponse.data!.map((json) => Review.fromJson(json)).toList();
      }

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Review.fromJson(json))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching user reviews', e, stackTrace);
      return [];
    }
  }

  Future<Review> getReview(String reviewId) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.reviews}/$reviewId',
      );
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Değerlendirme detayları alınamadı',
          );
        }

        return Review.fromJson(apiResponse.data!);
      }
      return Review.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching review detail', e, stackTrace);
      rethrow;
    }
  }
}
