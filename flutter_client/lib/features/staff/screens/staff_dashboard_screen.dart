import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../../dispatch_otp/screens/staff_dispatch_screen.dart';
import '../../inventory/screens/stock_management_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    StockManagementScreen(),
    StaffDispatchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staff Operations Portal'),
            Text(
              '${authService.currentProfile?.fullName ?? 'Staff'} • Restricted Access',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Preview Role',
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
            icon: Icon(Icons.checklist_rtl_outlined),
            activeIcon: Icon(Icons.checklist_rtl),
            label: 'Stock Reconciliation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Dispatch Entry',
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
