import '../constants/app_assets.dart';
import '../models/cart_item.dart';
import '../models/delivery_item.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/promotion.dart';
import '../models/special_offer.dart';
import '../models/store.dart';
import '../models/user_profile.dart';

class MockData {
  // Current user
  static const UserProfile currentUser = UserProfile(
    id: 'user_1',
    name: 'Alex Johnson',
    email: 'alex.johnson@example.com',
    avatarUrl: AppAssets.userAvatar,
    tagline: 'Smart Shopper & Delivery Explorer',
    rating: 4.9,
    totalOrders: 42,
    defaultAddress: '742 Evergreen Terrace, New York, NY',
  );

  // Common Addons for Food
  static const List<CustomizationAddon> burgerAddons = [
    CustomizationAddon(id: 'addon_cheese', name: 'Extra Cheese', price: 1.50),
    CustomizationAddon(id: 'addon_bacon', name: 'Crispy Bacon', price: 2.00),
    CustomizationAddon(id: 'addon_avocado', name: 'Avocado', price: 2.50),
  ];

  static const List<String> burgerTemperatures = [
    'Medium Rare',
    'Medium',
    'Well Done',
  ];

  static const List<String> burgerRemovals = [
    'Onions',
    'Tomato',
    'Pickles',
  ];

  // 1. Electronics Items (TechHub Express)
  static const DeliveryItem ancEarbuds = DeliveryItem(
    id: 'item_anc_earbuds',
    storeId: 'store_techhub',
    name: 'Pro Wireless ANC Earbuds',
    description:
        'Active noise-cancelling wireless earbuds with 32-hour battery life, sweat resistance, and spatial audio.',
    price: 89.99,
    imageUrl: AppAssets.earbudsItem,
    category: 'Audio',
    variantTitle: 'Select Color',
    availableVariants: ['Midnight Black', 'Pearl White', 'Deep Navy'],
    availableAddons: [
      CustomizationAddon(id: 'add_warranty', name: '2-Year Protection Plan', price: 14.99),
      CustomizationAddon(id: 'add_silicone_case', name: 'Silicone Carry Case', price: 8.50),
    ],
  );

  static const DeliveryItem fastChargingCable = DeliveryItem(
    id: 'item_usb_cable',
    storeId: 'store_techhub',
    name: 'Braided USB-C Fast Cable (2m)',
    description:
        '100W PD rapid charging cable with nylon braided exterior and reinforced connectors.',
    price: 16.99,
    imageUrl: AppAssets.usbCableItem,
    category: 'Cables & Power',
    variantTitle: 'Length',
    availableVariants: ['1 Meter', '2 Meters', '3 Meters'],
  );

  static const DeliveryItem powerBank = DeliveryItem(
    id: 'item_power_bank',
    storeId: 'store_techhub',
    name: 'Ultra-Slim 10,000mAh Power Bank',
    description:
        'Compact high-capacity power bank with dual USB-C ports and smart LED digital display.',
    price: 34.50,
    imageUrl: AppAssets.powerBankItem,
    category: 'Cables & Power',
    variantTitle: 'Color',
    availableVariants: ['Space Gray', 'Matte White'],
  );

  static const DeliveryItem carMount = DeliveryItem(
    id: 'item_car_mount',
    storeId: 'store_techhub',
    name: 'Magnetic Qi2 Fast Car Phone Mount',
    description:
        '15W wireless charging car mount with 360-degree rotation and secure air vent clamp.',
    price: 29.99,
    imageUrl: AppAssets.carMountItem,
    category: 'Accessories',
  );

  // 2. Groceries Items (FreshMart Organics)
  static const DeliveryItem organicAvocados = DeliveryItem(
    id: 'item_avocados',
    storeId: 'store_freshmart',
    name: 'Organic Hass Avocados (3 Pack)',
    description:
        'Ripe and ready-to-eat organic avocados, packed with nutrients, fiber, and healthy omega fats.',
    price: 4.99,
    imageUrl: AppAssets.avocadoItem,
    category: 'Produce',
    unit: '3 pack',
    variantTitle: 'Ripeness',
    availableVariants: ['Ripe & Ready', 'Firm (2-3 days)'],
    availableAddons: [
      CustomizationAddon(id: 'add_lime', name: 'Fresh Organic Lime', price: 0.75),
    ],
  );

  static const DeliveryItem sourdoughBread = DeliveryItem(
    id: 'item_sourdough',
    storeId: 'store_freshmart',
    name: 'Artisan Country Sourdough Loaf',
    description:
        'Naturally fermented over 36 hours for a crisp golden crust and light airy crumb.',
    price: 6.50,
    imageUrl: AppAssets.sourdoughItem,
    category: 'Bakery',
    unit: 'loaf',
    variantTitle: 'Preparation',
    availableVariants: ['Whole Loaf', 'Pre-Sliced'],
  );

  static const DeliveryItem coldPressedJuice = DeliveryItem(
    id: 'item_green_juice',
    storeId: 'store_freshmart',
    name: 'Vital Green Cold-Pressed Juice',
    description:
        'Organic kale, cucumber, crisp green apple, spinach, celery, and fresh lemon (500ml).',
    price: 7.25,
    imageUrl: AppAssets.juiceItem,
    category: 'Beverages',
    unit: '500ml',
  );

  static const DeliveryItem freshStrawberries = DeliveryItem(
    id: 'item_strawberries',
    storeId: 'store_freshmart',
    name: 'Fresh Organic Strawberries (400g)',
    description:
        'Sweet, sun-ripened organic strawberries harvested fresh from local family farms.',
    price: 5.49,
    imageUrl: AppAssets.strawberryItem,
    category: 'Produce',
    unit: '400g pack',
  );

  // 3. Pharmacy & Health Items (CareFirst Pharmacy)
  static const DeliveryItem vitaminC = DeliveryItem(
    id: 'item_vitamin_c',
    storeId: 'store_carefirst',
    name: 'Vitamin C 1000mg Immune Support',
    description:
        'High-potency antioxidant daily formula with rose hips and bioflavonoids (60 tablets).',
    price: 14.25,
    imageUrl: AppAssets.vitaminCItem,
    category: 'Vitamins & Wellness',
    unit: '60 tablets',
  );

  static const DeliveryItem firstAidKit = DeliveryItem(
    id: 'item_first_aid',
    storeId: 'store_carefirst',
    name: 'Compact Travel First Aid Kit',
    description:
        '56-piece travel and home medical kit with bandages, antiseptic wipes, and compact scissors.',
    price: 19.99,
    imageUrl: AppAssets.firstAidItem,
    category: 'First Aid',
  );

  static const DeliveryItem barrierHandCream = DeliveryItem(
    id: 'item_hand_cream',
    storeId: 'store_carefirst',
    name: 'Barrier Repair Hand Cream (100ml)',
    description:
        'Fast-absorbing botanical barrier balm with organic shea butter and ceramides.',
    price: 11.50,
    imageUrl: AppAssets.handCreamItem,
    category: 'Personal Care',
  );

  // 4. Flowers & Gifts Items (Bloom & Petal Florist)
  static const DeliveryItem pastelBouquet = DeliveryItem(
    id: 'item_bouquet',
    storeId: 'store_bloom_petal',
    name: 'Pastel Sunrise Fresh Bouquet',
    description:
        'Hand-tied floral arrangement of fresh pink roses, white lilies, and fragrant eucalyptus.',
    price: 42.00,
    imageUrl: AppAssets.bouquetItem,
    category: 'Bouquets',
    variantTitle: 'Bouquet Size',
    availableVariants: ['Standard', 'Deluxe (+\$15)', 'Grand (+\$30)'],
    availableAddons: [
      CustomizationAddon(id: 'add_card', name: 'Handwritten Gift Card', price: 3.50),
      CustomizationAddon(id: 'add_vase', name: 'Clear Glass Vase', price: 9.00),
    ],
  );

  static const DeliveryItem lavenderCandle = DeliveryItem(
    id: 'item_candle',
    storeId: 'store_bloom_petal',
    name: 'French Lavender Soy Candle',
    description:
        '100% natural soy wax candle infused with calming lavender essential oils (45hr burn).',
    price: 22.00,
    imageUrl: AppAssets.candleItem,
    category: 'Gifts',
  );

  // 5. Courier Service Items (Express Parcel Courier)
  static const DeliveryItem onDemandParcel = DeliveryItem(
    id: 'item_parcel_delivery',
    storeId: 'store_express_courier',
    name: 'Express Door-to-Door Courier',
    description:
        'Fast point-to-point courier delivery. Direct pickup and doorstep drop-off in under 45 mins.',
    price: 9.99,
    imageUrl: AppAssets.parcelBoxItem,
    category: 'Courier',
    variantTitle: 'Package Size',
    availableVariants: ['Envelope / Docs (< 0.5kg)', 'Small Box (< 3kg)', 'Medium Box (< 10kg)'],
    availableAddons: [
      CustomizationAddon(id: 'add_fragile', name: 'Fragile / White-Glove Care', price: 3.00),
      CustomizationAddon(id: 'add_signature', name: 'Direct Signature Required', price: 2.00),
    ],
  );

  // 6. Food Items (Burger Foundry & Luigi\'s)
  static const DeliveryItem foundryClassic = DeliveryItem(
    id: 'item_classic_burger',
    storeId: 'rest_burger_foundry',
    name: 'The Foundry Classic',
    description:
        'Our signature beef patty, aged cheddar, crisp lettuce, tomato, and house sauce on a brioche bun.',
    price: 12.50,
    imageUrl: AppAssets.classicBurgerItem,
    category: 'Burgers',
    variantTitle: 'Choice of Meat Temperature',
    availableVariants: burgerTemperatures,
    availableAddons: burgerAddons,
    removableOptions: burgerRemovals,
  );

  static const DeliveryItem truffleParmFries = DeliveryItem(
    id: 'item_truffle_fries',
    storeId: 'rest_burger_foundry',
    name: 'Truffle Parm Fries',
    description:
        'Crispy shoestring fries tossed in white truffle oil, parsley, and aged parmesan cheese.',
    price: 6.50,
    imageUrl: AppAssets.truffleFries,
    category: 'Sides',
  );

  static const DeliveryItem doubleChocShake = DeliveryItem(
    id: 'item_choc_shake',
    storeId: 'rest_burger_foundry',
    name: 'Double Choc Shake',
    description:
        'Thick milkshake made with premium Belgian chocolate ice cream, topped with whipped cream.',
    price: 7.00,
    imageUrl: AppAssets.chocShake,
    category: 'Drinks',
  );

  static const DeliveryItem cheeseburgerCustomizable = DeliveryItem(
    id: 'item_custom_cheeseburger',
    storeId: 'rest_burger_foundry',
    name: 'Classic Cheeseburger',
    description:
        'Juicy beef patty, melted cheddar, crisp leaf lettuce, vine tomatoes, and signature house sauce.',
    price: 12.99,
    imageUrl: AppAssets.cheeseburgerModal,
    category: 'Burgers',
    variantTitle: 'Choice of Meat Temperature',
    availableVariants: burgerTemperatures,
    availableAddons: burgerAddons,
    removableOptions: burgerRemovals,
  );

  static const DeliveryItem woodfiredPizza = DeliveryItem(
    id: 'item_margherita_pizza',
    storeId: 'rest_luigi_pizza',
    name: 'Woodfired Margherita Pizza',
    description:
        'San Marzano tomato sauce, fresh buffalo mozzarella, fragrant basil leaves, and extra virgin olive oil.',
    price: 18.00,
    imageUrl: AppAssets.pizzaFeatured,
    category: 'Pizza',
  );

  static const DeliveryItem salmonPoke = DeliveryItem(
    id: 'item_salmon_poke',
    storeId: 'store_freshmart',
    name: 'Spicy Salmon Poke Bowl',
    description:
        'Fresh Atlantic salmon, creamy avocado, edamame, cucumber, and spicy ponzu dressing over brown rice.',
    price: 16.50,
    imageUrl: AppAssets.pokeBowlCart,
    category: 'Produce',
  );

  static const DeliveryItem icedMatcha = DeliveryItem(
    id: 'item_matcha_latte',
    storeId: 'store_freshmart',
    name: 'Iced Matcha Latte',
    description:
        'Organic Japanese ceremonial matcha layered with fresh oat milk and served over light ice.',
    price: 5.50,
    imageUrl: AppAssets.matchaLatteCart,
    category: 'Beverages',
  );

  // Multi-Category Stores List
  static final List<Store> restaurants = [
    // 1. Chanoly Noodles (Olympia) - Matching Screenshot
    const Store(
      id: 'rest_chanoly_olympia',
      name: 'Chanoly Noodles',
      branch: 'Olympia',
      categoryDescription: 'Asian • Noodles • Fast Casual',
      type: StoreType.restaurant,
      priceLevel: r'$$',
      rating: 5.0,
      reviewsCount: 640,
      deliveryTime: '41 min',
      deliveryFee: '132 Br',
      avgPricePerPerson: 778.0,
      deliveryFeeAmount: 132.0,
      minOrder: 250.0,
      distanceKm: 1.0,
      latitude: 9.0054,
      longitude: 38.7667,
      heroImageUrl: AppAssets.ramenBowl,
      isFeatured: true,
      badge: 'Top Rated',
      categories: ['Popular', 'Noodles', 'Asian', 'Sides'],
      items: [
        DeliveryItem(
          id: 'item_chanoly_ramen',
          storeId: 'rest_chanoly_olympia',
          name: 'Chanoly Signature Noodles',
          description: 'Hand-pulled Asian noodles in rich broth with scallions and soft egg.',
          price: 778.0,
          imageUrl: AppAssets.ramenBowl,
          category: 'Noodles',
        ),
      ],
    ),

    // 2. Injoy Burger (Meskel Flower) - Matching Screenshot Special Offers
    const Store(
      id: 'rest_injoy_burger',
      name: 'Injoy Burger',
      branch: 'Meskel Flower',
      categoryDescription: 'Burgers • Fried Chicken • Fast Food',
      type: StoreType.restaurant,
      priceLevel: r'$$',
      rating: 4.9,
      reviewsCount: 880,
      deliveryTime: '25 min',
      deliveryFee: '110 Br',
      avgPricePerPerson: 678.0,
      deliveryFeeAmount: 110.0,
      minOrder: 200.0,
      distanceKm: 1.5,
      latitude: 9.0012,
      longitude: 38.7610,
      heroImageUrl: AppAssets.burgerFeatured,
      isFeatured: true,
      badge: '25% OFF',
      categories: ['Popular', 'Burgers', 'Chicken', 'Drinks'],
      items: [
        DeliveryItem(
          id: 'item_jj_chicken',
          storeId: 'rest_injoy_burger',
          name: 'J&J Chicken',
          description: 'Crispy fried chicken breast fillet with melted cheese and fresh pickles.',
          price: 686.3,
          imageUrl: AppAssets.friedChicken,
          category: 'Chicken',
        ),
        DeliveryItem(
          id: 'item_cheese_burger',
          storeId: 'rest_injoy_burger',
          name: 'Cheese Burger',
          description: 'Flame-broiled beef patty with melted cheddar, crisp lettuce, and onion.',
          price: 678.8,
          imageUrl: AppAssets.burgerDetailHero,
          category: 'Burgers',
        ),
        DeliveryItem(
          id: 'item_joy_burger',
          storeId: 'rest_injoy_burger',
          name: 'Joy Burger',
          description: 'Double layer crunch burger with secret house sauce and tomato.',
          price: 798.8,
          imageUrl: AppAssets.classicBurgerItem,
          category: 'Burgers',
        ),
      ],
    ),

    // 3. TechHub Express (Electronics)
    const Store(
      id: 'store_techhub',
      name: 'TechHub Express',
      branch: 'Bole Medhanialem',
      categoryDescription: 'Electronics • Gadgets • Accessories',
      type: StoreType.electronics,
      priceLevel: r'$$$',
      rating: 4.9,
      reviewsCount: 920,
      deliveryTime: '20-30 min',
      deliveryFee: 'Free delivery',
      avgPricePerPerson: 1200.0,
      deliveryFeeAmount: 150.0,
      minOrder: 25.0,
      distanceKm: 1.1,
      latitude: 9.0210,
      longitude: 38.7850,
      heroImageUrl: AppAssets.electronicsHero,
      isFeatured: true,
      badge: "Editor's Pick",
      categories: ['Popular', 'Audio', 'Cables & Power', 'Accessories'],
      items: [
        ancEarbuds,
        fastChargingCable,
        powerBank,
        carMount,
      ],
    ),

    // 2. FreshMart Organics (Groceries)
    const Store(
      id: 'store_freshmart',
      name: 'FreshMart Organics',
      branch: 'Sarbet',
      categoryDescription: 'Groceries • Fresh Produce • Bakery',
      type: StoreType.grocery,
      priceLevel: r'$$',
      rating: 4.8,
      reviewsCount: 1450,
      deliveryTime: '25 min',
      deliveryFee: '90 Br',
      avgPricePerPerson: 450.0,
      deliveryFeeAmount: 90.0,
      minOrder: 15.0,
      distanceKm: 0.8,
      latitude: 8.9950,
      longitude: 38.7890,
      heroImageUrl: AppAssets.groceryHero,
      isFeatured: true,
      badge: 'Popular Grocery',
      categories: ['Popular', 'Produce', 'Bakery', 'Beverages'],
      items: [
        organicAvocados,
        sourdoughBread,
        coldPressedJuice,
        freshStrawberries,
        salmonPoke,
        icedMatcha,
      ],
    ),

    // 3. CareFirst Pharmacy (Health & Personal Care)
    const Store(
      id: 'store_carefirst',
      name: 'CareFirst Pharmacy',
      branch: 'Bole Atlas',
      categoryDescription: 'Pharmacy • Health • Personal Care',
      type: StoreType.pharmacy,
      priceLevel: r'$$',
      rating: 4.9,
      reviewsCount: 780,
      deliveryTime: '20 min',
      deliveryFee: '80 Br',
      avgPricePerPerson: 350.0,
      deliveryFeeAmount: 80.0,
      minOrder: 10.0,
      distanceKm: 0.6,
      latitude: 9.0010,
      longitude: 38.7360,
      heroImageUrl: AppAssets.pharmacyHero,
      badge: 'Top Rated',
      categories: ['Popular', 'Vitamins & Wellness', 'First Aid', 'Personal Care'],
      items: [
        vitaminC,
        firstAidKit,
        barrierHandCream,
      ],
    ),

    // 4. Burger Foundry (Food & Dining)
    const Store(
      id: 'rest_burger_foundry',
      name: 'Burger Foundry',
      branch: 'Kazanchis',
      categoryDescription: 'Gourmet Burgers • American • Comfort',
      type: StoreType.restaurant,
      priceLevel: r'$$',
      rating: 4.8,
      reviewsCount: 520,
      deliveryTime: '25 min',
      deliveryFee: '110 Br',
      avgPricePerPerson: 650.0,
      deliveryFeeAmount: 110.0,
      minOrder: 10.0,
      distanceKm: 1.2,
      latitude: 9.0150,
      longitude: 38.7600,
      heroImageUrl: AppAssets.burgerDetailHero,
      categories: ['Popular', 'Burgers', 'Sides', 'Drinks'],
      items: [
        foundryClassic,
        truffleParmFries,
        doubleChocShake,
        cheeseburgerCustomizable,
      ],
    ),

    // 5. Bloom & Petal Florist (Flowers & Gifts)
    const Store(
      id: 'store_bloom_petal',
      name: 'Bloom & Petal Florist',
      branch: 'Gerji',
      categoryDescription: 'Flowers • Bouquets • Gifts & Plants',
      type: StoreType.flowers,
      priceLevel: r'$$$',
      rating: 4.9,
      reviewsCount: 360,
      deliveryTime: '45 min',
      deliveryFee: '120 Br',
      avgPricePerPerson: 850.0,
      deliveryFeeAmount: 120.0,
      minOrder: 20.0,
      distanceKm: 2.3,
      latitude: 9.0100,
      longitude: 38.8000,
      heroImageUrl: AppAssets.flowersHero,
      badge: 'Fresh Blooms',
      categories: ['Popular', 'Bouquets', 'Gifts'],
      items: [
        pastelBouquet,
        lavenderCandle,
      ],
    ),

    // 6. Luigi\'s Woodfired Pizza (Food & Dining)
    const Store(
      id: 'rest_luigi_pizza',
      name: "Luigi's Woodfired Pizza",
      branch: 'Bole Rwanda',
      categoryDescription: 'Italian • Artisan Pizza • Gourmet',
      type: StoreType.restaurant,
      priceLevel: r'$$',
      rating: 4.9,
      reviewsCount: 840,
      deliveryTime: '30 min',
      deliveryFee: '130 Br',
      avgPricePerPerson: 720.0,
      deliveryFeeAmount: 130.0,
      minOrder: 15.0,
      distanceKm: 1.5,
      latitude: 8.9920,
      longitude: 38.7750,
      heroImageUrl: AppAssets.pizzaFeatured,
      categories: ['Popular', 'Pizza', 'Sides', 'Drinks'],
      items: [woodfiredPizza],
    ),

    // 7. Express Parcel Courier (Courier Service)
    const Store(
      id: 'store_express_courier',
      name: 'Express Parcel Courier',
      branch: 'Stadium',
      categoryDescription: 'Courier • On-Demand Package Delivery',
      type: StoreType.courier,
      priceLevel: r'$',
      rating: 4.7,
      reviewsCount: 610,
      deliveryTime: '25 min',
      deliveryFee: '95 Br',
      avgPricePerPerson: 200.0,
      deliveryFeeAmount: 95.0,
      minOrder: 5.0,
      distanceKm: 0.5,
      latitude: 9.0120,
      longitude: 38.7540,
      heroImageUrl: AppAssets.courierHero,
      badge: 'Fast Courier',
      categories: ['Popular', 'Courier'],
      items: [onDemandParcel],
    ),
  ];

  // Active Live Order (#AMN-8924 - Electronics order from TechHub Express)
  static final OrderModel activeOrder = OrderModel(
    orderId: '#AMN-8924',
    storeName: 'TechHub Express',
    storeImageUrl: AppAssets.earbudsItem,
    orderDate: DateTime.now().subtract(const Duration(minutes: 18)),
    storeType: StoreType.electronics,
    items: [
      CartItem(
        id: 'ci_1',
        item: ancEarbuds,
        quantity: 1,
        selectedVariant: 'Midnight Black',
        selectedAddons: [
          const CustomizationAddon(id: 'add_warranty', name: '2-Year Protection Plan', price: 14.99),
        ],
      ),
      CartItem(
        id: 'ci_2',
        item: fastChargingCable,
        quantity: 1,
        selectedVariant: '2 Meters',
      ),
    ],
    subtotal: 121.97,
    deliveryFee: 0.00,
    taxAndFees: 12.20,
    total: 134.17,
    deliveryAddress: 'Bole Olympia, Addis Ababa',
    status: OrderProgressStatus.onTheWay,
    estimatedArrival: '12 mins',
    storeLatitude: 9.0210,
    storeLongitude: 38.7850,
    deliveryLatitude: 9.0054,
    deliveryLongitude: 38.7636,
    driver: const DriverInfo(
      name: 'Alex M.',
      vehicle: 'Silver Honda Civic',
      plateNumber: 'ABC-123',
      rating: 4.9,
      photoUrl: AppAssets.driverAvatar,
      phone: '+251 911 382 912',
    ),
  );

  // Past Orders across different categories
  static final List<OrderModel> pastOrders = [
    OrderModel(
      orderId: '#AMN-7621',
      storeName: 'FreshMart Organics',
      storeImageUrl: AppAssets.groceryHero,
      orderDate: DateTime(2023, 10, 24),
      storeType: StoreType.grocery,
      items: [
        CartItem(id: 'p1', item: organicAvocados, quantity: 2),
        CartItem(id: 'p2', item: sourdoughBread, quantity: 1),
        CartItem(id: 'p3', item: coldPressedJuice, quantity: 2),
      ],
      subtotal: 30.98,
      deliveryFee: 0.00,
      taxAndFees: 3.10,
      total: 34.08,
      deliveryAddress: 'Meskel Flower, Addis Ababa',
      storeLatitude: 8.9950,
      storeLongitude: 38.7350,
      deliveryLatitude: 9.0120,
      deliveryLongitude: 38.7600,
      status: OrderProgressStatus.delivered,
      estimatedArrival: 'Delivered',
    ),
    OrderModel(
      orderId: '#AMN-6819',
      storeName: 'Burger Foundry',
      storeImageUrl: AppAssets.burgerDetailHero,
      orderDate: DateTime(2023, 10, 18),
      storeType: StoreType.restaurant,
      items: [
        CartItem(id: 'p4', item: foundryClassic, quantity: 1),
        CartItem(id: 'p5', item: truffleParmFries, quantity: 1),
      ],
      subtotal: 19.00,
      deliveryFee: 1.99,
      taxAndFees: 2.01,
      total: 23.00,
      deliveryAddress: 'Olympia, Addis Ababa',
      storeLatitude: 9.0120,
      storeLongitude: 38.7700,
      deliveryLatitude: 9.0054,
      deliveryLongitude: 38.7636,
      status: OrderProgressStatus.delivered,
      estimatedArrival: 'Delivered',
    ),
    OrderModel(
      orderId: '#AMN-5402',
      storeName: 'CareFirst Pharmacy',
      storeImageUrl: AppAssets.pharmacyHero,
      orderDate: DateTime(2023, 10, 12),
      storeType: StoreType.pharmacy,
      items: [
        CartItem(id: 'p6', item: vitaminC, quantity: 1),
        CartItem(id: 'p7', item: firstAidKit, quantity: 1),
      ],
      subtotal: 34.24,
      deliveryFee: 0.00,
      taxAndFees: 3.42,
      total: 37.66,
      deliveryAddress: 'Kazanchis, Addis Ababa',
      storeLatitude: 9.0150,
      storeLongitude: 38.7650,
      deliveryLatitude: 9.0280,
      deliveryLongitude: 38.7750,
      status: OrderProgressStatus.delivered,
      estimatedArrival: 'Delivered',
    ),
  ];

  // Curated Promotional Slider Banners (Top Carousel)
  static final List<Promotion> promotions = [
    const Promotion(
      id: 'promo_techhub',
      title: 'Mega Tech Drop',
      subtitle: 'Up to 40% OFF Pro ANC Earbuds & Fast Chargers',
      imageUrl: AppAssets.electronicsHero,
      badge: 'Tech Deal',
      storeId: 'store_techhub',
      discountText: 'USE: TECH40',
    ),
    const Promotion(
      id: 'promo_freshmart',
      title: 'Farm-Fresh Organics',
      subtitle: 'Free Delivery on Hass Avocados & Artisanal Breads',
      imageUrl: AppAssets.groceryHero,
      badge: 'Fresh Daily',
      storeId: 'store_freshmart',
      discountText: 'FREE DELIVERY',
    ),
    const Promotion(
      id: 'promo_burger',
      title: 'Gourmet Burger Duo',
      subtitle: 'Buy 1 Get 1 Free on Foundry Classics & Truffle Fries',
      imageUrl: AppAssets.burgerFeatured,
      badge: 'Hot Deal',
      storeId: 'rest_burger_foundry',
      discountText: 'BOGO FREE',
    ),
    const Promotion(
      id: 'promo_carefirst',
      title: 'Health & Wellness Rush',
      subtitle: 'Direct 20-Min Delivery for Vitamins & Medical Care',
      imageUrl: AppAssets.pharmacyHero,
      badge: '20-Min Express',
      storeId: 'store_carefirst',
      discountText: 'USE: HEALTH20',
    ),
    const Promotion(
      id: 'promo_luigi',
      title: 'Artisan Woodfired Pizza',
      subtitle: 'Hot Crispy Crusts Handcrafted with Fresh Mozzarella',
      imageUrl: AppAssets.pizzaFeatured,
      badge: "Chef's Choice",
      storeId: 'rest_luigi_pizza',
      discountText: '20% OFF SLICES',
    ),
  ];

  // Circular Categories matching Screenshot
  static final List<CircularCategory> circularCategories = [
    const CircularCategory(
      id: 'cat_ethiopost',
      name: 'Ethiopost',
      categoryKey: 'courier',
      icon: Icons.local_post_office_rounded,
      backgroundColor: Color(0xFFFEF3C7),
      iconColor: Color(0xFFD97706),
    ),
    const CircularCategory(
      id: 'cat_fasting',
      name: 'Fasting\nSpecials',
      categoryKey: 'fasting',
      icon: Icons.restaurant_rounded,
      backgroundColor: Color(0xFFE0F2FE),
      iconColor: Color(0xFF009EE0),
    ),
    const CircularCategory(
      id: 'cat_books',
      name: 'Books',
      categoryKey: 'books',
      icon: Icons.menu_book_rounded,
      backgroundColor: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0284C7),
    ),
    const CircularCategory(
      id: 'cat_breakfast',
      name: 'Breakfast\nFor You',
      categoryKey: 'breakfast',
      icon: Icons.free_breakfast_rounded,
      backgroundColor: Color(0xFFFEF9C3),
      iconColor: Color(0xFFCA8A04),
    ),
    const CircularCategory(
      id: 'cat_burgers',
      name: 'Burgers &\nFast Food',
      categoryKey: 'burger',
      icon: Icons.lunch_dining_rounded,
      backgroundColor: Color(0xFFFFE4E6),
      iconColor: Color(0xFFE11D48),
    ),
    const CircularCategory(
      id: 'cat_electronics',
      name: 'Electronics',
      categoryKey: 'electronics',
      icon: Icons.headphones_rounded,
      backgroundColor: Color(0xFFEDE9FE),
      iconColor: Color(0xFF7C3AED),
    ),
    const CircularCategory(
      id: 'cat_groceries',
      name: 'Groceries',
      categoryKey: 'grocery',
      icon: Icons.local_grocery_store_rounded,
      backgroundColor: Color(0xFFDCFCE7),
      iconColor: Color(0xFF16A34A),
    ),
    const CircularCategory(
      id: 'cat_pharmacy',
      name: 'Pharmacy',
      categoryKey: 'pharmacy',
      icon: Icons.medication_rounded,
      backgroundColor: Color(0xFFCCFBF1),
      iconColor: Color(0xFF0D9488),
    ),
  ];

  // Special Offers matching Screenshot
  static final List<SpecialOffer> specialOffers = [
    const SpecialOffer(
      id: 'so_jj_chicken',
      name: 'J&J Chicken',
      storeName: 'Injoy Burger',
      branchName: 'Meskel Flower',
      discountedPrice: 686.3,
      originalPrice: 915.00,
      discountPercent: 25.0,
      imageUrl: AppAssets.friedChicken,
      storeId: 'rest_injoy_burger',
    ),
    const SpecialOffer(
      id: 'so_cheese_burger',
      name: 'Cheese Burger',
      storeName: 'Injoy Burger',
      branchName: 'Meskel Flower',
      discountedPrice: 678.8,
      originalPrice: 905.00,
      discountPercent: 25.0,
      imageUrl: AppAssets.burgerDetailHero,
      storeId: 'rest_injoy_burger',
    ),
    const SpecialOffer(
      id: 'so_joy_burger',
      name: 'Joy Burger',
      storeName: 'Injoy Burger',
      branchName: 'Meskel Flower',
      discountedPrice: 798.8,
      originalPrice: 1065.00,
      discountPercent: 25.0,
      imageUrl: AppAssets.classicBurgerItem,
      storeId: 'rest_injoy_burger',
    ),
    const SpecialOffer(
      id: 'so_anc_earbuds',
      name: 'Pro ANC Earbuds',
      storeName: 'TechHub Express',
      branchName: 'Bole Medhanialem',
      discountedPrice: 910.0,
      originalPrice: 1300.00,
      discountPercent: 30.0,
      imageUrl: AppAssets.earbudsItem,
      storeId: 'store_techhub',
    ),
    const SpecialOffer(
      id: 'so_chanoly_noodles',
      name: 'Chanoly Signature Noodles',
      storeName: 'Chanoly Noodles',
      branchName: 'Olympia',
      discountedPrice: 622.4,
      originalPrice: 778.00,
      discountPercent: 20.0,
      imageUrl: AppAssets.ramenBowl,
      storeId: 'rest_chanoly_olympia',
    ),
    const SpecialOffer(
      id: 'so_fresh_avocado',
      name: 'Fresh Hass Avocados',
      storeName: 'FreshMart Organics',
      branchName: 'Sarbet',
      discountedPrice: 382.5,
      originalPrice: 450.00,
      discountPercent: 15.0,
      imageUrl: AppAssets.avocadoItem,
      storeId: 'store_freshmart',
    ),
  ];
}