import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';
import 'jwt_interceptor.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiEndpoints.addListener((newUrl) {
    dio.options.baseUrl = newUrl;
  });

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.baseUrl = ApiEndpoints.baseUrl;
        return handler.next(options);
      },
    ),
  );

  dio.interceptors.add(
    JwtInterceptor(dio: dio, tokenStorage: tokenStorage),
  );

  return dio;
});
