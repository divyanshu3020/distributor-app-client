import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../models/product.dart';

class InventoryService extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final set = {'All'};
    for (var p in _products) {
      set.add(p.category);
    }
    return set.toList();
  }

  List<Product> get filteredProducts {
    if (_selectedCategory == 'All') {
      return _products;
    }
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  InventoryService() {
    loadProducts();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        final data = await sb.products
            .select()
            .order('category', ascending: true)
            .order('name', ascending: true);
        _products = (data as List).map((item) => Product.fromJson(item)).toList();
      } else {
        _products = _getFallbackCatalog();
      }
    } catch (e) {
      debugPrint('Error loading products from Supabase: $e');
      _products = _getFallbackCatalog();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStockQuantity({
    required String productId,
    required int newQuantity,
    required String reason,
    required bool isStaff,
  }) async {
    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        await sb.products
            .update({'stock_quantity': newQuantity})
            .eq('id', productId);
      }

      // Update local state
      final idx = _products.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        _products[idx] = _products[idx].copyWith(stockQuantity: newQuantity);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProductPriceAndSettings({
    required String productId,
    required double newUnitPrice,
    required int lowStockThreshold,
    required int perDistributorMaxCap,
    required int globalQueueCap,
    required int leadDays,
  }) async {
    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        await sb.products.update({
          'unit_price': newUnitPrice,
          'low_stock_threshold': lowStockThreshold,
          'per_distributor_max_cap': perDistributorMaxCap,
          'global_queue_cap': globalQueueCap,
          'production_lead_days_per_batch': leadDays,
        }).eq('id', productId);
      }

      final idx = _products.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        _products[idx] = _products[idx].copyWith(
          unitPrice: newUnitPrice,
          lowStockThreshold: lowStockThreshold,
          perDistributorMaxCap: perDistributorMaxCap,
          globalQueueCap: globalQueueCap,
          productionLeadDaysPerBatch: leadDays,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Product> _getFallbackCatalog() {
    return [
      Product(
        id: 'p-01',
        sku: 'BKT-005L-STD',
        name: '5 Litre Heavy Duty Virgin Bucket',
        category: 'Buckets & Mugs',
        description: 'Virgin polypropylene bucket with rust-free stainless steel handle.',
        unitPrice: 48.0,
        unitsPerPackage: 24,
        stockQuantity: 450,
        lowStockThreshold: 60,
        perDistributorMaxCap: 120,
        globalQueueCap: 1500,
        productionLeadDaysPerBatch: 2,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-02',
        sku: 'BKT-010L-DLX',
        name: '10 Litre Deluxe Printed Bucket',
        category: 'Buckets & Mugs',
        description: 'Floral in-mold labeling bathroom bucket with ergonomic grip handle.',
        unitPrice: 85.0,
        unitsPerPackage: 18,
        stockQuantity: 320,
        lowStockThreshold: 50,
        perDistributorMaxCap: 100,
        globalQueueCap: 1200,
        productionLeadDaysPerBatch: 2,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-03',
        sku: 'BKT-020L-IND',
        name: '20 Litre Industrial Heavy Duty Bucket',
        category: 'Buckets & Mugs',
        description: 'Extra thick wall construction suited for paint, construction, and chemical handling.',
        unitPrice: 145.0,
        unitsPerPackage: 12,
        stockQuantity: 25, // Below threshold (50) -> cap of 50 active
        lowStockThreshold: 50,
        perDistributorMaxCap: 50,
        globalQueueCap: 1000,
        productionLeadDaysPerBatch: 3,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-04',
        sku: 'BKT-025L-JMB',
        name: '25 Litre Jumbo Frost Finish Bucket',
        category: 'Buckets & Mugs',
        description: 'Jumbo capacity water storage bucket with durable plastic carrying handle.',
        unitPrice: 180.0,
        unitsPerPackage: 10,
        stockQuantity: 0, // Out of stock -> Made to order
        lowStockThreshold: 30,
        perDistributorMaxCap: 40,
        globalQueueCap: 800,
        productionLeadDaysPerBatch: 3,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-05',
        sku: 'MUG-001L-CLS',
        name: '1 Litre Classic Bath Mug (Pack of 12)',
        category: 'Buckets & Mugs',
        description: 'Smooth molded round bath mug with comfortable thumb rest.',
        unitPrice: 18.0,
        unitsPerPackage: 24,
        stockQuantity: 600,
        lowStockThreshold: 80,
        perDistributorMaxCap: 150,
        globalQueueCap: 2000,
        productionLeadDaysPerBatch: 1,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-06',
        sku: 'BSN-018R-HVY',
        name: '18" Heavy Rim Construction Basin',
        category: 'Basins & Tubs',
        description: 'Thickened outer rim for mortar, cement, and high-load civil tasks.',
        unitPrice: 72.0,
        unitsPerPackage: 20,
        stockQuantity: 12, // Low stock
        lowStockThreshold: 50,
        perDistributorMaxCap: 60,
        globalQueueCap: 1200,
        productionLeadDaysPerBatch: 2,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-07',
        sku: 'TUB-035L-FLX',
        name: '35 Litre Oval Washing Tub with Handles',
        category: 'Basins & Tubs',
        description: 'Dual ergonomic handles for effortless lifting of loaded clothes/water.',
        unitPrice: 175.0,
        unitsPerPackage: 10,
        stockQuantity: 95,
        lowStockThreshold: 30,
        perDistributorMaxCap: 50,
        globalQueueCap: 800,
        productionLeadDaysPerBatch: 3,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-08',
        sku: 'DRM-050L-IND',
        name: '50 Litre Blue Industrial Drum with Ring Lock',
        category: 'Industrial Storage',
        description: 'Full open top drum with galvanized steel clamping ring for chemical safety.',
        unitPrice: 520.0,
        unitsPerPackage: 2,
        stockQuantity: 8, // Low stock
        lowStockThreshold: 20,
        perDistributorMaxCap: 30,
        globalQueueCap: 400,
        productionLeadDaysPerBatch: 4,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-09',
        sku: 'DST-060L-FLP',
        name: '60 Litre Heavy Push-Flap Municipal Dustbin',
        category: 'Dustbins',
        description: 'High traffic waste bin suitable for factories, hotels, and schools.',
        unitPrice: 540.0,
        unitsPerPackage: 4,
        stockQuantity: 3, // Low stock
        lowStockThreshold: 15,
        perDistributorMaxCap: 25,
        globalQueueCap: 400,
        productionLeadDaysPerBatch: 3,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-10',
        sku: 'CHR-001M-RYL',
        name: 'Royal Plastic Arm Chair (Set of 2)',
        category: 'Furniture',
        description: 'Molded monobloc stackable arm chair with high backrest and 150kg load rating.',
        unitPrice: 450.0,
        unitsPerPackage: 2,
        stockQuantity: 220,
        lowStockThreshold: 30,
        perDistributorMaxCap: 50,
        globalQueueCap: 600,
        productionLeadDaysPerBatch: 3,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-11',
        sku: 'CRT-001P-VEG',
        name: 'Perforated Fruit & Veggie Crate (540x360x280mm)',
        category: 'Industrial Crates',
        description: 'Optimized airflow design with inter-stacking rails for agro logistics.',
        unitPrice: 290.0,
        unitsPerPackage: 6,
        stockQuantity: 420,
        lowStockThreshold: 50,
        perDistributorMaxCap: 100,
        globalQueueCap: 1500,
        productionLeadDaysPerBatch: 3,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'p-12',
        sku: 'WPR-018F-FLR',
        name: '18" Heavy Floor Wiper with Virgin Blade Frame',
        category: 'Household Accessories',
        description: 'Durable threaded socket wiper head fitting standard metal pipes.',
        unitPrice: 55.0,
        unitsPerPackage: 20,
        stockQuantity: 0, // Made to order
        lowStockThreshold: 40,
        perDistributorMaxCap: 80,
        globalQueueCap: 1200,
        productionLeadDaysPerBatch: 2,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
