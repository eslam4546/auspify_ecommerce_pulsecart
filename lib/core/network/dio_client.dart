import 'package:dio/dio.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/exceptions.dart';

/// Configured HTTP client wrapper around [Dio] for catalog REST API requests.
class DioClient {
  final Dio _dio;

  DioClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConstants.fakeStoreBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {
                'Accept': 'application/json, text/plain, */*',
                'Content-Type': 'application/json',
                'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
              },
            ),
          );

  /// Performs a GET request to [path] (relative or full URL) and translates
  /// [DioException] into typed exceptions.
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ServerException(
        message: 'Unexpected error communicating with store server: $e',
      );
    }
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please check your network.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message:
              'Unable to connect to the store server. Check your internet.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return ServerException(
          statusCode: statusCode,
          message: 'Store server returned an error (HTTP $statusCode).',
        );
      case DioExceptionType.cancel:
        return const ServerException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const NetworkException(
          message: 'Network error while fetching store catalog.',
        );
    }
  }
}
