import 'package:dio/dio.dart';

import 'token_store.dart';

const String _defaultBaseUrl = 'http://10.0.2.2:5080/api/v1';

class ApiClient {
  /// [bearerToken], when given, is sent on every request instead of the host's stored apiKey —
  /// used to act as a guest (e.g. a circle joined via Discover) without touching the host's own session.
  ApiClient({TokenStore? tokenStore, String? baseUrl, String? bearerToken})
      : _tokenStore = tokenStore ?? const TokenStore(),
        _bearerToken = bearerToken,
        dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: _attachAuth));
  }

  final Dio dio;
  final TokenStore _tokenStore;
  final String? _bearerToken;

  Future<void> _attachAuth(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = _bearerToken ?? await _tokenStore.readApiKey();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
