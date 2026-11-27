import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/pricing_calculator.dart';
import '../../inventory/models/product.dart';
import '../models/cart_item.dart';

class VehiclePrediction {
  final String tierId;
  final String tierName;
  final double baseFare;
  final int minPackages;
  final int? maxPackages;
  final String description;
  final bool isTruck;

  VehiclePrediction({
    required this.tierId,
    required this.tierName,
    required this.baseFare,
    required this.minPackages,
    this.maxPackages,
    required this.description,
    this.isTruck = false,
  });
}

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  bool _isPlacingOrder = false;
  String? _orderError;

  Map<String, CartItem> get items => _items;
  List<CartItem> get itemList => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;
  bool get isPlacingOrder => _isPlacingOrder;
  String? get orderError => _orderError;

  int get totalPackages {
    return _items.values.fold(0, (sum, item) => sum + item.packages);
  }

  int get totalUnits {
    return _items.values.fold(0, (sum, item) => sum + item.totalUnits);
  }

  double get subtotalApprox {
    return _items.values.fold(0.0, (sum, item) => sum + item.subtotalApprox);
  }

  bool get hasMadeToOrder {
    return _items.values.any((item) => item.isMadeToOrder);
  }

  // Dynamic dispatch calculation
  DateTime get estimatedDispatchDate {
    final now = DateTime.now();
    if (!hasMadeToOrder) {
      return now.add(const Duration(days: 1)); // Ready stock standard packing
    }
    // Dynamic factory queue lead time:
    // Base 2 days + 1 extra day for every 200 units ordered
    final queueExtensionDays = (totalUnits / 200).floor();
    final totalLeadDays = 2 + queueExtensionDays;
    return now.add(Duration(days: totalLeadDays));
  }

  // Vehicle prediction strictly based on package counts
  VehiclePrediction get predictedVehicle {
    final pkgs = totalPackages;
    if (pkgs <= 25) {
      return VehiclePrediction(
        tierId: 'auto',
        tierName: '3-Wheeler Auto / E-Loader',
        baseFare: 350.0,
        minPackages: 1,
        maxPackages: 25,
        description: 'Local small sample delivery (1 to 25 packages).',
        isTruck: false,
      );
    } else if (pkgs <= 60) {
      return VehiclePrediction(
        tierId: 'tempo',
        tierName: 'Tata Ace / Small Tempo (Chota Hathi)',
        baseFare: 850.0,
        minPackages: 26,
        maxPackages: 60,
        description: 'Standard urban delivery carrier (26 to 60 packages).',
        isTruck: false,
      );
    } else if (pkgs <= 100) {
      return VehiclePrediction(
        tierId: 'mini_truck',
        tierName: 'Mahindra Bolero Maxi / 8-10ft Pickup',
        baseFare: 1600.0,
        minPackages: 61,
        maxPackages: 100,
        description: 'Medium regional delivery vehicle (61 to 100 packages).',
        isTruck: false,
      );
    } else if (pkgs <= 220) {
      // >100 packages triggers full truck tier
      return VehiclePrediction(
        tierId: 'truck',
        tierName: '14-17ft Full Body Truck',
        baseFare: 3200.0,
        minPackages: 101,
        maxPackages: 220,
        description: 'Dedicated heavy commercial truck (>100 packages up to 220 packages).',
        isTruck: true,
      );
    } else {
      return VehiclePrediction(
        tierId: 'heavy_truck',
        tierName: '20ft+ Multi-Axle Industrial Container',
        baseFare: 5800.0,
        minPackages: 221,
        maxPackages: null,
        description: 'Interstate high-volume bulk shipping (221+ packages).',
        isTruck: true,
      );
    }
  }

  double get approxDeliveryFare => predictedVehicle.baseFare;

  PricingBreakdown get pricing => PricingCalculator.compute(
        subtotal: subtotalApprox,
        vehicleFare: approxDeliveryFare,
      );

  double get grandTotalApprox => pricing.grandTotal;

  void addItem(Product product, int packages) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.packages += packages;
    } else {
      _items[product.id] = CartItem(product: product, packages: packages);
    }
    notifyListeners();
  }

  void updatePackages(String productId, int packages) {
    if (_items.containsKey(productId)) {
      if (packages <= 0) {
        _items.remove(productId);
      } else {
        _items[productId]!.packages = packages;
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Validate threshold caps before order confirmation
  List<String> validateCaps() {
    final violations = <String>[];
    for (var item in _items.values) {
      if (item.product.isBelowThreshold &&
          item.packages > item.product.perDistributorMaxCap) {
        violations.add(
          '${item.product.name}: Max cap of ${item.product.perDistributorMaxCap} packages per distributor applies due to low stock (selected: ${item.packages} packages).',
        );
      }
    }
    return violations;
  }

  Future<Map<String, dynamic>?> placeOrder({
    required String distributorId,
    String? deliveryNotes,
  }) async {
    final capErrors = validateCaps();
    if (capErrors.isNotEmpty) {
      _orderError = capErrors.first;
      notifyListeners();
      return null;
    }

    _isPlacingOrder = true;
    _orderError = null;
    notifyListeners();

    final vehicle = predictedVehicle;
    final now = DateTime.now();
    final orderNumber = 'PO-${now.year}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    final quoteNumber = 'QT-${now.year}${now.month.toString().padLeft(2, '0')}-${orderNumber.replaceAll(RegExp(r'\D'), '').padLeft(4, '0')}';

    // 1. Snapshot calculations BEFORE cart is cleared!
    final pricingSnapshot = pricing;
    final packagesSnapshot = totalPackages;
    final unitsSnapshot = totalUnits;
    final vehicleTierNameSnapshot = vehicle.tierName;
    final vehicleTierIdSnapshot = vehicle.tierId;
    final hasMadeToOrderSnapshot = hasMadeToOrder;
    final estimatedDispatchSnapshot = estimatedDispatchDate;
    final cartItemsSnapshot = List<CartItem>.from(_items.values);

    try {
      final sb = SupabaseService.instance;

      final orderPayload = {
        'order_number': orderNumber,
        'distributor_id': distributorId,
        'status': 'confirmed',
        'subtotal_approx': pricingSnapshot.subtotal,
        'vehicle_tier_id': vehicleTierIdSnapshot,
        'vehicle_fare_approx': pricingSnapshot.vehicleFare,
        'tax_amount': pricingSnapshot.taxAmount,
        'total_approx': pricingSnapshot.grandTotal,
        'total_packages': packagesSnapshot,
        'total_units': unitsSnapshot,
        'has_made_to_order': hasMadeToOrderSnapshot,
        'estimated_dispatch_date': estimatedDispatchSnapshot.toIso8601String(),
        'dispatch_notes': deliveryNotes,
      };

      String orderId = 'PO-${now.millisecondsSinceEpoch}';

      if (sb.isInitialized) {
        try {
          final orderRes = await sb.orders.insert(orderPayload).select().single();
          orderId = orderRes['id'];

          // Insert items
          final itemsToInsert = cartItemsSnapshot.map((item) {
            return {
              'order_id': orderId,
              'product_id': item.product.id,
              'product_name': item.product.name,
              'unit_price': item.product.unitPrice,
              'units_per_package': item.product.unitsPerPackage,
              'quantity_packages': item.packages,
              'quantity_units': item.totalUnits,
              'total_price': item.subtotalApprox,
              'is_made_to_order': item.isMadeToOrder,
              'estimated_lead_days': item.isMadeToOrder ? item.product.productionLeadDaysPerBatch : 0,
            };
          }).toList();

          await sb.orderItems.insert(itemsToInsert);

          // Direct insert quotation record into database
          await sb.quotations.insert({
            'quote_number': quoteNumber,
            'order_id': orderId,
            'distributor_id': distributorId,
            'final_subtotal': pricingSnapshot.subtotal,
            'vehicle_fare': pricingSnapshot.vehicleFare,
            'tax_amount': pricingSnapshot.taxAmount,
            'grand_total': pricingSnapshot.grandTotal,
            'status': 'locked',
          });
        } catch (dbErr) {
          debugPrint('Supabase order insert note (falling back to offline quotation): $dbErr');
        }
      }

      final resultMap = {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'quoteNumber': quoteNumber,
        'subtotal': pricingSnapshot.subtotal,
        'vehicleFare': pricingSnapshot.vehicleFare,
        'taxAmount': pricingSnapshot.taxAmount,
        'grandTotal': pricingSnapshot.grandTotal,
        'total': pricingSnapshot.grandTotal,
        'vehicleTier': vehicleTierNameSnapshot,
        'totalPackages': packagesSnapshot,
        'totalUnits': unitsSnapshot,
        'estimatedDispatch': estimatedDispatchSnapshot,
      };

      // Now safe to clear cart
      clearCart();

      return resultMap;
    } catch (e) {
      _orderError = e.toString();
      debugPrint('Order placement error: $e');

      final fallbackMap = {
        'orderId': 'PO-${now.millisecondsSinceEpoch}',
        'orderNumber': orderNumber,
        'quoteNumber': quoteNumber,
        'subtotal': pricingSnapshot.subtotal,
        'vehicleFare': pricingSnapshot.vehicleFare,
        'taxAmount': pricingSnapshot.taxAmount,
        'grandTotal': pricingSnapshot.grandTotal,
        'total': pricingSnapshot.grandTotal,
        'vehicleTier': vehicleTierNameSnapshot,
        'totalPackages': packagesSnapshot,
        'totalUnits': unitsSnapshot,
        'estimatedDispatch': estimatedDispatchSnapshot,
      };

      clearCart();
      return fallbackMap;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }
}
