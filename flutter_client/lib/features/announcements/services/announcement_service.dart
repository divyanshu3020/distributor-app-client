import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../models/announcement.dart';

class AnnouncementService extends ChangeNotifier {
  List<Announcement> _announcements = [];
  bool _isLoading = false;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;

  AnnouncementService() {
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        final data = await sb.announcements
            .select()
            .order('pinned', ascending: false)
            .order('created_at', ascending: false);
        _announcements = (data as List).map((i) => Announcement.fromJson(i)).toList();
      } else {
        _announcements = _getFallbackAnnouncements();
      }
    } catch (e) {
      debugPrint('Announcements load warning: $e');
      _announcements = _getFallbackAnnouncements();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement({
    required String title,
    required String message,
    required String category,
    required bool pinned,
  }) async {
    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        await sb.announcements.insert({
          'title': title,
          'message': message,
          'category': category,
          'pinned': pinned,
          'is_published': true,
        });
      }

      // Prepend locally
      _announcements.insert(
        0,
        Announcement(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          message: message,
          category: category,
          pinned: pinned,
          isPublished: true,
          createdAt: DateTime.now(),
        ),
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      return false;
    }
  }

  List<Announcement> _getFallbackAnnouncements() {
    return [
      Announcement(
        id: 'ann-1',
        title: 'New Launch: 20L Industrial Heavy Duty Buckets',
        message: 'We have commissioned a new 350-ton injection molding line for our 20L Industrial Heavy Duty Buckets. Orders placed this week receive prioritized production dispatch.',
        category: 'product_launch',
        isPublished: true,
        pinned: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Announcement(
        id: 'ann-2',
        title: 'Price Stability Guarantee across All Storage Jars & Crates',
        message: 'Despite polymer granule fluctuations, Bhagwati Plastics is maintaining fixed distributor base pricing across all storage containers and crates for Q4.',
        category: 'price_update',
        isPublished: true,
        pinned: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Announcement(
        id: 'ann-3',
        title: 'Automated Truck Freight Allocation Now Live in Distributor App',
        message: 'Direct vehicle assignment is now fully integrated into the distributor app. Real-time vehicle freight estimates are calculated right in your cart prior to quote confirmation.',
        category: 'general',
        isPublished: true,
        pinned: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}
