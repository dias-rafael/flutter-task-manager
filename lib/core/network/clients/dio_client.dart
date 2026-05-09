import 'package:dio/dio.dart';

import '../network.dart';
import '../network_types.dart';

class DioClient implements Network {
  DioClient(this._dio);
  final Dio _dio;

  @override
  Future<NetworkResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
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
    dynamic data,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
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
