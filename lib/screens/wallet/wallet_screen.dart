import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/pages.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/wallet_model.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/skeletons/skeleton_loaders.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final RxString _selectedFilter = 'All'.obs;
  static const List<String> _filters = [
    'All',
    'Top-ups',
    'Bonuses',
    'Completed',
    'Pending',
  ];

  String _getFilterLabel(String f) {
    switch (f) {
      case 'Top-ups':
        return 'topups_filter'.tr;
      case 'Bonuses':
        return 'bonuses_filter'.tr;
      case 'Completed':
        return 'completed'.tr;
      case 'Pending':
        return 'pending'.tr;
      case 'All':
      default:
        return 'all'.tr;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileController = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : Get.put(ProfileController());
      profileController.loadWallet();
    });
  }

  void _showTopupDialog(BuildContext context, ProfileController profileController) {
    final amountController = TextEditingController(text: '100');
    final quickAmounts = [100.0, 250.0, 500.0, 1000.0];

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'topup_wallet'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'topup_prompt'.tr,
                    style: TextStyle(
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick amount selector chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickAmounts.map((amt) {
                      final isSelected = amountController.text == amt.toStringAsFixed(0);
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            amountController.text = amt.toStringAsFixed(0);
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkSurfaceContainerLow
                                    : AppColors.surfaceContainerLow),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '+${amt.toStringAsFixed(0)} Br',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.onSurface),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'custom_amount'.tr,
                      suffixText: 'Br',
                      prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkInputBg : AppColors.inputBg,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'secured_chapa'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
              Obx(() {
                if (profileController.isSaving.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                }
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () {
                    final val = double.tryParse(amountController.text.trim()) ?? 0;
                    if (val <= 0) {
                      Get.snackbar(
                        'invalid_amount'.tr,
                        'enter_valid_amount'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    profileController.topupWallet(val);
                  },
                  child: Text(
                    'proceed_to_pay'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showTransactionDetailSheet(BuildContext context, WalletTransaction tx) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull indicator & Close header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Get.back(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tx.isCompleted
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                ),
                child: Icon(
                  tx.isCompleted ? Icons.check_circle_rounded : Icons.access_time_rounded,
                  size: 34,
                  color: tx.isCompleted ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              Text(
                tx.formattedAmount,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tx.isDebit ? AppColors.secondary : Colors.green,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                tx.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Details container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('status'.tr, tx.isCompleted ? 'completed'.tr : 'pending'.tr,
                        valueColor: tx.isCompleted ? Colors.green : Colors.orange),
                    const Divider(height: 20),
                    if (tx.id != null) ...[
                      _buildDetailRow('transaction_id'.tr, '#${tx.id}'),
                      const Divider(height: 20),
                    ],
                    _buildDetailRow('date'.tr, _formatDate(tx)),
                    const Divider(height: 20),
                    _buildDetailRow('payment_type'.tr, tx.type?.toUpperCase() ?? 'WALLET'),
                    if (tx.description != null && tx.description != tx.title) ...[
                      const Divider(height: 20),
                      _buildDetailRow('note'.tr, tx.description!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
                    foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => Get.back(),
                  child: Text('close'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(WalletTransaction tx) {
    if (tx.date != null) {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(tx.date!);
    }
    return tx.rawDate ?? 'Recent';
  }

  List<WalletTransaction> _getFilteredTransactions(List<WalletTransaction> all) {
    final filter = _selectedFilter.value;
    switch (filter) {
      case 'Top-ups':
        return all.where((t) => t.isTopup).toList();
      case 'Bonuses':
        return all.where((t) => t.isBonus).toList();
      case 'Completed':
        return all.where((t) => t.isCompleted).toList();
      case 'Pending':
        return all.where((t) => t.isPending).toList();
      case 'All':
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'wallet_balance'.tr,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'refresh_wallet'.tr,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => profileController.loadWallet(),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (!authController.isLoggedIn) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'access_your_wallet'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'wallet_guest_sub'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: Text(
                        'sign_in_register'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => Get.toNamed(AppRoutes.login),
                    ),
                  ],
                ),
              ),
            );
          }

          final allTransactions = profileController.transactions;
          final filteredTransactions = _getFilteredTransactions(allTransactions);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => profileController.loadWallet(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Wallet Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'amn_pay_wallet'.tr,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 12, color: Colors.greenAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'active'.tr,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'available_balance'.tr,
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => Text(
                            profileController.walletBalance.value.formattedBirr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: Text(
                                  'topup_wallet'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: () => _showTopupDialog(context, profileController),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'total_records'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Obx(
                                () => Text(
                                  '${profileController.transactions.length}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'completed'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Obx(
                                () => Text(
                                  '${profileController.transactions.where((t) => t.isCompleted).length}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // History Section Header & Filter Chips
                  Text(
                    'recent_transactions'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(
                      () => Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter.value == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: PillChip(
                              label: _getFilterLabel(filter),
                              isSelected: isSelected,
                              onTap: () => _selectedFilter.value = filter,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transactions List or Empty / Loading States
                  Obx(() {
                    if (profileController.isLoadingWallet.value && profileController.transactions.isEmpty) {
                      return Column(
                        children: List.generate(
                          3,
                          (_) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              children: [
                                ShimmerBox(width: 44, height: 44, borderRadius: 12),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ShimmerBox(width: 120, height: 16, borderRadius: 4),
                                      SizedBox(height: 6),
                                      ShimmerBox(width: 80, height: 12, borderRadius: 4),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                ShimmerBox(width: 60, height: 18, borderRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    if (filteredTransactions.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                size: 30,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _selectedFilter.value == 'All'
                                  ? 'no_transactions'.tr
                                  : '${'no_matching_results'.tr} (${_getFilterLabel(_selectedFilter.value)})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'no_transactions_sub'.tr,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              width: 140,
                              height: 40,
                              text: 'topup'.tr,
                              onPressed: () => _showTopupDialog(context, profileController),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: filteredTransactions.map((tx) {
                        final isDebit = tx.isDebit;
                        final isBonus = tx.isBonus;
                        final isCompleted = tx.isCompleted;

                        Color iconBgColor;
                        Color iconColor;
                        IconData iconData;

                        if (isBonus) {
                          iconBgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.12);
                          iconColor = const Color(0xFF8B5CF6);
                          iconData = Icons.card_giftcard_rounded;
                        } else if (isDebit) {
                          iconBgColor = AppColors.secondary.withValues(alpha: 0.12);
                          iconColor = AppColors.secondary;
                          iconData = Icons.arrow_upward_rounded;
                        } else {
                          iconBgColor = AppColors.primary.withValues(alpha: 0.12);
                          iconColor = AppColors.primary;
                          iconData = Icons.arrow_downward_rounded;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _showTransactionDetailSheet(context, tx),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: iconBgColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(iconData, color: iconColor, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.title,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              if (tx.date != null)
                                                DateFormat('yyyy-MM-dd').format(tx.date!)
                                              else if (tx.rawDate != null && tx.rawDate!.isNotEmpty)
                                                tx.rawDate!,
                                              if (tx.id != null) '#${tx.id}',
                                            ].join(' • '),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          tx.formattedAmount,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: isDebit ? AppColors.secondary : Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? Colors.green.withValues(alpha: 0.12)
                                                : Colors.orange.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isCompleted ? 'completed'.tr : 'pending'.tr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isCompleted ? Colors.green : Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
