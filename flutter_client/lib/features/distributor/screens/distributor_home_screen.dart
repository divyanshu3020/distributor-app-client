import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../announcements/screens/announcements_feed_screen.dart';
import '../../auth_rbac/services/auth_service.dart';
import '../../inventory/screens/catalog_screen.dart';
import '../../inventory/services/inventory_service.dart';
import '../../notifications/screens/notification_center_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../ordering_vehicles/screens/cart_screen.dart';
import '../../ordering_vehicles/services/cart_service.dart';
import '../../quotes/screens/orders_quotes_screen.dart';
import '../../quotes/services/quote_service.dart';
import 'distributor_profile_screen.dart';

class DistributorHomeScreen extends StatefulWidget {
  const DistributorHomeScreen({super.key});

  @override
  State<DistributorHomeScreen> createState() => _DistributorHomeScreenState();
}

class _DistributorHomeScreenState extends State<DistributorHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartService = context.watch<CartService>();
    final notifService = context.watch<NotificationService>();
    final authService = context.watch<AuthService>();
    final inventoryService = context.read<InventoryService>();
    final quoteService = context.read<QuoteService>();
    final profile = authService.currentProfile;

    final screens = [
      const CatalogScreen(),
      const CartScreen(),
      const OrdersQuotesScreen(),
      const AnnouncementsFeedScreen(),
      DistributorProfileScreen(
        onNavigateTab: (index) => setState(() => _currentIndex = index),
      ),
    ];

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
          // 1. Refresh Button
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              inventoryService.loadProducts();
              if (profile?.id != null) {
                quoteService.loadAll(profile!.id);
                notifService.loadNotifications(profile.id);
              }
            },
          ),
          // 2. Alerts with Unread Badge moved to top bar
          IconButton(
            tooltip: 'Alerts & Notifications',
            icon: Badge(
              isLabelVisible: notifService.unreadCount > 0,
              backgroundColor: const Color(0xFFDC2626),
              label: Text('${notifService.unreadCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
              );
            },
          ),
          // 3. Switch Preview Role
          IconButton(
            tooltip: 'Switch Preview Role',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _showRoleSwitchSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            color: const Color(0xFFFEF3C7),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 13, color: Color(0xFFB45309)),
                SizedBox(width: 6),
                Text(
                  'Demo Evaluation Build — Trial access valid until Nov 30, 2026',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: screens[_currentIndex]),
        ],
      ),
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
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Updates',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
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
