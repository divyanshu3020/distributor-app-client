import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../services/dispatch_service.dart';

class DeliveryHandshakeScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const DeliveryHandshakeScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<DeliveryHandshakeScreen> createState() => _DeliveryHandshakeScreenState();
}

class _DeliveryHandshakeScreenState extends State<DeliveryHandshakeScreen> {
  bool _otpDispatched = false;
  String _maskedPhone = '+91 98*** **345';
  String? _demoOtp;
  final TextEditingController _otpController = TextEditingController();
  bool _deliveryCompleted = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _acknowledgeArrival() async {
    final dispatchService = context.read<DispatchService>();
    final result = await dispatchService.acknowledgeArrivalAndSendOtp(widget.orderId);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _otpDispatched = true;
        _maskedPhone = result['driverPhoneMasked'] ?? _maskedPhone;
        _demoOtp = result['demoOtp'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to driver\'s phone ($_maskedPhone)!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else if (dispatchService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dispatchService.errorMessage!),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code provided by the driver.'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    final dispatchService = context.read<DispatchService>();
    final success = await dispatchService.verifyOtpAndCompleteDelivery(
      orderId: widget.orderId,
      otp: otp,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _deliveryCompleted = true;
      });
    } else if (dispatchService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dispatchService.errorMessage!),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dispatchService = context.watch<DispatchService>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Track Order #${widget.orderNumber}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Order Meta
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${widget.orderNumber}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                      ),
                      StatusBadge(status: _deliveryCompleted ? 'delivered' : (_otpDispatched ? 'out_for_delivery' : 'dispatched')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.borderSubtle),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.local_shipping, size: 18, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text('Assigned Vehicle: MH 04 GD 4521 (14ft Full Truck)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.person_pin, size: 18, color: AppTheme.textMuted),
                      SizedBox(width: 8),
                      Text('Driver: Ramesh Yadav (+91 98765 12345)', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_deliveryCompleted) ...[
              // Delivery Completed Certificate
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, size: 64, color: Color(0xFF16A34A)),
                    const SizedBox(height: 12),
                    const Text(
                      'Delivery Verified & Complete!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Clearance SMS Dispatched to Driver:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Text(
                        '"Bhagwati Plastics CLEARANCE: OTP verified successfully. Hand over goods to the distributor. Delivery complete."',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF166534)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Return to Catalog',
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Handshake Steps
              const Text(
                'Delivery Handshake Flow (No Driver App)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain),
              ),
              const SizedBox(height: 6),
              const Text(
                'Follow these simple steps when the delivery vehicle arrives at your warehouse.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),

              // Step 1: Acknowledge Arrival
              _buildStepCard(
                stepNumber: '1',
                title: 'Driver Arrival Trigger',
                description: 'When the delivery truck pulls in, tap "Acknowledge Arrival" below. This sends a secure 6-digit OTP directly to the driver\'s phone via SMS.',
                isDone: _otpDispatched,
                child: !_otpDispatched
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: CustomButton(
                          text: 'Acknowledge Driver Arrival',
                          icon: Icons.notifications_active_outlined,
                          isLoading: dispatchService.isLoading,
                          onPressed: _acknowledgeArrival,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 14),

              // Step 2: Ask Driver for OTP & Enter Code
              _buildStepCard(
                stepNumber: '2',
                title: 'Enter Verbal Driver OTP',
                description: 'The driver will read the 6-digit code received on their phone ($_maskedPhone). Enter it below to unlock delivery clearance.',
                isDone: _deliveryCompleted,
                isActive: _otpDispatched,
                child: _otpDispatched
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          if (_demoOtp != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Demo Mode Note: The driver received OTP: $_demoOtp',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                          CustomTextField(
                            controller: _otpController,
                            label: 'Enter 6-Digit Delivery OTP',
                            hint: '123456',
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.security, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(height: 14),
                          CustomButton(
                            text: 'Verify OTP & Accept Goods',
                            icon: Icons.check_circle,
                            isLoading: dispatchService.isLoading,
                            onPressed: _verifyOtp,
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required bool isDone,
    bool isActive = true,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? const Color(0xFF86EFAC) : (isActive ? AppTheme.primaryBlue.withOpacity(0.4) : AppTheme.borderSubtle),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFF16A34A) : (isActive ? AppTheme.primaryBlue : const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        stepNumber,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isActive ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
          ),
          if (child != null) child,
        ],
      ),
    );
  }
}
