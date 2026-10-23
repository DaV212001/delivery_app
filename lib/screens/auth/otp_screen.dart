import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/pages.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/app_widgets.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  late final AuthController _authController;
  late final String _phone;
  late final String _email;
  late final int _userId;

  final _isVerifying = false.obs;
  final _isResending = false.obs;
  final _resendCooldown = 0.obs;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _phone = args['phone']?.toString() ?? _authController.pendingPhone ?? '';
    _email = args['email']?.toString() ?? _authController.pendingEmail ?? '';
    _userId = args['userId'] is int
        ? args['userId'] as int
        : int.tryParse(args['userId']?.toString() ?? '0') ?? 0;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    // Auto-submit when all 4 digits filled
    if (_otpValue.length == 4) {
      _verify();
    }
  }


  Future<void> _verify() async {
    final otp = _otpValue;
    if (otp.length < 4) {
      Get.snackbar('incomplete'.tr, 'enter_4_digit_code'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    _isVerifying.value = true;
    await _authController.verifyOtpAndComplete(userId: _userId, otp: otp);
    _isVerifying.value = false;
  }

  Future<void> _resend() async {
    if (_resendCooldown.value > 0) return;
    _isResending.value = true;
    await _authController.resendOtp(phone: _phone);
    _isResending.value = false;

    // 60-second cooldown
    _resendCooldown.value = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_resendCooldown.value > 0) {
        _resendCooldown.value--;
        return true;
      }
      return false;
    });
  }

  void _handleBack() {
    _authController.clearPendingRegistration();
    if (Navigator.of(context).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
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
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Dual channel icon header
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'verify_your_number'.tr,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'enter_code_sent_to'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (_phone.isNotEmpty || _email.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (_phone.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.phone_android_rounded,
                            size: 16, color: AppColors.primary),
                        label: Text(_phone,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (_email.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.email_outlined,
                            size: 16, color: AppColors.primary),
                        label: Text(_email,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              const SizedBox(height: 14),
              // Prominent Instruction Card informing the user to check phone or email
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'check_phone_or_email_instructions'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
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
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _focusNodes[i].hasFocus
                            ? AppColors.primary
                            : theme.colorScheme.outlineVariant,
                        width: _focusNodes[i].hasFocus ? 2 : 1.5,
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
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      obscureText: true,
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
                      onTap: () => setState(() {}),
                      // Handle backspace to go to previous box
                      onEditingComplete: () {},
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              // Verify button
              Obx(() => AppButton(
                    text: 'verify_code'.tr,
                    isLoading: _isVerifying.value,
                    onPressed: _verify,
                  )),

              const SizedBox(height: 20),

              // Resend
              Center(
                child: Obx(() {
                  if (_isResending.value) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (_resendCooldown.value > 0) {
                    return Text(
                      '${'resend_code_in'.tr} ${_resendCooldown.value}s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return TextButton(
                    onPressed: _resend,
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
          ),
        ),
        ),
      ),
    );
  }
}
