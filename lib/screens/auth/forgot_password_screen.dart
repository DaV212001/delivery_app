import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0; // 0: Phone, 1: OTP, 2: New Password

  late final TextEditingController _phoneController;
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _phoneController = TextEditingController(
      text: args['phone']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _authController.clearResetPasswordState();
    super.dispose();
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      _authController.clearResetPasswordState();
      Get.back();
    }
  }

  void _onDigitEntered(int index, String value) {
    if (value.length > 1) {
      // User pasted multiple characters
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < 4 && i < digits.length; i++) {
        _otpControllers[i].text = digits[i];
      }
      final nextIndex = digits.length < 4 ? digits.length : 3;
      _otpFocusNodes[nextIndex].requestFocus();
    } else if (value.isNotEmpty && index < 3) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 4) {
      _verifyOtp();
    }
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      if (!Get.testMode && Get.context != null && Get.overlayContext != null) {
        Get.snackbar(
          'error'.tr,
          'fill_all_fields'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
      return;
    }

    final ok = await _authController.sendPasswordResetOtp(phone);
    if (ok && mounted) {
      setState(() => _currentStep = 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _otpFocusNodes[0].canRequestFocus) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    }
  }

  Future<void> _resendOtp() async {
    await _authController.resendPasswordResetOtp();
  }

  void _verifyOtp() {
    FocusScope.of(context).unfocus();
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) {
      if (!Get.testMode && Get.context != null && Get.overlayContext != null) {
        Get.snackbar(
          'incomplete'.tr,
          'enter_4_digit_code'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
      return;
    }

    final verified = _authController.verifyPasswordResetOtp(otp);
    if (verified && mounted) {
      setState(() => _currentStep = 2);
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    final phoneUsed = _authController.resetPhone ?? _phoneController.text.trim();
    final ok = await _authController.resetPasswordWithOtp(
      newPassword: newPass,
      confirmPassword: confirmPass,
    );

    if (ok) {
      Get.back(result: phoneUsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
          title: Text(
            'reset_password'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(theme),
                const SizedBox(height: 32),
                if (_currentStep == 0) _buildPhoneStep(theme),
                if (_currentStep == 1) _buildOtpStep(theme),
                if (_currentStep == 2) _buildNewPasswordStep(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    final steps = [
      {'title': 'step_phone'.tr, 'icon': Icons.phone_android_rounded},
      {'title': 'step_otp'.tr, 'icon': Icons.sms_outlined},
      {'title': 'step_new_password'.tr, 'icon': Icons.lock_reset_rounded},
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = _currentStep > index;
        final isActive = _currentStep == index;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : isActive
                                ? AppColors.primary
                                : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : (steps[index]['icon'] as IconData),
                        size: 18,
                        color: isCompleted || isActive
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index]['title'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive
                            ? AppColors.primary
                            : isCompleted
                                ? Colors.green
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 24,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: isCompleted
                      ? Colors.green
                      : theme.colorScheme.outlineVariant,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPhoneStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'reset_password'.tr,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'enter_phone_reset_instructions'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Text('phone_number'.tr, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
          ],
          decoration: const InputDecoration(
            hintText: '251911058179 or 0911058179',
            prefixIcon: Icon(Icons.phone_android_rounded),
          ),
        ),
        const SizedBox(height: 28),
        Obx(
          () => AppButton(
            text: 'send_code'.tr,
            isLoading: _authController.isSendingResetOtp.value,
            onPressed: _sendOtp,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(ThemeData theme) {
    final phoneDisplay = _authController.resetPhone ?? _phoneController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.sms_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'verify_your_number'.tr,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${'enter_code_sent_to'.tr}\n$phoneDisplay',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // OTP digit boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _otpFocusNodes[i].hasFocus
                      ? AppColors.primary
                      : theme.colorScheme.outlineVariant,
                  width: _otpFocusNodes[i].hasFocus ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4, // allow paste
                obscureText: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onChanged: (val) => _onDigitEntered(i, val),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),
        AppButton(
          text: 'verify_code'.tr,
          onPressed: _verifyOtp,
        ),
        const SizedBox(height: 20),

        // Resend section with countdown
        Center(
          child: Obx(() {
            final cooldown = _authController.resetResendCooldown.value;
            final isSending = _authController.isSendingResetOtp.value;

            if (isSending) {
              return const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            if (cooldown > 0) {
              return Text(
                '${'resend_code_in'.tr} ${cooldown}s',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return TextButton(
              onPressed: _resendOtp,
              child: Text(
                'didnt_receive_code_resend'.tr,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: Colors.green,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'new_password'.tr,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'set_new_pin_desc'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        // New PIN
        Text('new_password'.tr, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPass,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'four_digit_pin'.tr,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            counterText: '',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirm PIN
        Text('confirm_password'.tr, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPass,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'confirm_password'.tr,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            counterText: '',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            ),
          ),
        ),
        const SizedBox(height: 28),

        Obx(
          () => AppButton(
            text: 'reset_password'.tr,
            isLoading: _authController.isResettingPassword.value,
            onPressed: _resetPassword,
          ),
        ),
      ],
    );
  }
}
