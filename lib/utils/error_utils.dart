import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'error_data.dart';

class ErrorUtil {
  static Future<ErrorData> getErrorData(Object error) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return const ErrorData(
          title: 'No internet connection',
          body: 'Please check your connection and try again.',
          buttonText: 'Retry',
        );
      }
    } catch (_) {
      // Platform channel may not be registered in tests or headless runners
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return const ErrorData(
            title: 'Connection error',
            body: 'Unable to connect to the server. Please check your internet.',
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
            buttonText: 'Log In',
          );
        case 404:
          return const ErrorData(
            title: 'Not found',
            body: 'The requested item or store was not found.',
            buttonText: 'Refresh',
          );
        case 429:
          return const ErrorData(
            title: 'Too many requests',
            body: 'Please wait a moment and try again.',
            buttonText: 'Retry',
          );
        case 500:
        case 503:
        case 504:
          return const ErrorData(
            title: 'Service unavailable',
            body: 'The server is temporarily unavailable.',
            buttonText: 'Refresh',
          );
      }
    }

    return ErrorData(
      title: 'Something went wrong',
      body: error.toString().isNotEmpty ? error.toString() : 'An unexpected error occurred.',
      buttonText: 'Retry',
    );
  }
}
