import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../../dispatch_otp/screens/delivery_handshake_screen.dart';
import '../services/quote_service.dart';
import 'quote_detail_screen.dart';

class OrdersQuotesScreen extends StatefulWidget {
  final int initialTabIndex;

  const OrdersQuotesScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<OrdersQuotesScreen> createState() => _OrdersQuotesScreenState();
}

class _OrdersQuotesScreenState extends State<OrdersQuotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    final profile = context.read<AuthService>().currentProfile;
    if (profile != null) {
      context.read<QuoteService>().loadAll(profile.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quoteService = context.watch<QuoteService>();
    final authService = context.watch<AuthService>();
    final profile = authService.currentProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Orders & Quotations',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0C831F),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.local_shipping_outlined, size: 20),
              text: 'My Orders (${quoteService.orders.length})',
            ),
            Tab(
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
              text: 'Quotation History (${quoteService.quotes.length})',
            ),
          ],
        ),
      ),
      body: quoteService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(context, quoteService, profile?.id),
                _buildQuotesTab(context, quoteService, profile),
              ],
            ),
    );
  }

  // --- TAB 1: ORDERS & HANDSHAKE ---
  Widget _buildOrdersTab(BuildContext context, QuoteService quoteService, String? distributorId) {
    if (quoteService.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            const Text(
              'No Orders Placed Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add products from the catalog and confirm your order.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (distributorId != null) {
          await quoteService.loadDistributorOrders(distributorId);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: quoteService.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final order = quoteService.orders[index];
          final isDispatched = order.status.toLowerCase() == 'dispatched';
          final isDelivered = order.status.toLowerCase() == 'delivered';

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDispatched ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                width: isDispatched ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDispatched
                      ? const Color(0xFF16A34A).withOpacity(0.08)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.formatDate(order.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      StatusBadge(status: order.status),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Logistics & Vehicle Row
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Image.asset(
                          QuoteService.getVehicleAsset(order.vehicleTierName),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_shipping,
                            size: 24,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.vehicleTierName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.totalPackages} pkgs (${order.totalUnits} pieces)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              'Dispatch: ${DateFormatter.formatDate(order.estimatedDispatchDate)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                          Text(
                            CurrencyFormatter.format(order.grandTotal),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Driver Banner if Dispatched
                if (isDispatched && order.driverName != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    color: const Color(0xFFF0FDF4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin_circle, size: 18, color: Color(0xFF15803D)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Driver: ${order.driverName} (${order.driverPhone ?? "N/A"}) • ${order.vehicleNumber ?? ""}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      // View Quotation
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QuoteDetailScreen(
                                  orderId: order.id,
                                  orderNumber: order.orderNumber,
                                  quoteNumber: 'QT-202611-${order.orderNumber.replaceAll(RegExp(r'\D'), '').padLeft(4, '0')}',
                                  subtotal: order.subtotal,
                                  vehicleFare: order.vehicleFare,
                                  taxAmount: order.taxAmount,
                                  grandTotal: order.grandTotal,
                                  vehicleTier: order.vehicleTierName,
                                  totalPackages: order.totalPackages,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt, size: 16),
                          label: const Text('View Quote', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryDark,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Handshake OTP
                      Expanded(
                        flex: isDispatched ? 2 : 1,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DeliveryHandshakeScreen(
                                  orderId: order.id,
                                  orderNumber: order.orderNumber,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            isDelivered ? Icons.verified : Icons.verified_user_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            isDelivered
                                ? 'Delivered'
                                : isDispatched
                                    ? '🤝 Delivery OTP Handshake'
                                    : 'Track Handshake',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDispatched
                                ? const Color(0xFF0C831F)
                                : AppTheme.primaryBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- TAB 2: QUOTATION HISTORY ---
  Widget _buildQuotesTab(BuildContext context, QuoteService quoteService, dynamic profile) {
    if (quoteService.quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            const Text(
              'No Quotations Available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Quotations are generated automatically when placing orders.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (profile?.id != null) {
          await quoteService.loadDistributorQuotes(profile.id);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: quoteService.quotes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final q = quoteService.quotes[index];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quote & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.quoteNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ref: #${q.orderId} • ${DateFormatter.formatDate(q.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LOCKED PRICING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Financial Breakdown Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBreakdownColumn('Goods Subtotal', CurrencyFormatter.format(q.finalSubtotal)),
                    _buildBreakdownColumn('Freight Fare', CurrencyFormatter.format(q.vehicleFare)),
                    _buildBreakdownColumn('GST (18%)', CurrencyFormatter.format(q.taxAmount)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        Text(
                          CurrencyFormatter.format(q.grandTotal),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0C831F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    // PDF Download
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          quoteService.generateAndPrintPdf(
                            quoteNumber: q.quoteNumber,
                            orderNumber: q.orderId,
                            distributorName: profile?.businessName ?? profile?.fullName ?? 'Distributor',
                            distributorGst: profile?.gstNumber,
                            distributorAddress: profile?.address,
                            vehicleTier: 'Assigned Logistics Carrier',
                            subtotal: q.finalSubtotal,
                            vehicleFare: q.vehicleFare,
                            taxAmount: q.taxAmount,
                            grandTotal: q.grandTotal,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                        label: const Text('Download PDF', style: TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2942),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // View Details
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuoteDetailScreen(
                                orderId: q.orderId,
                                orderNumber: q.orderId,
                                quoteNumber: q.quoteNumber,
                                subtotal: q.finalSubtotal,
                                vehicleFare: q.vehicleFare,
                                taxAmount: q.taxAmount,
                                grandTotal: q.grandTotal,
                                vehicleTier: 'Assigned Logistics Carrier',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View Quotation', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryDark,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreakdownColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
      ],
    );
  }
}
