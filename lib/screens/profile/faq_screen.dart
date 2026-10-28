import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/faq_model.dart';
import '../../models/multilingual_string.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late final ProfileController _profileController;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedCategory = 'all'.obs;

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqItem> get _fallbackFaqs => const [
        FaqItem(
          id: 1,
          question: MultiLangString(
            en: 'How do I place an order on AMN Delivery?',
            am: 'በAMN Delivery እንዴት ማዘዝ እችላለሁ?',
          ),
          answer: MultiLangString(
            en: 'Browse restaurants, groceries, or stores from the Home screen, add your favorite items to your cart, set your delivery address on the interactive map, choose your payment method, and tap Place Order.',
            am: 'ከመነሻ ገጹ ምግብ ቤቶችን ወይም ሱቆችን ይምረጡ፣ እቃዎችን ወደ ጋሪዎ ያክሉ፣ አድራሻዎን በካርታው ላይ ያመልክቱ እና ትዕዛዝዎን ያጠናቅቁ።',
          ),
        ),
        FaqItem(
          id: 2,
          question: MultiLangString(
            en: 'How do I track my delivery rider in real time?',
            am: 'የማድረሻ አሽከርካሪዬን በቀጥታ እንዴት መከታተል እችላለሁ?',
          ),
          answer: MultiLangString(
            en: 'After placing an order, navigate to the Orders tab or tap on the active order tracking banner. You will see live GPS rider movement on the map with estimated arrival time.',
            am: 'ትዕዛዝ ከሰጡ በኋላ ወደ "ትዕዛዞች" ገጽ በመሄድ የቀጥታ ጂፒኤስ ካርታ እና የሚደርስበትን ግምታዊ ሰዓት መከታተል ይችላሉ።',
          ),
        ),
        FaqItem(
          id: 3,
          question: MultiLangString(
            en: 'What payment methods are accepted?',
            am: 'ምን ዓይነት የክፍያ አማራጮች ይደገፋሉ?',
          ),
          answer: MultiLangString(
            en: 'We accept the AMN In-App Wallet, Telebirr, Chapa (all major local bank cards and mobile wallets), and Cash on Delivery (COD) for eligible merchants.',
            am: 'AMN የኪስ ቦርሳ (Wallet)፣ ቴሌብር፣ ቻፓ (የባንክ ካርዶች እና ሞባይል ባንኪንግ) እና በእጅ የሚከፈል ጥሬ ገንዘብ (COD) እንደግፋለን።',
          ),
        ),
        FaqItem(
          id: 4,
          question: MultiLangString(
            en: 'How does the AMN In-App Wallet work?',
            am: 'የAMN ኢን-አፕ ዋሌት እንዴት ይሰራል?',
          ),
          answer: MultiLangString(
            en: 'You can top up your AMN Wallet anytime using Telebirr or Chapa from the Profile tab. Wallet payments offer the fastest one-tap checkout with automatic refund crediting.',
            am: 'በቴሌብር ወይም በቻፓ ዋሌትዎን መሙላት ይችላሉ። ፈጣን ክፍያ እና በቀላሉ ተመላሽ ገንዘብ ለማግኘት ይረዳል።',
          ),
        ),
        FaqItem(
          id: 5,
          question: MultiLangString(
            en: 'Can I cancel or modify my delivery order?',
            am: 'ትዕዛዜን መሰረዝ ወይም ማስተካከል እችላለሁ?',
          ),
          answer: MultiLangString(
            en: 'Orders can be cancelled free of charge before the merchant confirms and begins preparing your items. Once a driver has been dispatched or preparation begins, please contact our support team immediately.',
            am: 'ነጋዴው ምግብ ማዘጋጀት ከመጀመሩ በፊት በነፃ መሰረዝ ይችላሉ። ዝግጅት ከተጀመረ እባክዎ ወዲያውኑ ድጋፍ ሰጪ ቡድናችንን ያግኙ።',
          ),
        ),
        FaqItem(
          id: 6,
          question: MultiLangString(
            en: 'How do I use the Courier parcel delivery service?',
            am: 'የጥቅል ማድረሻ (Courier) አገልግሎትን እንዴት እጠቀማለሁ?',
          ),
          answer: MultiLangString(
            en: 'Tap "Courier" from the home shortcuts. Select package type, input the pickup and delivery addresses with sender/recipient phone numbers, and a dedicated courier will pick up and deliver your parcel.',
            am: 'ከመነሻ ገጹ "Courier" የሚለውን ይጫኑ፣ የጥቅል አይነት ይምረጡ፣ የመነሻ እና መዳረሻ አድራሻዎችን በማስገባት ትዕዛዝ ይስጡ።',
          ),
        ),
        FaqItem(
          id: 7,
          question: MultiLangString(
            en: 'How do I save multiple delivery addresses?',
            am: 'በርካታ የማድረሻ አድራሻዎችን እንዴት መመዝገብ እችላለሁ?',
          ),
          answer: MultiLangString(
            en: 'Open your Profile tab and select "Saved Addresses". Tap the "+" icon to pick a location on Gebeta Maps, give it a label (Home, Work, Other), and save it for instant checkout.',
            am: 'በመገለጫዎ ውስጥ "የተቀመጡ አድራሻዎች" የሚለውን ይክፈቱ። "+" በመጫን በካርታው ላይ አድራሻ መርጠው ስም በመስጠት ያስቀምጡ።',
          ),
        ),
        FaqItem(
          id: 8,
          question: MultiLangString(
            en: 'What if an item is missing or my order is incorrect?',
            am: 'የጎደለ እቃ ካለ ወይም ትዕዛዝ ከተሳሳተ ምን ማድረግ አለብኝ?',
          ),
          answer: MultiLangString(
            en: 'If your order arrives incomplete or damaged, report it directly from the Order Details screen or contact AMN Customer Support. Our team will verify and promptly issue an in-app wallet refund or redelivery.',
            am: 'ትዕዛዝዎ የተጓደለ ከሆነ በትዕዛዝ ዝርዝር ገጽ ወይም በደንበኞች አገልግሎት ሪፖርት ያድርጉ። ወዲያውኑ ምርመራ ተደርጎ ተመላሽ ይደረጋል።',
          ),
        ),
      ];

  List<FaqItem> _filterFaqs(List<FaqItem> items, String query, String category) {
    var result = items;

    // Filter by query
    if (query.isNotEmpty) {
      final q = query.toLowerCase().trim();
      result = result.where((item) {
        final question = item.questionText.toLowerCase();
        final answer = item.answerText.toLowerCase();
        return question.contains(q) || answer.contains(q);
      }).toList();
    }

    // Filter by category keywords if not 'all'
    if (category == 'orders') {
      result = result
          .where((item) =>
              item.questionText.toLowerCase().contains('order') ||
              item.questionText.toLowerCase().contains('ትዕዛዝ') ||
              item.answerText.toLowerCase().contains('order') ||
              item.questionText.toLowerCase().contains('cancel'))
          .toList();
    } else if (category == 'delivery') {
      result = result
          .where((item) =>
              item.questionText.toLowerCase().contains('delivery') ||
              item.questionText.toLowerCase().contains('track') ||
              item.questionText.toLowerCase().contains('courier') ||
              item.questionText.toLowerCase().contains('አድራሻ') ||
              item.answerText.toLowerCase().contains('delivery') ||
              item.answerText.toLowerCase().contains('gps'))
          .toList();
    } else if (category == 'payments') {
      result = result
          .where((item) =>
              item.questionText.toLowerCase().contains('payment') ||
              item.questionText.toLowerCase().contains('wallet') ||
              item.questionText.toLowerCase().contains('telebirr') ||
              item.questionText.toLowerCase().contains('chapa') ||
              item.questionText.toLowerCase().contains('ክፍያ') ||
              item.answerText.toLowerCase().contains('wallet'))
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'faqs'.tr.isNotEmpty ? 'faqs'.tr : 'FAQs',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _profileController.loadInformation(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.darkSurfaceContainerLow,
                            AppColors.darkSurface,
                          ]
                        : [
                            AppColors.primaryContainer.withValues(alpha: 0.6),
                            AppColors.surface,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutline.withValues(alpha: 0.3)
                        : AppColors.primaryFixed.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'faq'.tr.isNotEmpty ? 'faq'.tr : 'FAQ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'faqs_support_sub'.tr.isNotEmpty
                                ? 'faqs_support_sub'.tr
                                : 'Frequently Asked Questions & support',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) => _searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'search_hint'.tr.isNotEmpty
                      ? 'search'.tr
                      : 'Search FAQs...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Obx(
                    () => _searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery.value = '';
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkInputBg : AppColors.inputBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Category Filter Chips
              Obx(() {
                final currentCat = _selectedCategory.value;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All', currentCat == 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('orders', 'Orders', currentCat == 'orders'),
                      const SizedBox(width: 8),
                      _buildFilterChip('delivery', 'Delivery & Courier', currentCat == 'delivery'),
                      const SizedBox(width: 8),
                      _buildFilterChip('payments', 'Payment & Wallet', currentCat == 'payments'),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // FAQ List
              Obx(() {
                final rawFaqs = _profileController.faqs.isNotEmpty
                    ? _profileController.faqs.toList()
                    : _fallbackFaqs;

                final filtered = _filterFaqs(
                  rawFaqs,
                  _searchQuery.value,
                  _selectedCategory.value,
                );

                Widget listContent;
                if (filtered.isEmpty) {
                  listContent = Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No matching questions found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'try_searching_different'.tr.isNotEmpty
                                ? 'try_searching_different'.tr
                                : 'Try searching for something else or clearing filters',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset Search'),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery.value = '';
                              _selectedCategory.value = 'all';
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  listContent = ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return _buildFaqCard(
                        context,
                        isDark: isDark,
                        faq: item,
                        index: index + 1,
                      );
                    },
                  );
                }

                return listContent;
              }),

              const SizedBox(height: 28),

              // Contact Support Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Still have questions?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Our 24/7 customer care team is always happy to assist you with your orders and inquiries.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isSelected) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _selectedCategory.value = key,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant),
        ),
      ),
    );
  }

  Widget _buildFaqCard(
    BuildContext context, {
    required bool isDark,
    required FaqItem faq,
    required int index,
  }) {
    final theme = Theme.of(context);

    return Theme(
      // Remove default ExpansionTile borders
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
          ),
        ),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          title: Text(
            faq.questionText,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq.answerText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  height: 1.55,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
