import 'package:flutter/foundation.dart';

class AnalyticsSummary {
  final double totalRevenue;
  final int totalOrders;
  final int pendingQueueUnits;
  final int totalDispatches;
  final List<Map<String, dynamic>> topProducts;
  final Map<String, int> vehicleBreakdown;

  AnalyticsSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.pendingQueueUnits,
    required this.totalDispatches,
    required this.topProducts,
    required this.vehicleBreakdown,
  });
}

class AnalyticsService extends ChangeNotifier {
  AnalyticsSummary? _summary;
  bool _isLoading = false;

  AnalyticsSummary? get summary => _summary;
  bool get isLoading => _isLoading;

  AnalyticsService() {
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    _isLoading = true;
    notifyListeners();

    // Simulated analytical roll-up
    await Future.delayed(const Duration(milliseconds: 300));

    _summary = AnalyticsSummary(
      totalRevenue: 1485200.0,
      totalOrders: 42,
      pendingQueueUnits: 3450,
      totalDispatches: 38,
      topProducts: [
        {'name': '20L Industrial Heavy Duty Bucket', 'packages': 480, 'units': 5760, 'revenue': 835200.0},
        {'name': 'Perforated Fruit & Veggie Crate', 'packages': 320, 'units': 1920, 'revenue': 556800.0},
        {'name': '18" Heavy Rim Construction Basin', 'packages': 240, 'units': 4800, 'revenue': 345600.0},
        {'name': '10 Litre Deluxe Printed Bucket', 'packages': 180, 'units': 3240, 'revenue': 275400.0},
        {'name': 'Royal Plastic Arm Chair (Set of 2)', 'packages': 110, 'units': 220, 'revenue': 99000.0},
      ],
      vehicleBreakdown: {
        '14-17ft Full Body Truck': 18,
        'Mahindra Bolero Maxi / Pickup': 12,
        'Tata Ace / Small Tempo': 8,
        '3-Wheeler Auto / E-Loader': 4,
      },
    );

    _isLoading = false;
    notifyListeners();
  }
}
