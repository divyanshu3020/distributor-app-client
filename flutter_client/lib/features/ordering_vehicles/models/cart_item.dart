import '../../inventory/models/product.dart';

class CartItem {
  final Product product;
  int packages;

  CartItem({
    required this.product,
    this.packages = 1,
  });

  int get totalUnits => packages * product.unitsPerPackage;
  double get subtotalApprox => totalUnits * product.unitPrice;
  bool get isMadeToOrder => totalUnits > product.stockQuantity;
  bool get isCapExceeded =>
      product.isBelowThreshold && packages > product.perDistributorMaxCap;
}
