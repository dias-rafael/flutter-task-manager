/// Generic response wrapper to decouple from any specific library
class NetworkResponse<T> {
  NetworkResponse({this.data, this.statusCode, this.statusMessage});
  final T? data;
  final int? statusCode;
  final String? statusMessage;
}

/// Generic exception for network errors
class NetworkException implements Exception {
  NetworkException({required this.message, this.statusCode, this.error});
  final String message;
  final int? statusCode;
  final dynamic error;
}

/// Generic exception for unknown errors
class UnknownException implements Exception {
  UnknownException({required this.message, this.statusCode, this.error});
  final String message;
  final int? statusCode;
  final dynamic error;
}

/// Generic exception for conflict errors
class ConflictException implements Exception {
  ConflictException({required this.message, this.statusCode, this.error});
  final String message;
  final int? statusCode;
  final dynamic error;
}
