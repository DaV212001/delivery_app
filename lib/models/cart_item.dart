import 'delivery_item.dart';

class CartItem {
  final String id;
  final DeliveryItem item;
  int quantity;
  final String? selectedVariant;
  final List<CustomizationAddon> selectedAddons;
  final List<String> removedOptions;
  final String? specialInstructions;

  CartItem({
    required this.id,
    required this.item,
    this.quantity = 1,
    String? selectedVariant,
    String? selectedTemperature,
    this.selectedAddons = const [],
    List<String> removedOptions = const [],
    List<String> removedIngredients = const [],
    this.specialInstructions,
  }) : selectedVariant = selectedVariant ?? selectedTemperature,
       removedOptions = removedOptions.isNotEmpty ? removedOptions : removedIngredients;

  // Backward-compatibility getters
  String? get selectedTemperature => selectedVariant;
  List<String> get removedIngredients => removedOptions;

  double get unitPrice {
    double total = item.price;
    for (final addon in selectedAddons) {
      total += addon.price;
    }
    return total;
  }

  double get totalPrice => unitPrice * quantity;

  String get customizationSummary {
    final parts = <String>[];
    if (selectedVariant != null) {
      parts.add(selectedVariant!);
    }
    for (final addon in selectedAddons) {
      parts.add('+ ${addon.name}');
    }
    for (final removed in removedOptions) {
      parts.add('No $removed');
    }
    return parts.join(', ');
  }
}

