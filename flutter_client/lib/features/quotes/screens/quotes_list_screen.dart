import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../../dispatch_otp/screens/delivery_handshake_screen.dart';
import '../services/quote_service.dart';
import 'quote_detail_screen.dart';

class QuotesListScreen extends StatefulWidget {
  const QuotesListScreen({super.key});

  @override
  State<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends State<QuotesListScreen> {
  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthService>().currentProfile;
    if (profile != null) {
      context.read<QuoteService>().loadDistributorQuotes(profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quoteService = context.watch<QuoteService>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Orders & Quotations'),
      ),
      body: quoteService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : quoteService.quotes.isEmpty
              ? const Center(
                  child: Text('No orders or quotations placed yet.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: quoteService.quotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final q = quoteService.quotes[idx];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                q.quoteNumber,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              const StatusBadge(status: 'confirmed'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Order Ref: #${q.orderId} • ${DateFormatter.formatDate(q.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Grand Total:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  Text(
                                    CurrencyFormatter.format(q.grandTotal),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryDark),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => QuoteDetailScreen(
                                            orderId: q.orderId,
                                            orderNumber: q.orderId,
                                            grandTotal: q.grandTotal,
                                            vehicleTier: 'Assigned Truck',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.near_me, color: Color(0xFF15803D)),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => DeliveryHandshakeScreen(
                                            orderId: q.orderId,
                                            orderNumber: q.orderId,
                                          ),
                                        ),
                                      );
                                    },
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
    );
  }
}
