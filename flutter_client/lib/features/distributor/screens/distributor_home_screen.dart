import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../announcements/screens/announcements_feed_screen.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../../inventory/screens/catalog_screen.dart';
import '../../notifications/screens/notification_center_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../ordering_vehicles/screens/cart_screen.dart';
import '../../ordering_vehicles/services/cart_service.dart';
import '../../quotes/screens/quotes_list_screen.dart';

class DistributorHomeScreen extends StatefulWidget {
  const DistributorHomeScreen({super.key});

  @override
  State<DistributorHomeScreen> createState() => _DistributorHomeScreenState();
}

class _DistributorHomeScreenState extends State<DistributorHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CatalogScreen(),
    CartScreen(),
    QuotesListScreen(),
    AnnouncementsFeedScreen(),
    NotificationCenterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartService = context.watch<CartService>();
    final notifService = context.watch<NotificationService>();
    final authService = context.watch<AuthService>();
    final profile = authService.currentProfile;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile?.businessName ?? 'Bhagwati Plastics',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              'Distributor: ${profile?.fullName ?? 'Valued Partner'}',
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0C831F),
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Catalog',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: cartService.itemCount > 0,
                backgroundColor: const Color(0xFF0C831F),
                label: Text('${cartService.itemCount}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: cartService.itemCount > 0,
                backgroundColor: const Color(0xFF0C831F),
                label: Text('${cartService.itemCount}'),
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Quotes',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Updates',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: notifService.unreadCount > 0,
                backgroundColor: const Color(0xFFDC2626),
                label: Text('${notifService.unreadCount}'),
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: notifService.unreadCount > 0,
                backgroundColor: const Color(0xFFDC2626),
                label: Text('${notifService.unreadCount}'),
                child: const Icon(Icons.notifications),
              ),
              label: 'Alerts',
            ),
          ],
        ),
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
