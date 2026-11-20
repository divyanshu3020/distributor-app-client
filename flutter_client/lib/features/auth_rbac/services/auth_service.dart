import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  UserProfile? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentProfile => _currentProfile;
  bool get isAuthenticated => _currentProfile != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final sb = SupabaseService.instance;
    if (sb.isInitialized && sb.currentUser != null) {
      await fetchProfile(sb.currentUser!.id);
    } else {
      // Default to demo distributor for immediate review/testability
      _setDemoUser('distributor');
    }
  }

  void _setDemoUser(String role) {
    if (role == 'super_admin') {
      _currentProfile = UserProfile(
        id: '00000000-0000-0000-0000-000000000001',
        email: 'owner@bhagwatiplastics.com',
        fullName: 'Rajesh Sharma (Owner)',
        phone: '+91 98765 00001',
        role: 'super_admin',
        businessName: 'Bhagwati Plastic Manufacturing HQ',
        address: 'Plot 42, Industrial Area Phase 2',
        createdAt: DateTime.now(),
      );
    } else if (role == 'staff') {
      _currentProfile = UserProfile(
        id: '00000000-0000-0000-0000-000000000002',
        email: 'staff@bhagwatiplastics.com',
        fullName: 'Amit Verma (Plant Accountant)',
        phone: '+91 98765 00002',
        role: 'staff',
        businessName: 'Bhagwati Plastics Plant Operations',
        address: 'Dispatch Bay 3, Factory Yard',
        createdAt: DateTime.now(),
      );
    } else {
      _currentProfile = UserProfile(
        id: '00000000-0000-0000-0000-000000000003',
        email: 'distributor@shreetraders.com',
        fullName: 'Sunil Kumar',
        phone: '+91 98765 00003',
        role: 'distributor',
        businessName: 'Shree Plastics Wholesale & Distribution',
        gstNumber: '07AAAAA1234A1Z1',
        address: 'Shop 14, Wholesale Market, Ring Road',
        createdAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sb = SupabaseService.instance;
      final response = await sb.profiles.select().eq('id', userId).single();
      _currentProfile = UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        final authRes = await sb.client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        if (authRes.user != null) {
          await fetchProfile(authRes.user!.id);
          return true;
        }
      } else {
        // Mock fallback if offline/no credentials yet
        if (email.contains('admin') || email.contains('owner')) {
          _setDemoUser('super_admin');
        } else if (email.contains('staff') || email.contains('accountant')) {
          _setDemoUser('staff');
        } else {
          _setDemoUser('distributor');
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchDemoRole(String role) {
    _setDemoUser(role);
  }

  Future<void> signOut() async {
    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        await sb.client.auth.signOut();
      }
    } catch (_) {}
    _currentProfile = null;
    notifyListeners();
  }
}
