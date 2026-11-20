import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/approximate_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/vehicle_tier_card.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../../quotes/screens/quote_detail_screen.dart';
import '../services/cart_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = context.watch<CartService>();
    final authService = context.watch<AuthService>();
    final vehicle = cartService.predictedVehicle;

    if (cartService.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('Cart & Freight Preview'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your cart is currently empty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Browse the catalog to add standard package batches.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final capErrors = cartService.validateCaps();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Cart & Freight Preview'),
        actions: [
          TextButton(
            onPressed: () => cartService.clearCart(),
            child: const Text('Clear', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rule 3 Banner: Clear approximate estimate disclosure
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All cart totals and vehicle freight rates are Approximate Estimates. Official locked quotation is generated immediately upon order confirmation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cart Items Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${cartService.totalPackages} pkgs (${cartService.totalUnits} units)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Item Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartService.itemList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = cartService.itemList[idx];
                final isCapExceeded = item.isCapExceeded;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCapExceeded ? const Color(0xFFF87171) : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.alertRed),
                            onPressed: () => cartService.removeItem(item.product.id),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Made to Order badge or Ready stock
                      if (item.isMadeToOrder) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⚙️ Made to Order / Backorder',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      if (isCapExceeded) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '⚠️ Exceeds per-distributor cap of ${item.product.perDistributorMaxCap} packages.',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Stepper
                          Row(
                            children: [
                              _buildMiniStepperBtn(
                                icon: Icons.remove,
                                onTap: () => cartService.updatePackages(item.product.id, item.packages - 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${item.packages} pkgs',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                              _buildMiniStepperBtn(
                                icon: Icons.add,
                                onTap: () => cartService.updatePackages(item.product.id, item.packages + 1),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const ApproximateBadge(compact: true),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatApprox(item.subtotalApprox),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Live Auto-Predicted Vehicle Tier Card (Rule 4)
            const Text(
              'Automated Vehicle Assignment & Freight',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            VehicleTierCard(
              tierName: vehicle.tierName,
              totalPackages: cartService.totalPackages,
              approxFare: cartService.approxDeliveryFare,
              description: vehicle.description,
              isTruck: vehicle.isTruck,
            ),
            const SizedBox(height: 20),

            // Dynamic Dispatch Lead Time Card (Rule 2)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_available, color: AppTheme.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Dispatch Timeline',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        Text(
                          DateFormatter.formatDate(cartService.estimatedDispatchDate),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        Text(
                          cartService.hasMadeToOrder
                              ? 'Includes dynamic queue scheduling for Made-to-Order items.'
                              : 'Ready stock batch: packaged and loaded in 24 hours.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Approximate Cost Summary Box
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
                      const Text('Items Subtotal (Approx):', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      Text(
                        CurrencyFormatter.formatApprox(cartService.subtotalApprox),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Freight (${vehicle.tierName}):',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      Text(
                        CurrencyFormatter.formatApprox(cartService.approxDeliveryFare),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.borderSubtle),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Approximate Total:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          ApproximateBadge(compact: true),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.formatApprox(cartService.grandTotalApprox),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cap Errors Warning
            if (capErrors.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  capErrors.first,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Place Order Button (Generates Final Official Quote)
            CustomButton(
              text: 'Place Order & Lock Quote',
              icon: Icons.check_circle_outline,
              isLoading: cartService.isPlacingOrder,
              onPressed: capErrors.isNotEmpty
                  ? null
                  : () async {
                      final profile = authService.currentProfile;
                      final distributorId = profile?.id ?? '00000000-0000-0000-0000-000000000003';

                      final result = await cartService.placeOrder(
                        distributorId: distributorId,
                      );

                      if (result != null && context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => QuoteDetailScreen(
                              orderId: result['orderId'],
                              orderNumber: result['orderNumber'],
                              grandTotal: result['total'],
                              vehicleTier: result['vehicleTier'],
                            ),
                          ),
                        );
                      }
                    },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStepperBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppTheme.primaryDark),
        ),
      ),
    );
  }
}
