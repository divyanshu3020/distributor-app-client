import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/approximate_badge.dart';
import '../../../core/widgets/top_toast.dart';
import '../../ordering_vehicles/screens/cart_screen.dart';
import '../../ordering_vehicles/services/cart_service.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Visual category helper (color & icon)
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Buckets & Mugs':
        return Icons.water_drop_outlined;
      case 'Basins & Tubs':
        return Icons.bathtub_outlined;
      case 'Industrial Storage':
        return Icons.inventory_2_outlined;
      case 'Industrial Crates':
        return Icons.all_inbox_outlined;
      case 'Dustbins':
        return Icons.delete_outline;
      case 'Furniture':
        return Icons.chair_outlined;
      case 'Kitchen Storage':
        return Icons.kitchen_outlined;
      case 'Household Accessories':
        return Icons.home_repair_service_outlined;
      case 'Packaging & Caps':
        return Icons.local_drink_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Buckets & Mugs':
        return const Color(0xFFE0F2FE);
      case 'Basins & Tubs':
        return const Color(0xFFE0E7FF);
      case 'Industrial Storage':
        return const Color(0xFFFEF3C7);
      case 'Industrial Crates':
        return const Color(0xFFDCFCE7);
      case 'Dustbins':
        return const Color(0xFFFEE2E2);
      case 'Furniture':
        return const Color(0xFFF3E8FF);
      case 'Kitchen Storage':
        return const Color(0xFFFFEDD5);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  void _showNotificationSnackBar(BuildContext context, String message, {bool isError = false}) {
    TopToast.show(context, message: message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = context.watch<InventoryService>();
    final cartService = context.watch<CartService>();

    final products = inventoryService.filteredProducts.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Color(0xFF475569)),
            onPressed: () => inventoryService.loadProducts(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Clean Search Bar (Blinkit style)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Search buckets, drums, crates...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel, size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Horizontal Category Filter Pills
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: inventoryService.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = inventoryService.categories[idx];
                      final isSelected = inventoryService.selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => inventoryService.setCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0C831F) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0C831F) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Product Grid (2-Column Blinkit style)
              Expanded(
                child: inventoryService.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF0C831F)),
                      )
                    : products.isEmpty
                        ? const Center(
                            child: Text(
                              'No products found matching your search.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              12,
                              12,
                              cartService.totalPackages > 0 ? 90 : 20,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.64,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, idx) {
                              final product = products[idx];
                              return _buildProductCard(context, product, cartService);
                            },
                          ),
              ),
            ],
          ),

          // Floating Bottom Cart Bar (Blinkit / Zepto style)
          if (cartService.totalPackages > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: _buildFloatingCartBar(context, cartService),
            ),
        ],
      ),
    );
  }

  // 2-Column Product Card
  Widget _buildProductCard(BuildContext context, Product product, CartService cartService) {
    final qty = cartService.items[product.id]?.packages ?? 0;
    final catColor = _getCategoryColor(product.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tap Area: Image + Badges (Opens Bottom Sheet Modal)
          GestureDetector(
            onTap: () => _showProductDetailsModal(context, product, cartService),
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.4),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getCategoryIcon(product.category),
                      size: 48,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  // Cap or Made to Order badge on image
                  if (product.isMadeToOrder)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: const Text(
                          'Backorder',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ),
                  if (product.isBelowThreshold)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Max ${product.perDistributorMaxCap}p',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Details Section (No text overflow!)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showProductDetailsModal(context, product, cartService),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Packaging unit tag
                        Text(
                          '${product.unitsPerPackage} pcs / pkg',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Title with ellipsis
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Pricing & Blinkit Style ADD Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Price
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${product.unitPrice.toStringAsFixed(0)}/pc',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '₹${product.packagePrice.toStringAsFixed(0)}/pkg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Blinkit ADD Button / [- qty +]
                      _buildAddButton(context, product, cartService, qty),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Blinkit / Zepto Style ADD & Quantity Stepper
  Widget _buildAddButton(
    BuildContext context,
    Product product,
    CartService cartService,
    int qty, {
    bool isLarge = false,
  }) {
    if (qty == 0) {
      return InkWell(
        onTap: () {
          cartService.addItem(product, 1);
          _showNotificationSnackBar(context, 'Added ${product.name} to cart');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 24 : 12,
            vertical: isLarge ? 10 : 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0C831F), width: 1.5),
          ),
          child: Text(
            'ADD',
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0C831F),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C831F),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 8 : 4,
        vertical: isLarge ? 4 : 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus
          InkWell(
            onTap: () {
              cartService.updatePackages(product.id, qty - 1);
            },
            child: Padding(
              padding: EdgeInsets.all(isLarge ? 6 : 2),
              child: Icon(Icons.remove, size: isLarge ? 18 : 14, color: Colors.white),
            ),
          ),
          // Qty
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isLarge ? 12 : 6),
            child: Text(
              '$qty',
              style: TextStyle(
                fontSize: isLarge ? 14 : 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          // Plus
          InkWell(
            onTap: () {
              if (product.isBelowThreshold && (qty + 1) > product.perDistributorMaxCap) {
                _showNotificationSnackBar(
                  context,
                  'Max cap of ${product.perDistributorMaxCap} packages per distributor applies.',
                  isError: true,
                );
                return;
              }
              cartService.updatePackages(product.id, qty + 1);
            },
            child: Padding(
              padding: EdgeInsets.all(isLarge ? 6 : 2),
              child: Icon(Icons.add, size: isLarge ? 18 : 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Blinkit Style Product Details Overlay (Modal Bottom Sheet)
  void _showProductDetailsModal(
    BuildContext context,
    Product product,
    CartService cartService,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<CartService>(
          builder: (modalContext, liveCartService, child) {
            final currentQty = liveCartService.items[product.id]?.packages ?? 0;
            final catColor = _getCategoryColor(product.category);

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header with Close
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.sku,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Modal Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Large visual preview
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                _getCategoryIcon(product.category),
                                size: 80,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Badges Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (product.isMadeToOrder)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Made to Order',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              if (product.isBelowThreshold) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Max Cap: ${product.perDistributorMaxCap} pkgs',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Name
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Description
                          Text(
                            product.description ??
                                'Durable virgin polymer molded for heavy duty commercial and domestic utility.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Specifications Grid
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                _buildSpecRow('Standard Packaging', '${product.unitsPerPackage} pieces per package'),
                                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                                _buildSpecRow('Unit Price (Approx)', CurrencyFormatter.formatApprox(product.unitPrice)),
                                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                                _buildSpecRow('Package Price', CurrencyFormatter.formatApprox(product.packagePrice)),
                                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                                _buildSpecRow('Batch Lead Time', '${product.productionLeadDaysPerBatch} working days'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar inside Modal
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Package Price',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            Text(
                              CurrencyFormatter.formatApprox(product.packagePrice),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        _buildAddButton(
                          context,
                          product,
                          liveCartService,
                          currentQty,
                          isLarge: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  // Floating Bottom Cart Bar (Blinkit / Zepto)
  Widget _buildFloatingCartBar(BuildContext context, CartService cartService) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C831F),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C831F).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cartService.totalPackages} ${cartService.totalPackages == 1 ? 'Package' : 'Packages'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatApprox(cartService.grandTotalApprox),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: const [
                Text(
                  'View Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 13),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
