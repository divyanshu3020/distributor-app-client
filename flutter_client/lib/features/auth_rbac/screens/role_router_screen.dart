import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../distributor/screens/distributor_home_screen.dart';
import '../../staff/screens/staff_dashboard_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RoleRouterScreen extends StatelessWidget {
  const RoleRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentAmber),
        ),
      );
    }

    if (!authService.isAuthenticated || authService.currentProfile == null) {
      return const LoginScreen();
    }

    final role = authService.currentProfile!.role;
    switch (role) {
      case 'super_admin':
        return const AdminDashboardScreen();
      case 'staff':
        return const StaffDashboardScreen();
      case 'distributor':
      default:
        return const DistributorHomeScreen();
    }
  }
}
