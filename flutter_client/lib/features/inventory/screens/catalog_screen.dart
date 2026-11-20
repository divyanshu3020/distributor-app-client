import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/approximate_badge.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import 'product_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final inventoryService = context.watch<InventoryService>();
    final products = inventoryService.filteredProducts.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => inventoryService.loadProducts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: AppTheme.surfaceWhite,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search products by name or SKU...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                // Categories Horizontal Scroll
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: inventoryService.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = inventoryService.categories[idx];
                      final isSelected = inventoryService.selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => inventoryService.setCategory(cat),
                        selectedColor: AppTheme.primaryDark,
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textMain,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Operational Policy Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFEFF6FF),
            child: const Row(
              children: [
                Icon(Icons.precision_manufacturing_outlined, size: 16, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Direct Factory Catalog: All items open for ordering with dynamic dispatch queueing.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),

          // Catalog List
          Expanded(
            child: inventoryService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found matching your search.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final product = products[idx];
                          return _buildProductCard(context, product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    // Strictly adheres to Rule 2: NO green/red stock indicators.
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Category & SKU
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  product.sku,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Product Title
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),

            // Packaging Specification & Units per package
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Standard Packaging: ${product.unitsPerPackage} units / package',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Badges: Made to Order / Threshold Cap Warning
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (product.isMadeToOrder)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.build_circle_outlined, size: 12, color: Color(0xFFD97706)),
                        SizedBox(width: 4),
                        Text(
                          'Made to Order / Backorder',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (product.isBelowThreshold)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 12, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Text(
                          'Max Cap: ${product.perDistributorMaxCap} pkgs/order',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.borderSubtle, height: 1),
            const SizedBox(height: 10),

            // Pricing Row: Approximate Badge + Per Unit & Per Package Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ApproximateBadge(compact: true),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.formatApprox(product.unitPrice)} / piece',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Package Price',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                    Text(
                      CurrencyFormatter.formatApprox(product.packagePrice),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
