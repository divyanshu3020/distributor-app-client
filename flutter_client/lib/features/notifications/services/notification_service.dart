import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../models/app_notification.dart';

class NotificationService extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationService() {
    loadNotifications();
  }

  Future<void> loadNotifications([String? userId]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized && userId != null) {
        final data = await sb.notifications
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        _notifications = (data as List).map((i) => AppNotification.fromJson(i)).toList();
      } else {
        _notifications = _getFallbackNotifications();
      }
    } catch (e) {
      debugPrint('Notification load note: $e');
      _notifications = _getFallbackNotifications();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = AppNotification(
        id: _notifications[idx].id,
        userId: _notifications[idx].userId,
        title: _notifications[idx].title,
        body: _notifications[idx].body,
        type: _notifications[idx].type,
        metadata: _notifications[idx].metadata,
        isRead: true,
        createdAt: _notifications[idx].createdAt,
      );
      notifyListeners();
    }
  }

  // Zomato/Swiggy-style catchy reorder reminder simulator
  void simulateZomatoNudge() {
    final nudges = [
      {
        'title': '⚡ Stock Running Thin?',
        'body': 'Distributors in your area just booked 400+ packages of 20L Heavy Buckets. Reorder now to skip the production queue!',
        'type': 'reorder_reminder',
      },
      {
        'title': '📦 Don\'t Let Your Warehouse Run Dry!',
        'body': 'Construction season is peaking! Book your batch of 18" and 22" Heavy Tubs before factory machine slots fill up.',
        'type': 'reorder_reminder',
      },
      {
        'title': '🔥 Top Seller Alert: Deluxe Stools',
        'body': 'Household stools are moving fast. Grab your quota before low-stock distributor caps kick in!',
        'type': 'reorder_reminder',
      },
      {
        'title': '🚚 Freight Priority Available',
        'body': 'Book your bulk crate order today and get priority Truck allocation for guaranteed dispatch.',
        'type': 'reorder_reminder',
      },
    ];

    final pick = nudges[DateTime.now().millisecond % nudges.length];

    _notifications.insert(
      0,
      AppNotification(
        id: 'nudge-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current-user',
        title: pick['title']!,
        body: pick['body']!,
        type: pick['type']!,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  List<AppNotification> _getFallbackNotifications() {
    return [
      AppNotification(
        id: 'notif-1',
        userId: 'u1',
        title: '🚚 Order Dispatched: 14ft Truck en route!',
        body: 'Order #PO-202611-001 has been loaded onto vehicle MH 04 GD 4521. Driver contact: +91 98765 12345.',
        type: 'dispatch_alert',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'notif-2',
        userId: 'u1',
        title: '⚡ Stock Running Thin?',
        body: 'Distributors in your area just booked 400+ packages of 20L Heavy Buckets. Reorder now to skip the production queue!',
        type: 'reorder_reminder',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      AppNotification(
        id: 'notif-3',
        userId: 'u1',
        title: '⚙️ Injection Molders Running!',
        body: 'Your Made-to-Order items for Order #PO-202611-001 are currently running on Factory Line 2.',
        type: 'order_update',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
