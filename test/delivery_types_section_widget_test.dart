import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/controllers/restaurant_controller.dart';
import 'package:delivery_app/models/category_model.dart';
import 'package:delivery_app/models/multilingual_string.dart';
import 'package:delivery_app/screens/home/widgets/home_delivery_types_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RestaurantController controller;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    controller = Get.put(RestaurantController());
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: const Scaffold(
        body: SingleChildScrollView(
          child: HomeDeliveryTypesSection(),
        ),
      ),
    );
  }

  testWidgets('HomeDeliveryTypesSection hides completely when no delivery types have images',
      (tester) async {
    controller.deliveryTypes.assignAll([
      CategoryModel(
        id: 1,
        name: MultiLangString.fromJson({'en': 'Food'}),
        image: '',
      ),
      CategoryModel(
        id: 2,
        name: MultiLangString.fromJson({'en': 'Courier'}),
        image: '   ',
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.byType(HomeDeliveryTypesSection), findsOneWidget);
    expect(find.text('Delivery Services'), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('HomeDeliveryTypesSection displays cards and normalized titles when images exist',
      (tester) async {
    controller.deliveryTypes.assignAll([
      CategoryModel(
        id: 1,
        name: MultiLangString.fromJson({'en': 'HABESHA FOOD'}),
        image: 'https://erp.amnplc.com/public/storage/delivery-type/1789304181.jpg',
      ),
      CategoryModel(
        id: 2,
        name: MultiLangString.fromJson({'en': 'ELECTRONICS'}),
        image: 'https://erp.amnplc.com/public/storage/delivery-type/1791395318.jpg',
      ),
      CategoryModel(
        id: 3,
        name: MultiLangString.fromJson({'en': 'NO IMAGE SERVICE'}),
        image: '', // Should be filtered out
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Section header should appear
    expect(find.text('Delivery Services'), findsOneWidget);
    expect(find.text('2 services'), findsOneWidget);

    // Titles should be normalized to Title Case
    expect(find.text('Habesha Food'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('No Image Service'), findsNothing);
  });

  testWidgets('Tapping a delivery type card navigates to CategoryStoresScreen',
      (tester) async {
    controller.deliveryTypes.assignAll([
      CategoryModel(
        id: 1,
        name: MultiLangString.fromJson({'en': 'HABESHA FOOD'}),
        image: 'https://erp.amnplc.com/public/storage/delivery-type/1789304181.jpg',
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('Habesha Food'), findsOneWidget);

    // Tap the card
    await tester.tap(find.text('Habesha Food'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Should push CategoryStoresScreen
    expect(Get.currentRoute.isNotEmpty, isTrue);
  });
}
