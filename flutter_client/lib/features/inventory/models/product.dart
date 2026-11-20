class Product {
  final String id;
  final String sku;
  final String name;
  final String category;
  final String? description;
  final double unitPrice;
  final int unitsPerPackage;
  final int stockQuantity;
  final int lowStockThreshold;
  final int perDistributorMaxCap;
  final int globalQueueCap;
  final int productionLeadDaysPerBatch;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    this.description,
    required this.unitPrice,
    required this.unitsPerPackage,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.perDistributorMaxCap,
    required this.globalQueueCap,
    required this.productionLeadDaysPerBatch,
    required this.isActive,
    this.imageUrl,
    required this.createdAt,
  });

  // Business Rules Helpers
  bool get isBelowThreshold => stockQuantity < lowStockThreshold;
  bool get isReadyStockAvailable => stockQuantity > 0;
  bool get isMadeToOrder => stockQuantity <= 0;

  double get packagePrice => unitPrice * unitsPerPackage;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      unitsPerPackage: json['units_per_package'] as int? ?? 1,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      lowStockThreshold: json['low_stock_threshold'] as int? ?? 50,
      perDistributorMaxCap: json['per_distributor_max_cap'] as int? ?? 100,
      globalQueueCap: json['global_queue_cap'] as int? ?? 1000,
      productionLeadDaysPerBatch: json['production_lead_days_per_batch'] as int? ?? 2,
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'category': category,
      'description': description,
      'unit_price': unitPrice,
      'units_per_package': unitsPerPackage,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'per_distributor_max_cap': perDistributorMaxCap,
      'global_queue_cap': globalQueueCap,
      'production_lead_days_per_batch': productionLeadDaysPerBatch,
      'is_active': isActive,
      'image_url': imageUrl,
    };
  }

  Product copyWith({
    String? name,
    String? category,
    String? description,
    double? unitPrice,
    int? unitsPerPackage,
    int? stockQuantity,
    int? lowStockThreshold,
    int? perDistributorMaxCap,
    int? globalQueueCap,
    int? productionLeadDaysPerBatch,
    bool? isActive,
    String? imageUrl,
  }) {
    return Product(
      id: id,
      sku: sku,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      perDistributorMaxCap: perDistributorMaxCap ?? this.perDistributorMaxCap,
      globalQueueCap: globalQueueCap ?? this.globalQueueCap,
      productionLeadDaysPerBatch: productionLeadDaysPerBatch ?? this.productionLeadDaysPerBatch,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }
}
