import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/approximate_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../ordering_vehicles/services/cart_service.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _packages = 5;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final totalUnits = _packages * product.unitsPerPackage;
    final approxTotal = totalUnits * product.unitPrice;

    final isCapExceeded = product.isBelowThreshold && _packages > product.perDistributorMaxCap;
    final isMadeToOrder = totalUnits > product.stockQuantity;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(product.sku),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Product Name
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            if (product.description != null) ...[
              Text(
                product.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pricing Specs Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ApproximateBadge(),
                      Text(
                        'SKU: ${product.sku}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Approx. Unit Price:',
                        style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                      ),
                      Text(
                        '${CurrencyFormatter.formatApprox(product.unitPrice)} / piece',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Standard Packaging:',
                        style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                      ),
                      Text(
                        '${product.unitsPerPackage} pieces / package',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Package Rate:',
                        style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                      ),
                      Text(
                        CurrencyFormatter.formatApprox(product.packagePrice),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Operational Threshold Cap Warning
            if (product.isBelowThreshold) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 20, color: Color(0xFFDC2626)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distributor Order Cap Active',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Due to high demand and factory scheduling, orders for this product are currently limited to a maximum of ${product.perDistributorMaxCap} packages per distributor.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Production Mode & Dynamic Dispatch Preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMadeToOrder ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMadeToOrder ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isMadeToOrder ? Icons.build_circle_outlined : Icons.check_circle_outline,
                    color: isMadeToOrder ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMadeToOrder ? 'Made to Order / Production Queue' : 'Ready Stock Dispatch',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isMadeToOrder ? const Color(0xFF92400E) : const Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMadeToOrder
                              ? 'Machine tooling setup: ~${product.productionLeadDaysPerBatch} to ${product.productionLeadDaysPerBatch + 2} business days estimated dispatch.'
                              : 'Immediate warehouse packing: estimated dispatch in 24 hours.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isMadeToOrder ? const Color(0xFFB45309) : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quantity Package Stepper
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Packages to Order',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildStepperButton(
                            icon: Icons.remove,
                            onTap: _packages > 1 ? () => setState(() => _packages--) : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Text(
                              '$_packages',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ),
                          _buildStepperButton(
                            icon: Icons.add,
                            onTap: () {
                              if (product.isBelowThreshold && _packages >= product.perDistributorMaxCap) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cannot exceed distributor cap of ${product.perDistributorMaxCap} packages.'),
                                    backgroundColor: AppTheme.alertRed,
                                  ),
                                );
                                return;
                              }
                              setState(() => _packages++);
                            },
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '= $totalUnits units',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain,
                            ),
                          ),
                          const Text(
                            '(Total Pieces)',
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Item Total Calculation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Item Subtotal:',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    ApproximateBadge(compact: true),
                  ],
                ),
                Text(
                  CurrencyFormatter.formatApprox(approxTotal),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Add to Cart Button
            CustomButton(
              text: isCapExceeded ? 'Exceeds Distributor Cap' : 'Add to Cart',
              icon: Icons.add_shopping_cart,
              onPressed: isCapExceeded
                  ? null
                  : () {
                      context.read<CartService>().addItem(product, _packages);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $_packages packages of ${product.name} to cart!'),
                          backgroundColor: AppTheme.successGreen,
                          action: SnackBarAction(
                            label: 'VIEW CART',
                            textColor: Colors.white,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: onTap == null ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: onTap == null ? const Color(0xFFCBD5E1) : AppTheme.primaryDark,
          ),
        ),
      ),
    );
  }
}
