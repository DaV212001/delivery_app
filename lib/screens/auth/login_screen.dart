import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../config/storage_config.dart';
import '../../constants/app_assets.dart';
import '../../controllers/auth_controller.dart';
import '../../constants/pages.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _phoneController;
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    String? savedPhone;
    try {
      savedPhone = ConfigPreference.getUserPhone();
    } catch (_) {}
    _phoneController = TextEditingController(
      text: savedPhone?.isNotEmpty == true ? savedPhone : '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (authController.isLoggedIn) {
          Get.offAllNamed(AppRoutes.mainNav);
        }
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final phoneCtrl = TextEditingController(text: _phoneController.text);
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('reset_password'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'phone_number'.tr,
                  hintText: '251911058179',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(labelText: 'new_password'.tr),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                decoration: InputDecoration(labelText: 'confirm_password'.tr),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (phoneCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                Get.snackbar('error'.tr, 'fill_all_fields'.tr);
                return;
              }
              Get.back();
              await AuthService.forgotPassword(
                phone: phoneCtrl.text.trim(),
                password: passCtrl.text,
                passwordConfirmation: confirmPassCtrl.text,
                onSuccess: () {
                  Get.snackbar('success'.tr, 'password_reset_success'.tr);
                },
                onFailure: (err) {
                  Get.snackbar('error'.tr, err);
                },
              );
            },
            child: Text('reset'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo mark
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  AppAssets.appLogo,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _isSignUp ? 'create_account'.tr : 'welcome_back'.tr,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'join_amn_delivery'.tr
                    : 'sign_in_tagline'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // Tab Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'log_in'.tr,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: !_isSignUp ? Colors.white : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isSignUp ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'sign_up'.tr,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _isSignUp ? Colors.white : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_isSignUp) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('first_name'.tr, style: theme.textTheme.labelMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              hintText: 'first_name_hint'.tr,
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('last_name'.tr, style: theme.textTheme.labelMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              hintText: 'last_name_hint'.tr,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('email_address'.tr, style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Phone Number
              Text('phone_number'.tr, style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '251911058179 or 0911058179',
                  prefixIcon: Icon(Icons.phone_android_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              Text('password'.tr, style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'four_digit_pin'.tr,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Remember me & forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(
                    () => Row(
                      children: [
                        Checkbox(
                          value: authController.rememberMe.value,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => authController.rememberMe.value = val ?? true,
                        ),
                        Text('remember_me'.tr, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      'forgot_password'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit button
              Obx(
                () => AppButton(
                  text: _isSignUp ? 'create_account'.tr : 'log_in'.tr,
                  isLoading: authController.isLoading.value,
                  onPressed: () {
                    if (_isSignUp) {
                      authController.register(
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                      );
                    } else {
                      authController.login(_phoneController.text.trim(), _passwordController.text);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Continue as Guest
              Center(
                child: TextButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.mainNav),
                  child: Text(
                    'continue_as_guest'.tr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
