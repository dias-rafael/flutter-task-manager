import 'network_types.dart';

abstract class Network {
  Future<NetworkResponse<T>> get<T>(
    String path, {
    String customBaseUrl,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });

  Future<NetworkResponse<T>> patch<T>(
    String path, {
    String customBaseUrl,
    dynamic data,
    Map<String, String>? headers,
  });

  // Add post, delete, etc. as needed
}
