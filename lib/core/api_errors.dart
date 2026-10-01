import 'package:dio/dio.dart';

/// The backend's user-facing `message` for a failed request (it's already Turkish and specific,
/// e.g. "Özet video için en az 3 fotoğraf gerekli."), a connection message when the server couldn't
/// be reached at all, or [fallback] otherwise.
String apiErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (error.response == null) {
      return switch (error.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene.',
        _ => fallback,
      };
    }
  }
  return fallback;
}
