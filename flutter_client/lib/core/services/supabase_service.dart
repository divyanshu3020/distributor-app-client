import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SupabaseClient? _client;
  SupabaseClient get client {
    if (_client == null) {
      throw StateError('SupabaseService has not been initialized. Call init() first.');
    }
    return _client!;
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      if (Env.isConfigured) {
        await Supabase.initialize(
          url: Env.supabaseUrl,
          anonKey: Env.supabaseAnonKey,
        );
        _client = Supabase.instance.client;
        _initialized = true;
        debugPrint('Supabase initialized with live endpoint: ${Env.supabaseUrl}');
      } else {
        debugPrint('Supabase not configured in .env. Running in unauthenticated configuration mode.');
      }
    } catch (e) {
      debugPrint('Supabase initialization warning: $e');
    }
  }

  // Safe table accessors
  SupabaseQueryBuilder get profiles => client.from('profiles');
  SupabaseQueryBuilder get products => client.from('products');
  SupabaseQueryBuilder get vehicleTiers => client.from('vehicle_tiers');
  SupabaseQueryBuilder get orders => client.from('orders');
  SupabaseQueryBuilder get orderItems => client.from('order_items');
  SupabaseQueryBuilder get quotations => client.from('quotations');
  SupabaseQueryBuilder get announcements => client.from('announcements');
  SupabaseQueryBuilder get notifications => client.from('notifications');
  SupabaseQueryBuilder get inventoryLogs => client.from('inventory_logs');

  User? get currentUser => _client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
}
