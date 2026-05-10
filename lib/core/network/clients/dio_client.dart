import 'package:dio/dio.dart';

import '../network.dart';
import '../network_types.dart';

const String baseUrl = 'http://localhost:3001';

class DioClient implements Network {
  DioClient(this._dio);

  final Dio _dio;

  @override
  Future<Response<T>> get<T>(
    String path, {
    String? customBaseUrl,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    try {
      final url = customBaseUrl != null ? customBaseUrl + path : baseUrl + path;
      return _dio.get<T>(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw NetworkException(
        message: e.message ?? 'Unknown Error',
        statusCode: e.response?.statusCode,
        error: e.error,
      );
    }
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    String? customBaseUrl,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    try {
      final url = customBaseUrl != null ? customBaseUrl + path : baseUrl + path;
      return _dio.patch<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw NetworkException(
        message: e.message ?? 'Unknown Error',
        statusCode: e.response?.statusCode,
        error: e.error,
      );
    }
  }
}
