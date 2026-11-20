import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';

class DispatchService extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Step 1: Staff / Admin enters driver & vehicle info
  Future<bool> assignDispatchDetails({
    required String orderId,
    required String driverName,
    required String driverPhone,
    required String vehicleNumber,
    required DateTime expectedArrival,
    String? dispatchNotes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        await sb.orders.update({
          'driver_name': driverName,
          'driver_phone': driverPhone,
          'vehicle_number': vehicleNumber,
          'expected_arrival': expectedArrival.toIso8601String(),
          'dispatch_notes': dispatchNotes,
          'status': 'dispatched',
        }).eq('id', orderId);

        // Send push notification to distributor
        try {
          await sb.client.functions.invoke('push-notifications', body: {
            'type': 'stage_update',
            'stage': 'dispatched',
            'orderId': orderId,
            'driverPhone': driverPhone,
            'vehicleNumber': vehicleNumber,
          });
        } catch (_) {}
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Step 3 & 4: Distributor taps "Acknowledge Arrival" -> backend sends OTP to driver's phone
  Future<Map<String, dynamic>?> acknowledgeArrivalAndSendOtp(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        final res = await sb.client.functions.invoke('send-delivery-otp', body: {
          'orderId': orderId,
        });

        if (res.status == 200) {
          return res.data as Map<String, dynamic>;
        } else {
          _errorMessage = res.data?['error'] ?? 'Failed to send OTP to driver';
          return null;
        }
      } else {
        // Mock demo simulation
        return {
          'success': true,
          'message': 'Delivery OTP dispatched to driver (+91 98*** **321).',
          'driverPhoneMasked': '+91 98*** **321',
          'demoOtp': '123456',
        };
      }
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Step 5 & 6: Distributor enters OTP told verbally by driver -> verify and mark delivered
  Future<bool> verifyOtpAndCompleteDelivery({
    required String orderId,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        final res = await sb.client.functions.invoke('verify-delivery-otp', body: {
          'orderId': orderId,
          'otp': otp.trim(),
        });

        if (res.status == 200) {
          return true;
        } else {
          _errorMessage = res.data?['error'] ?? 'Invalid OTP code.';
          return false;
        }
      } else {
        // Mock demo simulation: accept '123456' or any 6 digits in demo mode
        if (otp.trim().length == 6) {
          return true;
        } else {
          _errorMessage = 'Invalid 6-digit OTP code.';
          return false;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
