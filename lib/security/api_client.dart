import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mentorly/common/api_config.dart';
import 'package:mentorly/security/secure_storage.dart';
import 'package:mentorly/security/certificate_pinning.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Secure API client with certificate pinning, rate limiting, and auth handling
class SecureApiClient {
  static SecureApiClient? _instance;
  late Dio _dio;

  // Rate limiting
  final Map<String, DateTime> _requestTimestamps = {};
  static const int _maxRequestsPerMinute = 30;

  SecureApiClient._() {
    _initializeDio();
  }

  factory SecureApiClient() {
    _instance ??= SecureApiClient._();
    return _instance!;
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Accept all status codes to handle them manually
          return status != null && status < 500;
        },
      ),
    );

    // Add certificate pinning in production
    if (kReleaseMode) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = CertificatePinning.verifyCertificate;
          return client;
        },
      );
    }

    // Add request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Rate limiting check
          if (!_checkRateLimit(options.path)) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Rate limit exceeded. Please try again later.',
                type: DioExceptionType.cancel,
              ),
            );
          }

          // Add auth token
          final token = await SecureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add device info headers
          await _addDeviceHeaders(options);

          // Add security headers
          options.headers['X-Requested-With'] = 'XMLHttpRequest';
          options.headers['X-Client-Type'] = 'mobile-app';

          debugPrint('🔵 ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
              '✅ ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint(
              '❌ ${error.response?.statusCode} ${error.requestOptions.path}');

          // Handle 401 Unauthorized - token expired
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry request
              try {
                final options = error.requestOptions;
                final token = await SecureStorage.getAccessToken();
                options.headers['Authorization'] = 'Bearer $token';

                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    if (!kReleaseMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ));
    }
  }

  /// Check rate limiting
  bool _checkRateLimit(String endpoint) {
    final now = DateTime.now();
    final key = endpoint;

    // Clean up old timestamps
    _requestTimestamps
        .removeWhere((_, time) => now.difference(time).inMinutes > 1);

    // Count requests in last minute
    final recentRequests = _requestTimestamps.values
        .where((time) => now.difference(time).inMinutes < 1)
        .length;

    if (recentRequests >= _maxRequestsPerMinute) {
      debugPrint('⚠️ Rate limit exceeded for $endpoint');
      return false;
    }

    _requestTimestamps[key] = now;
    return true;
  }

  /// Add device information headers for security tracking
  Future<void> _addDeviceHeaders(RequestOptions options) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      options.headers['X-App-Version'] = packageInfo.version;
      options.headers['X-App-Build'] = packageInfo.buildNumber;

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        options.headers['X-Device-OS'] = 'Android ${info.version.release}';
        options.headers['X-Device-Model'] =
            '${info.manufacturer} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        options.headers['X-Device-OS'] = 'iOS ${info.systemVersion}';
        options.headers['X-Device-Model'] = info.model;
      }
    } catch (e) {
      debugPrint('⚠️ Could not add device headers: $e');
    }
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('⚠️ No refresh token available');
        await _handleLogout();
        return false;
      }

      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await SecureStorage.saveAuthTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'],
        );
        debugPrint('✅ Token refreshed successfully');
        return true;
      }

      await _handleLogout();
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      await _handleLogout();
      return false;
    }
  }

  /// Handle logout on auth failure
  Future<void> _handleLogout() async {
    await SecureStorage.clearSession();
    // You can add navigation to login here if you have NavigationService
    debugPrint('🔴 User logged out due to auth failure');
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle API errors
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: 408,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        String message = 'An error occurred';

        try {
          final data = error.response?.data;
          if (data is Map && data.containsKey('message')) {
            message = data['message'];
          } else if (data is Map && data.containsKey('error')) {
            message = data['error'];
          }
        } catch (_) {}

        return ApiException(
          message: message,
          statusCode: statusCode,
          data: error.response?.data,
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          statusCode: 0,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return ApiException(
            message: 'No internet connection',
            statusCode: 0,
          );
        }
        return ApiException(
          message: error.message ?? 'Unknown error occurred',
          statusCode: 0,
        );

      default:
        return ApiException(
          message: 'An unexpected error occurred',
          statusCode: 0,
        );
    }
  }

  /// Get Dio instance for custom requests
  Dio get dio => _dio;
}

/// API Exception class
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    required this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isValidationError => statusCode == 422;
}
