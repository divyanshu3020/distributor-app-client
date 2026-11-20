import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../services/analytics_service.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsService>();
    final summary = analytics.summary;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Factory Analytics & Velocity'),
      ),
      body: analytics.isLoading || summary == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Revenue',
                          value: CurrencyFormatter.format(summary.totalRevenue, showDecimals: false),
                          icon: Icons.payments_outlined,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'B2B Orders',
                          value: '${summary.totalOrders}',
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Queue Load',
                          value: '${summary.pendingQueueUnits} units',
                          icon: Icons.precision_manufacturing_outlined,
                          color: const Color(0xFFD97706),
                          subtitle: 'Anti-Mountain Backlog',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Completed Trips',
                          value: '${summary.totalDispatches}',
                          icon: Icons.local_shipping_outlined,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Vehicle Allocation Breakdown
                  const Text(
                    'Vehicle Tier Dispatches',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      children: summary.vehicleBreakdown.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.circle, size: 8, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Text(
                                '${e.value} shipments',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Top Moving Products (Inventory Velocity)
                  const Text(
                    'Inventory Velocity (Top Moving Catalog Items)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.topProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final item = summary.topProducts[idx];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '#${idx + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.primaryDark),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item['packages']} pkgs (${item['units']} units)',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item['revenue'], showDecimals: false),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
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
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ],
      ),
    );
  }
}
