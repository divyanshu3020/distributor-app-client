class AppOrder {
  final String id;
  final String orderNumber;
  final String distributorId;
  final String status; // 'confirmed', 'in_production', 'packing', 'dispatched', 'delivered'
  final double subtotal;
  final String vehicleTierId;
  final String vehicleTierName;
  final double vehicleFare;
  final double taxAmount;
  final double grandTotal;
  final int totalPackages;
  final int totalUnits;
  final bool hasMadeToOrder;
  final DateTime estimatedDispatchDate;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final String? dispatchNotes;
  final DateTime createdAt;

  AppOrder({
    required this.id,
    required this.orderNumber,
    required this.distributorId,
    required this.status,
    required this.subtotal,
    required this.vehicleTierId,
    required this.vehicleTierName,
    required this.vehicleFare,
    required this.taxAmount,
    required this.grandTotal,
    required this.totalPackages,
    required this.totalUnits,
    required this.hasMadeToOrder,
    required this.estimatedDispatchDate,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    this.dispatchNotes,
    required this.createdAt,
  });

  factory AppOrder.fromJson(Map<String, dynamic> json) {
    return AppOrder(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? 'PO-${json['id']}',
      distributorId: json['distributor_id'] as String? ?? '',
      status: json['status'] as String? ?? 'confirmed',
      subtotal: (json['subtotal_approx'] as num?)?.toDouble() ?? 0.0,
      vehicleTierId: json['vehicle_tier_id'] as String? ?? 'truck',
      vehicleTierName: json['vehicle_tier_name'] as String? ?? 'Assigned Logistics Carrier',
      vehicleFare: (json['vehicle_fare_approx'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['total_approx'] as num?)?.toDouble() ?? 0.0,
      totalPackages: json['total_packages'] as int? ?? 1,
      totalUnits: json['total_units'] as int? ?? 1,
      hasMadeToOrder: json['has_made_to_order'] as bool? ?? false,
      estimatedDispatchDate: json['estimated_dispatch_date'] != null
          ? DateTime.parse(json['estimated_dispatch_date'] as String)
          : DateTime.now().add(const Duration(days: 2)),
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      dispatchNotes: json['dispatch_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
