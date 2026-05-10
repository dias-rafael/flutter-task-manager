import 'package:dio/dio.dart';

abstract class Network {
  Future<Response<T>> get<T>(
    String path, {
    String? customBaseUrl,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  });

  Future<Response<T>> patch<T>(
    String path, {
    String? customBaseUrl,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  });
}
