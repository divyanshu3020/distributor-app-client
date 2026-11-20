import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../../dispatch_otp/screens/delivery_handshake_screen.dart';
import '../services/quote_service.dart';

class QuoteDetailScreen extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final double grandTotal;
  final String vehicleTier;

  const QuoteDetailScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.grandTotal,
    required this.vehicleTier,
  });

  @override
  Widget build(BuildContext context) {
    final quoteService = context.watch<QuoteService>();
    final authService = context.watch<AuthService>();
    final profile = authService.currentProfile;

    // Derived values
    final subtotal = grandTotal / 1.18 * 0.94; // approximate breakdown for locked view
    final vehicleFare = grandTotal / 1.18 * 0.06;
    final taxAmount = grandTotal - (subtotal + vehicleFare);
    final quoteNumber = 'QT-202611-${orderNumber.replaceAll(RegExp(r'\D'), '').padLeft(4, '0')}';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Official Quotation'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success & Locked Status Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified, size: 48, color: Color(0xFF16A34A)),
                  const SizedBox(height: 8),
                  const Text(
                    'Order Confirmed & Quote Locked!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your official factory quotation has been generated with locked pricing and assigned freight.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quotation Paper Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice Meta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QUOTATION NO.',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                          ),
                          Text(
                            quoteNumber,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LOCKED PRICING',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.borderSubtle),
                  const SizedBox(height: 12),

                  // Distributor Info
                  const Text(
                    'Billed To (Distributor)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.businessName ?? profile?.fullName ?? 'Distributor Account',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if (profile?.gstNumber != null)
                    Text('GSTIN: ${profile!.gstNumber}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 16),

                  // Logistics Summary
                  const Text(
                    'Assigned Vehicle Allocation',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        vehicleTier,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.borderSubtle),
                  const SizedBox(height: 12),

                  // Table of Amounts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Goods Subtotal:', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      Text(CurrencyFormatter.format(subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Freight Base Allocation:', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      Text(CurrencyFormatter.format(vehicleFare), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST (18%):', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      Text(CurrencyFormatter.format(taxAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(thickness: 1.5, color: AppTheme.primaryDark),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                      ),
                      Text(
                        CurrencyFormatter.format(grandTotal),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Download PDF Button (Rule 3)
            CustomButton(
              text: 'Download / Print PDF Quotation',
              icon: Icons.picture_as_pdf,
              onPressed: () {
                quoteService.generateAndPrintPdf(
                  quoteNumber: quoteNumber,
                  orderNumber: orderNumber,
                  distributorName: profile?.businessName ?? profile?.fullName ?? 'Distributor',
                  distributorGst: profile?.gstNumber,
                  distributorAddress: profile?.address,
                  vehicleTier: vehicleTier,
                  subtotal: subtotal,
                  vehicleFare: vehicleFare,
                  taxAmount: taxAmount,
                  grandTotal: grandTotal,
                );
              },
            ),
            const SizedBox(height: 12),

            // Track Order & Delivery Button
            CustomButton(
              text: 'Track Order & Handshake',
              variant: ButtonVariant.outline,
              icon: Icons.track_changes,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DeliveryHandshakeScreen(
                      orderId: orderId,
                      orderNumber: orderNumber,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
