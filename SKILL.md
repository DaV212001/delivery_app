---
name: flutter-dio-networking
description: Build and maintain a reusable Flutter networking layer with Dio, singleton clients, authentication interceptors, token refresh, request wrappers, retries, loading states, error mapping, and testability. Use when creating a new Flutter project or adding API communication, auth refresh, request status handling, loading widgets, or network error handling.
---

# Flutter Dio networking skill

Use this skill when creating or standardizing the networking layer of a Flutter application. Build the layer around a single configured Dio client, a small request service, reactive request states, and a consistent error model.

## Required architecture

Create these responsibilities:

| Responsibility | Recommended file |
| --- | --- |
| API base URL and shared constants | `lib/constants/constants.dart` |
| Dio clients, interceptors, timeouts, error conversion | `lib/config/dio_config.dart` |
| Access and refresh token persistence | `lib/config/storage_config.dart` |
| GET/POST wrappers and retry policy | `lib/utils/templates/dio_template.dart` |
| Request state enum | `lib/utils/api_call_status.dart` |
| Error-to-UI mapping | `lib/utils/error_utils.dart` and `lib/utils/error_data.dart` |
| Loading, empty, and error widgets | `lib/utils/templates/loaded_widgets_template.dart` |

Keep screens focused on rendering. Parse response data and update observable models in controllers or repositories.

## Base URL and dependencies

Add Dio and supporting packages:

```yaml
dependencies:
  dio: ^5.9.2
  cookie_jar: ^4.0.9
  get: ^4.7.3
  logger: ^2.7.0
  path_provider: ^2.1.5
  shared_preferences: ^2.5.5
  connectivity_plus: ^7.0.0

dev_dependencies:
  http_mock_adapter: ^0.6.1
  mocktail: ^1.0.3
```

Define the API URL in one place and make it environment-specific before production:

```dart
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://example.com/api',
);
```

Use relative endpoint paths such as `/v1/users`. Do not scatter complete URLs across controllers.

## Dio configuration

Create one lazily initialized client for the main API. Add logging and authentication interceptors only outside test mode.

```dart
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../config/storage_config.dart';
import '../constants/constants.dart';
import '../constants/pages.dart';

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

    final directory = await getApplicationDocumentsDirectory();
    cookieJar ??= PersistCookieJar(
      storage: FileStorage('${directory.path}/.cookies/'),
    );

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
        // Enable when cookie-based sessions are required:
        // CookieManager(cookieJar!),
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
      case DioExceptionType.unknown:
        return error.message ?? 'Unknown network error';
    }
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Logger().i({
      'url': options.uri.toString(),
      'method': options.method,
      'headers': options.headers,
      'queryParameters': options.queryParameters,
      'body': options.data,
    });
    handler.next(options);
  }
}
```

Do not log passwords, access tokens, refresh tokens, payment data, or other sensitive fields in production. Redact them in `LoggingInterceptor` if request logging remains enabled.

## Authentication interceptor

Attach the bearer token to all non-auth requests. Refresh proactively when the stored access token is expired and reactively after a `401` response.

```dart
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

  bool _isAuthPath(String path) => path.contains('/auth/');

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
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode != 401 ||
        _isAuthPath(error.requestOptions.path)) {
      handler.next(error);
      return;
    }

    final token = await _refreshAccessToken();
    if (token == null) {
      await _redirectToLogin();
      handler.reject(_expired(error.requestOptions, response: error.response));
      return;
    }

    final request = error.requestOptions;
    request.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await (await DioConfig.dio()).fetch(request);
      handler.resolve(response);
    } on DioException {
      handler.next(error);
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
      // Use a dedicated client so refresh does not recurse through this
      // interceptor.
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
      if (response.statusCode! >= 200 &&
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
```

Keep `/auth/` endpoints outside refresh logic to prevent infinite interceptor recursion. Share one refresh future so concurrent `401` responses do not create a refresh storm.

## Token storage contract

Persist the access token, refresh token, expiry timestamp, and optionally the signed-in user. Keep storage access behind a small class.

```dart
class ConfigPreference {
  static late SharedPreferences sharedPreferencesInstance;

  static Future<void> init() async {
    sharedPreferencesInstance = await SharedPreferences.getInstance();
  }

  static String? getAccessToken() =>
      sharedPreferencesInstance.getString('access_token');

  static String? getRefreshToken() =>
      sharedPreferencesInstance.getString('refresh_token');

  static bool isAccessTokenExpired() {
    final expiry = sharedPreferencesInstance.getInt('access_token_expiry');
    return expiry == null || DateTime.now().millisecondsSinceEpoch > expiry;
  }

  static Future<void> updateTokens(
    String accessToken,
    String refreshToken,
    int expiresIn,
  ) async {
    final expiry = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch;
    await sharedPreferencesInstance.setString('access_token', accessToken);
    await sharedPreferencesInstance.setString('refresh_token', refreshToken);
    await sharedPreferencesInstance.setInt('access_token_expiry', expiry);
  }

  static Future<void> clearTokens() async {
    await sharedPreferencesInstance.remove('access_token');
    await sharedPreferencesInstance.remove('refresh_token');
    await sharedPreferencesInstance.remove('access_token_expiry');
  }
}
```

Initialize storage before any controller can make an authenticated request.

## Request service template

Use a wrapper to centralize request execution, status checks, logging, and retry rules. Keep POST retries disabled by default because a repeated write can duplicate a payment or other side effect.

```dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../config/dio_config.dart';

class DioService {
  static const int _maxGetAttempts = 2;
  static const Duration _maxRetryDelay = Duration(seconds: 5);

  static bool _shouldRetry(DioException error) {
    final data = error.response?.data;
    return error.response?.statusCode == 520 ||
        (data is Map && data['retryable'] == true);
  }

  static Duration _retryDelay(DioException error, int attempt) {
    final value = error.response?.data is Map
        ? error.response?.data['retry_after']
        : null;
    final seconds = value is num ? value.toInt() : attempt * 2;
    final delay = Duration(seconds: seconds);
    return delay > _maxRetryDelay ? _maxRetryDelay : delay;
  }

  static Future<Response> _getWithRetry({
    required String path,
    Options? options,
    Object? data,
    Map<String, String>? queryParameters,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await (await DioConfig.dio()).get(
          path,
          options: options,
          data: data,
          queryParameters: queryParameters,
        );
      } on DioException catch (error) {
        attempt++;
        if (attempt >= _maxGetAttempts || !_shouldRetry(error)) rethrow;
        final delay = _retryDelay(error, attempt);
        Logger().w('Retrying GET $path after ${delay.inSeconds}s');
        await Future.delayed(delay);
      }
    }
  }

  static Future<void> dioGet({
    required String path,
    Options? options,
    Object? data,
    Map<String, String>? queryParameters,
    FutureOr<void> Function(Response response)? onSuccess,
    FutureOr<void> Function(Object error, Response response)? onFailure,
  }) async {
    var response = Response(requestOptions: RequestOptions());
    try {
      response = await _getWithRetry(
        path: path,
        options: options,
        data: data,
        queryParameters: queryParameters,
      );
      if (response.statusCode == 200) {
        await onSuccess?.call(response);
      } else {
        await onFailure?.call(response.statusCode!, response);
      }
    } catch (error, stack) {
      Logger().e('GET $path failed', error: error, stackTrace: stack);
      await onFailure?.call(error, response);
    }
  }

  static Future<void> dioPost({
    required String path,
    Options? options,
    Object? data,
    FutureOr<void> Function(Response response)? onSuccess,
    FutureOr<void> Function(Object error, Response response)? onFailure,
  }) async {
    var response = Response(requestOptions: RequestOptions());
    try {
      response = await (await DioConfig.dio()).post(
        path,
        options: options,
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await onSuccess?.call(response);
      } else {
        await onFailure?.call(response.statusCode!, response);
      }
    } catch (error, stack) {
      Logger().e('POST $path failed', error: error, stackTrace: stack);
      await onFailure?.call(error, response);
    }
  }
}
```

The `FutureOr<void>` callback types are intentional: controllers often need to await token persistence, navigation preparation, or error translation before the request operation is considered complete.

## Calling the service

Use relative paths, typed model conversion, and explicit state transitions.

```dart
Future<void> fetchItems() async {
  if (status.value == ApiCallStatus.loading) return;

  isLoading.value = true;
  status.value = ApiCallStatus.loading;
  error.value = null;

  await DioService.dioGet(
    path: '/v1/items',
    queryParameters: {'page': '1', 'limit': '20'},
    options: Options(headers: {
      'Accept': 'application/json',
      'Accept-Language': Get.locale?.languageCode ?? 'en',
    }),
    onSuccess: (response) {
      final rawItems = response.data['data']['items'] ?? [];
      items.value = rawItems.map((json) => Item.fromJson(json)).toList();
      isLoading.value = false;
      status.value = items.isEmpty
          ? ApiCallStatus.empty
          : ApiCallStatus.success;
    },
    onFailure: (networkError, response) async {
      isLoading.value = false;
      status.value = ApiCallStatus.error;
      error.value = await ErrorUtil.getErrorData(networkError.toString());
      showNetworkError(networkError, response);
    },
  );
}
```

For paginated lists, maintain separate `isLoading` and `isLoadingMore` flags. Keep existing items visible while requesting later pages. Guard both flags to prevent duplicate requests.

For non-idempotent operations such as payments, generate and reuse an idempotency key during retries:

```dart
final key = const Uuid().v4();

await DioService.dioPost(
  path: '/v1/payments',
  options: Options(headers: {'Idempotency-Key': key}),
  data: {'amount': amount},
  onSuccess: (_) => paymentStatus.value = ApiCallStatus.success,
  onFailure: (error, response) async {
    paymentStatus.value = ApiCallStatus.error;
    paymentError.value = await ErrorUtil.getErrorData(error.toString());
  },
);
```

## Request statuses

Define the shared status enum:

```dart
enum ApiCallStatus {
  loading,
  success,
  error,
  empty,
  holding,
  cache,
  refresh,
}
```

Use one status per independently rendered request, not one global status for the entire application. For example, a wallet screen can have separate balance, transaction, and top-up statuses.

Use the following transitions:

```text
holding -> loading -> success
holding -> loading -> empty
holding -> loading -> error
success -> loading -> success/error/empty   (refresh)
cache   -> loading -> success/error
```

Always clear loading flags and set an explicit final status in both success and failure callbacks.

## Loading, empty, and error widgets

Create reusable widgets with this rendering contract:

```text
loading -> loading widget
error   -> custom error widget or ErrorCard
empty   -> empty widget
success -> content widget
```

```dart
class LoadedWidget extends StatelessWidget {
  final ApiCallStatus status;
  final ErrorData? errorData;
  final Widget child;
  final Widget loadingChild;
  final Widget? errorChild;
  final VoidCallback? onReload;

  const LoadedWidget({
    super.key,
    required this.status,
    required this.child,
    required this.loadingChild,
    this.errorData,
    this.errorChild,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ApiCallStatus.loading) return loadingChild;
    if (status == ApiCallStatus.error) {
      return errorChild ?? ErrorCard(errorData: errorData!, refresh: onReload);
    }
    return child;
  }
}
```

For lists, render `empty` separately and add pull-to-refresh. Keep cached content visible during refresh when possible instead of replacing it with a full-screen spinner.

## Error model and mapping

Use a UI-safe error object:

```dart
class ErrorData {
  final String title;
  final String body;
  final String image;
  final String? buttonText;

  const ErrorData({
    required this.title,
    required this.body,
    required this.image,
    this.buttonText,
  });
}
```

Map connectivity failures, Dio exception types, HTTP statuses, and backend messages to `ErrorData`. Check connectivity before displaying a generic server error.

```dart
Future<ErrorData> getErrorData(Object error) async {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const ErrorData(
          title: 'No internet connection',
          body: 'Check your connection and try again.',
          image: 'assets/images/errors/no_connection.svg',
          buttonText: 'Retry',
        );
      default:
        break;
    }

    final status = error.response?.statusCode;
    switch (status) {
      case 401:
        return const ErrorData(
          title: 'Unauthorized',
          body: 'Please log in again.',
          image: 'assets/images/errors/unauthorized.svg',
          buttonText: 'Retry',
        );
      case 404:
        return const ErrorData(
          title: 'Not found',
          body: 'The requested resource was not found.',
          image: 'assets/images/errors/not_found.svg',
          buttonText: 'Refresh',
        );
      case 429:
        return const ErrorData(
          title: 'Too many requests',
          body: 'Wait a moment and try again.',
          image: 'assets/images/errors/unknown.svg',
          buttonText: 'Retry',
        );
      case 500:
      case 503:
      case 504:
        return const ErrorData(
          title: 'Service unavailable',
          body: 'The service is temporarily unavailable.',
          image: 'assets/images/errors/service_unavailable.svg',
          buttonText: 'Refresh',
        );
    }
  }

  return const ErrorData(
    title: 'Unknown error',
    body: 'Something unexpected happened.',
    image: 'assets/images/errors/unknown.svg',
    buttonText: 'Refresh',
  );
}
```

Prefer a backend `message` or `messages` field when it is safe and useful. Never show raw stack traces, credentials, or complete response bodies to users.

## Testing

Use `http_mock_adapter` or a mock Dio client. Enable test mode and reset the singleton between tests:

```dart
setUp(() {
  DioConfig.isTestMode = true;
  DioConfig.resetDio();
});

tearDown(() {
  DioConfig.resetDio();
  DioConfig.isTestMode = false;
});
```

Test at least:

- successful 200 GET and 200/201 POST responses
- empty lists
- HTTP errors and backend messages
- connection and timeout errors
- 520/retryable GET behavior
- expired-token refresh and refresh failure
- concurrent `401` responses sharing one refresh
- duplicate-load guards
- loading flags reset on success and failure
- idempotency-key reuse for failed writes
- session-expired errors not producing duplicate snackbars

## Implementation checklist

When adding networking to a project:

- [ ] Put the base URL in one configuration location.
- [ ] Create one lazy Dio singleton.
- [ ] Set connection and receive timeouts.
- [ ] Add auth and logging interceptors outside test mode.
- [ ] Redact sensitive fields from logs.
- [ ] Bypass auth refresh for auth endpoints.
- [ ] Serialize concurrent token refreshes.
- [ ] Clear tokens and redirect after refresh failure.
- [ ] Centralize GET/POST execution in a request service.
- [ ] Retry only safe/read operations and only known retryable failures.
- [ ] Use idempotency keys for retryable writes such as payments.
- [ ] Track loading, success, empty, and error state per request.
- [ ] Store structured `ErrorData` for reusable UI errors.
- [ ] Reset all loading flags in both callbacks.
- [ ] Add singleton/interceptor reset support for tests.
