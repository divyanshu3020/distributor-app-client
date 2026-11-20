import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../analytics/screens/admin_analytics_screen.dart';
import '../../announcements/screens/admin_announcements_screen.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../../dispatch_otp/screens/staff_dispatch_screen.dart';
import '../../inventory/screens/stock_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    StockManagementScreen(),
    StaffDispatchScreen(),
    AdminAnnouncementsScreen(),
    AdminAnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Super Admin Console'),
            Text(
              '${authService.currentProfile?.fullName ?? 'Owner'} • Full Access',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch User Role (Preview)',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _showRoleSwitchSheet(context),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory & Pricing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Dispatch Entry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  void _showRoleSwitchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Switch Active Preview Role',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: AppTheme.primaryDark),
              title: const Text('Super Admin (Owner)'),
              subtitle: const Text('Full catalog pricing, base fares, stock & analytics access'),
              onTap: () {
                context.read<AuthService>().switchDemoRole('super_admin');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined, color: AppTheme.primaryBlue),
              title: const Text('Restricted Staff (Accountant/Marketing)'),
              subtitle: const Text('Daily stock reconciliation & dispatch details only'),
              onTap: () {
                context.read<AuthService>().switchDemoRole('staff');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined, color: Color(0xFF16A34A)),
              title: const Text('B2B Distributor'),
              subtitle: const Text('Catalog, cart, freight tiers, quotes & arrival OTP'),
              onTap: () {
                context.read<AuthService>().switchDemoRole('distributor');
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
