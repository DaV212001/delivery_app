import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/app_colors.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String title;
  final Future<void> Function()? onReceiptDetected;
  final WebViewController? controller; // Optional injection for testing

  const PaymentWebViewScreen({
    super.key,
    required this.initialUrl,
    this.title = 'Payment Checkout',
    this.onReceiptDetected,
    this.controller,
  });

  /// Helper to check if a URL represents a payment receipt page
  static bool isReceiptUrl(String url) {
    return url.toLowerCase().contains('receipt');
  }

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  final RxInt _loadingProgress = 0.obs;
  final RxBool _isLoading = true.obs;
  bool _receiptHandled = false;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            _loadingProgress.value = progress;
            if (progress >= 100) {
              _isLoading.value = false;
            }
          },
          onPageStarted: (String url) {
            _isLoading.value = true;
            _checkAndHandleReceiptUrl(url);
          },
          onPageFinished: (String url) {
            _isLoading.value = false;
            _checkAndHandleReceiptUrl(url);
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              _checkAndHandleReceiptUrl(change.url!);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            _checkAndHandleReceiptUrl(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Payment WebView error: ${error.description}');
          },
        ),
      );

    final uri = Uri.tryParse(widget.initialUrl);
    if (uri != null) {
      _controller.loadRequest(uri);
    }
  }

  Future<void> _checkAndHandleReceiptUrl(String url) async {
    if (_receiptHandled) return;

    if (PaymentWebViewScreen.isReceiptUrl(url)) {
      _receiptHandled = true;

      // 1. Trigger the callback or fetch wallet directly
      if (widget.onReceiptDetected != null) {
        await widget.onReceiptDetected!();
      } else {
        final profileController = Get.isRegistered<ProfileController>()
            ? Get.find<ProfileController>()
            : Get.put(ProfileController());
        await profileController.loadWallet();
      }

      // 2. Auto return the user immediately
      if (mounted && Navigator.canPop(context)) {
        Get.back(result: true);
      }

      // 3. Show success snackbar
      Get.snackbar(
        'payment_successful'.tr,
        'receipt_verified_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_receiptHandled) {
      return true;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('exit_payment_title'.tr),
        content: Text(
          'exit_payment_desc'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('continue_payment'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('exit'.tr),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canExit = await _onWillPop();
        if (canExit && context.mounted) {
          Get.back(result: _receiptHandled);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'ssl_encrypted'.tr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'reload'.tr,
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress Bar
            Obx(() {
              if (!_isLoading.value && _loadingProgress.value >= 100) {
                return const SizedBox.shrink();
              }
              return LinearProgressIndicator(
                value: _loadingProgress.value / 100.0,
                backgroundColor: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainer,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 3,
              );
            }),

            // Webview
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
