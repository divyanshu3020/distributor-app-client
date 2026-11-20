import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'distributor@shreetraders.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final success = await authService.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success && authService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage!),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing_outlined,
                    size: 48,
                    color: AppTheme.accentAmber,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'BHAGWATI PLASTICS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Custom B2B Distributor & Operations Platform',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 32),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sign In to Your Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'distributor@business.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                          validator: (v) => (v == null || v.length < 6) ? 'Enter at least 6 characters' : null,
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Sign In',
                          isLoading: authService.isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 24),

                        // Quick Role Switcher for seamless evaluation & review
                        const Divider(),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Quick Demo Role Switching (RBAC Preview)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleChip(
                                label: 'Super Admin',
                                icon: Icons.admin_panel_settings,
                                onTap: () {
                                  _emailController.text = 'owner@bhagwatiplastics.com';
                                  authService.switchDemoRole('super_admin');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRoleChip(
                                label: 'Staff',
                                icon: Icons.badge_outlined,
                                onTap: () {
                                  _emailController.text = 'staff@bhagwatiplastics.com';
                                  authService.switchDemoRole('staff');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRoleChip(
                                label: 'Distributor',
                                icon: Icons.storefront_outlined,
                                onTap: () {
                                  _emailController.text = 'distributor@shreetraders.com';
                                  authService.switchDemoRole('distributor');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryDark),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
