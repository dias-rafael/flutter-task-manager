import 'network_types.dart';

abstract class Network {
  Future<NetworkResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });

  Future<NetworkResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, String>? headers,
  });

  // Add post, delete, etc. as needed
}
