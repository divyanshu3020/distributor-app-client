import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class LicenseService extends ChangeNotifier {
  // Hardcoded 7-Day Demo Expiry (November 30, 2026)
  static final DateTime trialExpiryDate = DateTime(2026, 11, 30, 23, 59, 59);

  bool _isLocked = false;
  String _lockReason = '';
  bool _isChecking = true;

  bool get isLocked => _isLocked;
  String get lockReason => _lockReason;
  bool get isChecking => _isChecking;

  LicenseService() {
    checkLicense();
  }

  Future<void> checkLicense() async {
    _isChecking = true;
    notifyListeners();

    try {
      // 1. Time-based Trial Expiration Check
      final now = DateTime.now();
      if (now.isAfter(trialExpiryDate)) {
        _isLocked = true;
        _lockReason = 'The 7-day evaluation period for this build expired on 30 Nov 2026. '
            'Please contact the app developer to finalize commercial terms and unlock the production release.';
        _isChecking = false;
        notifyListeners();
        return;
      }

      // 2. Remote Kill Switch via Supabase
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        try {
          final res = await sb.announcements
              .select()
              .eq('title', 'APP_LICENSE_LOCK')
              .maybeSingle();

          if (res != null && res['is_published'] == true) {
            _isLocked = true;
            _lockReason = res['message'] ??
                'App access has been suspended by the developer. '
                'Please contact the developer to resolve licensing and activate access.';
            _isChecking = false;
            notifyListeners();
            return;
          }
        } catch (e) {
          debugPrint('Remote license check note: $e');
        }
      }

      _isLocked = false;
      _lockReason = '';
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}
