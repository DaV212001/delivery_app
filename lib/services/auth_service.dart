import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../utils/templates/dio_template.dart';

class AuthService {
  /// Login with phone and password
  static Future<void> customerLogin({
    required String phone,
    required String password,
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.customerLogin,
      data: {
        'phone': phone,
        'password': password,
      },
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic>) {
          if (resData['success'] == false) {
            onFailure(resData['message']?.toString() ?? 'Login failed');
            return;
          }
          final userMap = resData['data'] is Map<String, dynamic>
              ? resData['data'] as Map<String, dynamic>
              : resData;
          onSuccess(userMap);
        } else {
          onFailure('Invalid server response');
        }
      },
      onFailure: (error, response) {
        String msg = 'Login failed';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        }
        onFailure(msg);
      },
    );
  }

  /// Register customer
  static Future<void> customerRegister({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.customerRegister,
      data: {
        'f_name': firstName,
        'l_name': lastName,
        'phone': phone,
        'email': email,
        'password': password,
      },
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic>) {
          if (resData['success'] == false) {
            onFailure(resData['message']?.toString() ?? 'Registration failed');
            return;
          }
          final userMap = resData['data'] is Map<String, dynamic>
              ? resData['data'] as Map<String, dynamic>
              : resData;
          onSuccess(userMap);
        } else {
          onFailure('Invalid server response');
        }
      },
      onFailure: (error, response) {
        String msg = 'Registration failed';
        if (response.data is Map<String, dynamic>) {
          final errMap = response.data['errors'];
          if (errMap is Map && errMap.isNotEmpty) {
            final firstErrorList = errMap.values.first;
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              msg = firstErrorList.first.toString();
            }
          } else {
            msg = response.data['message']?.toString() ?? msg;
          }
        }
        onFailure(msg);
      },
    );
  }

  /// Send OTP
  static Future<void> sendOtp({
    required String phone,
    required String otp,
    required Function() onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.customerSendOtp,
      data: {'phone': phone, 'otp': otp},
      onSuccess: (_) => onSuccess(),
      onFailure: (error, response) {
        final msg = response.data is Map
            ? response.data['message']?.toString() ?? 'Failed to send OTP'
            : 'Failed to send OTP';
        onFailure(msg);
      },
    );
  }

  /// Verify OTP
  static Future<void> verifyOtp({
    required dynamic userId,
    required String otp,
    required Function() onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.customerVerifyOtp,
      data: {'user_id': userId.toString(), 'otp': otp},
      onSuccess: (_) => onSuccess(),
      onFailure: (error, response) {
        final msg = response.data is Map
            ? response.data['message']?.toString() ?? 'Invalid OTP code'
            : 'Invalid OTP code';
        onFailure(msg);
      },
    );
  }

  /// Forgot password
  static Future<void> forgotPassword({
    required String phone,
    required String password,
    required String passwordConfirmation,
    required Function() onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.customerForgetPassword,
      data: {
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      onSuccess: (_) => onSuccess(),
      onFailure: (error, response) {
        final msg = response.data is Map
            ? response.data['message']?.toString() ?? 'Failed to reset password'
            : 'Failed to reset password';
        onFailure(msg);
      },
    );
  }

  /// Change password
  static Future<void> changePassword({
    required int userId,
    required String password,
    required String passwordConfirmation,
    required Function() onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.customerChangePassword,
      data: {
        'user_id': userId,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      onSuccess: (_) => onSuccess(),
      onFailure: (error, response) {
        final msg = response.data is Map
            ? response.data['message']?.toString() ?? 'Failed to change password'
            : 'Failed to change password';
        onFailure(msg);
      },
    );
  }

  /// Customer Logout
  static Future<void> customerLogout({
    required int userId,
    required Function() onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.customerLogout,
      data: {'user_id': userId},
      onSuccess: (_) => onSuccess(),
      onFailure: (error, response) => onSuccess(), // Still succeed locally on error
    );
  }

  /// Upload profile image
  static Future<void> uploadProfileImage({
    required int userId,
    required String filePath,
    required Function(String newImageUrl) onSuccess,
    required Function(String error) onFailure,
  }) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'user_id': userId.toString(),
      'image': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    void parseResponse(dynamic response) {
      String newUrl = '';
      if (response.data is Map) {
        final map = response.data as Map;
        final data = map['data'];

        String? extractUrl(dynamic source) {
          if (source is! Map) return null;
          final candidates = [
            source['profile_picture'],
            source['profile_image'],
            source['image'],
            source['url'],
            source['avatar'],
            source['avatar_url'],
          ];
          for (final c in candidates) {
            final s = c?.toString().trim();
            if (s != null && s.isNotEmpty && s.toLowerCase() != 'null') {
              return s;
            }
          }
          return null;
        }

        if (data is Map) {
          newUrl = extractUrl(data) ?? '';
        } else if (data is String && data.trim().isNotEmpty && data.trim().toLowerCase() != 'null') {
          newUrl = data.trim();
        }

        if (newUrl.isEmpty) {
          newUrl = extractUrl(map) ?? '';
        }
      } else if (response.data is String && response.data.toString().trim().isNotEmpty) {
        newUrl = response.data.toString().trim();
      }
      onSuccess(newUrl);
    }

    await DioService.dioUpload(
      path: ApiEndpoints.customerChangeProfileImage,
      formData: formData,
      onSuccess: parseResponse,
      onFailure: (error, response) async {
        if (response.statusCode == 404) {
          final fallbackFormData = FormData.fromMap({
            'user_id': userId.toString(),
            'image': await MultipartFile.fromFile(filePath, filename: fileName),
          });
          await DioService.dioUpload(
            path: ApiEndpoints.changeProfileImage,
            formData: fallbackFormData,
            onSuccess: parseResponse,
            onFailure: (err2, resp2) {
              final msg = resp2.data is Map
                  ? resp2.data['message']?.toString() ?? 'Failed to upload photo'
                  : 'Failed to upload photo';
              onFailure(msg);
            },
          );
          return;
        }

        final msg = response.data is Map
            ? response.data['message']?.toString() ?? 'Failed to upload photo'
            : 'Failed to upload photo';
        onFailure(msg);
      },
    );
  }
}
