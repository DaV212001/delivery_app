import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../config/storage_config.dart';
import '../../constants/app_assets.dart';
import '../../controllers/auth_controller.dart';
import '../../constants/pages.dart';
import '../../core/theme/app_colors.dart';
import '../../models/country_code.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/country_code_dropdown.dart';

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

  CountryCode _selectedCountry = CountryCode.defaultCountry;
  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    String? savedPhone;
    try {
      savedPhone = ConfigPreference.getUserPhone();
    } catch (_) {}

    if (savedPhone != null && savedPhone.isNotEmpty) {
      final detected = CountryCode.findByPhoneNumber(savedPhone);
      if (detected != null) {
        _selectedCountry = detected;
        final dialDigits = detected.dialCode.replaceAll(RegExp(r'[^0-9]'), '');
        final clean = savedPhone.replaceAll(RegExp(r'[^0-9]'), '');
        final local = clean.startsWith(dialDigits) ? clean.substring(dialDigits.length) : clean;
        _phoneController = TextEditingController(text: local);
      } else {
        _phoneController = TextEditingController(text: savedPhone);
      }
    } else {
      _phoneController = TextEditingController();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (authController.isLoggedIn) {
          Get.offAllNamed(AppRoutes.mainNav);
        }
      }
    });
  }

  void _onPhoneChanged(String val) {
    if (val.trim().startsWith('+')) {
      final detected = CountryCode.findByPhoneNumber(val);
      if (detected != null && detected != _selectedCountry) {
        setState(() {
          _selectedCountry = detected;
        });
      }
    }
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

  void _showForgotPasswordDialog() async {
    final cleanPhone = AuthController.sanitizePhone(
      _phoneController.text.trim(),
      _selectedCountry.dialCode,
    );
    final result = await Get.toNamed(AppRoutes.forgotPassword, arguments: {
      'phone': cleanPhone,
    });
    if (result is String && result.isNotEmpty) {
      final detected = CountryCode.findByPhoneNumber(result);
      if (detected != null) {
        _selectedCountry = detected;
        final dialDigits = detected.dialCode.replaceAll(RegExp(r'[^0-9]'), '');
        final clean = result.replaceAll(RegExp(r'[^0-9]'), '');
        final local = clean.startsWith(dialDigits) ? clean.substring(dialDigits.length) : clean;
        _phoneController.text = local;
      } else {
        _phoneController.text = result;
      }
    }
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
                onChanged: _onPhoneChanged,
                decoration: InputDecoration(
                  hintText: _selectedCountry.dialCode == '+251'
                      ? '911058179 or 0911058179'
                      : 'enter_phone_number'.tr,
                  prefixIcon: CountryCodeDropdown(
                    selectedCountry: _selectedCountry,
                    onChanged: (country) {
                      setState(() {
                        _selectedCountry = country;
                      });
                    },
                  ),
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
                    final phoneText = _phoneController.text.trim();
                    if (phoneText.isEmpty) {
                      Get.snackbar(
                        'error'.tr,
                        'enter_valid_phone'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        colorText: Colors.white,
                      );
                      return;
                    }
                    if (_passwordController.text.length < 4) {
                      Get.snackbar(
                        'error'.tr,
                        'four_digit_pin'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        colorText: Colors.white,
                      );
                      return;
                    }
                    if (_isSignUp) {
                      if (_firstNameController.text.trim().isEmpty) {
                        Get.snackbar(
                          'error'.tr,
                          'fill_all_fields'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          colorText: Colors.white,
                        );
                        return;
                      }
                      authController.register(
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        phone: phoneText,
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                        countryCode: _selectedCountry.dialCode,
                      );
                    } else {
                      authController.login(
                        phoneText,
                        _passwordController.text,
                        countryCode: _selectedCountry.dialCode,
                      );
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
