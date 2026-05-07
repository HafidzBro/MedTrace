abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({required this.message, this.code, this.originalException});

  @override
  String toString() => message;
}

class AuthenticationException extends AppException {
  AuthenticationException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class AuthorizationException extends AppException {
  AuthorizationException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class ServerException extends AppException {
  ServerException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class DatabaseException extends AppException {
  DatabaseException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class CacheException extends AppException {
  CacheException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class ValidationException extends AppException {
  ValidationException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class InvalidDoctorCodeException extends AppException {
  InvalidDoctorCodeException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class LocationException extends AppException {
  LocationException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class NotFoundException extends AppException {
  NotFoundException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}

class UnknownException extends AppException {
  UnknownException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
        );
}
