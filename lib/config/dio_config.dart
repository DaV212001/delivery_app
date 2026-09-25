import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/constants.dart';
import '../constants/pages.dart';
import 'storage_config.dart';

class DioConfig {
  static bool isTestMode = false;
  static PersistCookieJar? cookieJar;
  static Dio? _dioInstance;

  static void resetDio() {
    _dioInstance = null;
    cookieJar = null;
  }

  static Future<Dio> dio() async {
    if (_dioInstance != null) return _dioInstance!;

    try {
      final directory = await getApplicationDocumentsDirectory();
      cookieJar ??= PersistCookieJar(
        storage: FileStorage('${directory.path}/.cookies/'),
      );
    } catch (_) {
      // Fallback in environments where path_provider is unavailable
    }

    final client = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Accept': 'application/json'},
      ),
    );

    if (!isTestMode) {
      client.interceptors.addAll([
        LoggingInterceptor(),
        AuthInterceptor(),
      ]);
    }

    _dioInstance = client;
    return client;
  }

  static bool isSessionExpiredError(Object error) {
    return error is DioException &&
        error.message == 'Session expired. Please log in again.';
  }

  static String convertDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        return 'HTTP error ${error.response?.statusCode}: '
            '${error.response?.statusMessage}';
      case DioExceptionType.badCertificate:
        return 'Bad certificate';
      case DioExceptionType.connectionError:
        return 'Connection error, check your internet';
      default:
        return error.message ?? 'Unknown network error';
    }
  }
}

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i({
      'type': 'REQUEST 🚀',
      'method': options.method,
      'url': options.uri.toString(),
      'headers': options.headers,
      'queryParameters': options.queryParameters,
      'body': options.data,
    });
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i({
      'type': 'RESPONSE 📥',
      'statusCode': response.statusCode,
      'url': response.requestOptions.uri.toString(),
      'data': response.data,
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      {
        'type': 'ERROR ❌',
        'url': err.requestOptions.uri.toString(),
        'statusCode': err.response?.statusCode,
        'message': err.message,
        'response': err.response?.data,
      },
      error: err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}

class AuthInterceptor extends Interceptor {
  static Future<String?>? _refreshFuture;

  DioException _expired(RequestOptions request, {Response? response}) {
    return DioException(
      requestOptions: request,
      response: response,
      type: DioExceptionType.unknown,
      message: 'Session expired. Please log in again.',
    );
  }

  bool _isAuthPath(String path) =>
      path.contains('/auth/') ||
      path.contains('login') ||
      path.contains('register') ||
      path.contains('otp') ||
      path.contains('forget-password');

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthPath(options.path)) {
      handler.next(options);
      return;
    }

    if (ConfigPreference.isAccessTokenExpired()) {
      final token = await _refreshAccessToken();
      if (token == null) {
        await _redirectToLogin();
        handler.reject(_expired(options));
        return;
      }
    }

    final token = ConfigPreference.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 ||
        _isAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final token = await _refreshAccessToken();
    if (token == null) {
      await _redirectToLogin();
      handler.reject(_expired(err.requestOptions, response: err.response));
      return;
    }

    final request = err.requestOptions;
    request.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await (await DioConfig.dio()).fetch(request);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshFuture != null) return _refreshFuture;
    _refreshFuture = _performTokenRefresh();
    try {
      return await _refreshFuture;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _performTokenRefresh() async {
    final refreshToken = ConfigPreference.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final client = Dio(BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
      ));
      final response = await client.post(
        '/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data['data'];
      final accessToken = data?['accessToken'];
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          accessToken is String) {
        await ConfigPreference.updateTokens(
          accessToken,
          data['refreshToken'] ?? refreshToken,
          data['expiresIn'] ?? 3600,
        );
        return accessToken;
      }
    } catch (error, stack) {
      Logger().e('Token refresh failed', error: error, stackTrace: stack);
    }
    return null;
  }

  Future<void> _redirectToLogin() async {
    await ConfigPreference.clearTokens();
    Get.offAllNamed(AppRoutes.loginRoute);
  }
}
