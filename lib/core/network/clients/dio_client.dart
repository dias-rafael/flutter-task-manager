import 'package:dio/dio.dart';

import '../network.dart';
import '../network_types.dart';

const String baseUrl = 'http://localhost:3001';

class DioClient implements Network {
  DioClient(this._dio);
  final Dio _dio;

  @override
  Future<NetworkResponse<T>> get<T>(
    String path, {
    String? customBaseUrl,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final url = customBaseUrl != null ? customBaseUrl + path : baseUrl + path;
      final response = await _dio.get<T>(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return NetworkResponse(
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
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
  Future<NetworkResponse<T>> patch<T>(
    String path, {
    String? customBaseUrl,
    dynamic data,
    Map<String, String>? headers,
  }) async {
    try {
      final url = customBaseUrl != null ? customBaseUrl + path : baseUrl + path;
      final response = await _dio.patch<T>(
        url,
        data: data,
        options: Options(headers: headers),
      );
      return NetworkResponse(
        data: response.data,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw NetworkException(
        message: e.message ?? 'Patch Failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
