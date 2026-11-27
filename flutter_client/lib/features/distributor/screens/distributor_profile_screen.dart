import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../../notifications/screens/notification_center_screen.dart';
import '../../quotes/screens/orders_quotes_screen.dart';
import '../../quotes/services/quote_service.dart';

class DistributorProfileScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DistributorProfileScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final quoteService = context.watch<QuoteService>();
    final profile = authService.currentProfile;

    final businessName = profile?.businessName ?? 'Bhagwati Plastics & Polymers';
    final partnerName = profile?.fullName ?? 'Authorized Distributor Partner';
    final email = profile?.email ?? 'distributor@bhagwatiplastics.com';
    final phone = profile?.phoneNumber ?? '+91 98200 12345';
    final gstin = profile?.gstNumber ?? '27AABCU9603R1ZM';
    final address = profile?.address ?? 'Plot No. 42, GIDC Industrial Estate, Umbergaon, Gujarat - 396171';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Distributor Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  // Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2942),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F2942).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        businessName.isNotEmpty ? businessName.substring(0, 2).toUpperCase() : 'BP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Distributor: $partnerName',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Quick Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Active Orders', '${quoteService.orders.length}', const Color(0xFF0369A1)),
                      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                      _buildStatItem('Official Quotes', '${quoteService.quotes.length}', const Color(0xFF0C831F)),
                      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                      _buildStatItem('Account Tier', 'Priority B2B', const Color(0xFFD97706)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Business & Regulatory Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Company & Regulatory Compliance',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(Icons.assignment_ind_outlined, 'GST Identification No.', gstin),
                  _buildInfoTile(Icons.phone_outlined, 'Registered Phone', phone),
                  _buildInfoTile(Icons.email_outlined, 'Corporate Email', email),
                  _buildInfoTile(Icons.location_on_outlined, 'Factory Delivery Address', address),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Actions Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF0369A1), size: 20),
                    ),
                    title: const Text('My Orders & OTP Handshake', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Track vehicle allocation, dispatch status & driver OTP', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(2); // Switch to Orders & Quotes Tab (index 2)
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OrdersQuotesScreen(initialTabIndex: 0)),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF166534), size: 20),
                    ),
                    title: const Text('Quotation History & PDF Downloads', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('View locked factory quotes and print PDF invoices', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(2);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OrdersQuotesScreen(initialTabIndex: 1)),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: Color(0xFFDC2626), size: 20),
                    ),
                    title: const Text('Notification & Alerts Center', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Dispatch updates, low-stock threshold alerts', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Demo License & Developer Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commercial Evaluation License Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Authorized evaluation trial active until Nov 30, 2026. Protected under developer commercial rights.',
                          style: TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => authService.signOut(),
                icon: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 18),
                label: const Text(
                  'Sign Out of Distributor Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFFFEF2F2),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
