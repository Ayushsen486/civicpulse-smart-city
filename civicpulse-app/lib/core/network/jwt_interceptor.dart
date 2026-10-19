import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';

class JwtInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;

  JwtInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token for auth endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;

    // Trigger token refresh on 401 Unauthorized
    if (response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/login') &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await _tokenStorage.getRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            await _tokenStorage.clearAll();
            return handler.next(err);
          }

          // Use clean Dio instance without interceptors for refresh call
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              headers: {'Content-Type': 'application/json'},
            ),
          );

          final refreshResponse = await refreshDio.post(
            ApiEndpoints.refresh,
            data: {'refreshToken': refreshToken},
          );

          if (refreshResponse.statusCode == 200 &&
              refreshResponse.data?['data'] != null) {
            final data = refreshResponse.data['data'];
            final newAccessToken = data['accessToken'] as String;
            final newRefreshToken = data['refreshToken'] as String;

            await _tokenStorage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            _isRefreshing = false;

            // Retry original request with new access token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await _dio.fetch(options);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          _isRefreshing = false;
          await _tokenStorage.clearAll();
          return handler.next(err);
        }
      }
    }

    return handler.next(err);
  }
}
