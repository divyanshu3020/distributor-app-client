import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/env.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/services/analytics_service.dart';
import 'features/announcements/services/announcement_service.dart';
import 'features/auth_rbac/screens/role_router_screen.dart';
import 'features/auth_rbac/services/auth_service.dart';
import 'features/dispatch_otp/services/dispatch_service.dart';
import 'features/inventory/services/inventory_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/ordering_vehicles/services/cart_service.dart';
import 'features/quotes/services/quote_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  await Env.init();

  // Initialize Supabase client
  await SupabaseService.instance.init();

  runApp(const BhagwatiDistributorApp());
}

class BhagwatiDistributorApp extends StatelessWidget {
  const BhagwatiDistributorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => InventoryService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => QuoteService()),
        ChangeNotifierProvider(create: (_) => DispatchService()),
        ChangeNotifierProvider(create: (_) => AnnouncementService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()),
      ],
      child: MaterialApp(
        title: 'Bhagwati Plastics B2B',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const RoleRouterScreen(),
      ),
    );
  }
}
