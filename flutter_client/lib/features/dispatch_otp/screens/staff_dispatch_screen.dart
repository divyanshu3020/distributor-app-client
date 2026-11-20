import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../services/dispatch_service.dart';

class StaffDispatchScreen extends StatefulWidget {
  const StaffDispatchScreen({super.key});

  @override
  State<StaffDispatchScreen> createState() => _StaffDispatchScreenState();
}

class _StaffDispatchScreenState extends State<StaffDispatchScreen> {
  // Mock active orders ready for dispatch
  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 'PO-202611-001',
      'distributor': 'Shree Plastics Wholesale',
      'packages': 140,
      'units': 2400,
      'vehicleTier': '14-17ft Full Body Truck',
      'status': 'packing',
    },
    {
      'id': 'PO-202611-002',
      'distributor': 'Apex Industrial Traders',
      'packages': 45,
      'units': 800,
      'vehicleTier': 'Tata Ace / Small Tempo',
      'status': 'in_production',
    },
    {
      'id': 'PO-202611-003',
      'distributor': 'Metro Hardware Distributors',
      'packages': 85,
      'units': 1500,
      'vehicleTier': 'Mahindra Bolero Maxi / Pickup',
      'status': 'dispatched',
      'driver_name': 'Ramesh Kumar',
      'driver_phone': '+91 98765 12345',
      'vehicle_number': 'MH 04 AB 8844',
    },
  ];

  void _showDispatchDialog(BuildContext context, Map<String, dynamic> order) {
    final nameController = TextEditingController(text: 'Ramesh Yadav');
    final phoneController = TextEditingController(text: '+91 98765 12345');
    final vehicleController = TextEditingController(text: 'MH 04 GD 4521');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Assign Dispatch: ${order['id']}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distributor: ${order['distributor']}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  'Load: ${order['packages']} pkgs (${order['vehicleTier']})',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: nameController,
                  label: 'Driver Full Name',
                  hint: 'e.g. Ramesh Yadav',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: phoneController,
                  label: "Driver Phone Number (Receives Handshake OTP)",
                  hint: '+91 98765 43210',
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid 10-digit phone' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: vehicleController,
                  label: 'Vehicle Plate Number',
                  hint: 'e.g. MH 04 GD 4521',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vehicle number required' : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Security Notice: The driver will receive a 6-digit OTP on this phone when the distributor acknowledges arrival at destination.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final dispatchService = context.read<DispatchService>();
              final success = await dispatchService.assignDispatchDetails(
                orderId: order['id'],
                driverName: nameController.text.trim(),
                driverPhone: phoneController.text.trim(),
                vehicleNumber: vehicleController.text.trim(),
                expectedArrival: DateTime.now().add(const Duration(hours: 4)),
              );

              if (mounted) {
                Navigator.of(dialogCtx).pop();
                setState(() {
                  order['status'] = 'dispatched';
                  order['driver_name'] = nameController.text.trim();
                  order['driver_phone'] = phoneController.text.trim();
                  order['vehicle_number'] = vehicleController.text.trim();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Order ${order['id']} marked as Dispatched!' : 'Dispatch error'),
                    backgroundColor: success ? AppTheme.successGreen : AppTheme.alertRed,
                  ),
                );
              }
            },
            child: const Text('Confirm Dispatch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Factory Dispatch & Logistics'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mockOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final order = _mockOrders[idx];
          final isDispatched = order['status'] == 'dispatched';

          return Container(
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
                      'Order #${order['id']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                    ),
                    StatusBadge(status: order['status']),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Distributor: ${order['distributor']}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Packaging: ${order['packages']} packages (${order['units']} units) • ${order['vehicleTier']}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                if (isDispatched) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vehicle: ${order['vehicle_number']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('Driver: ${order['driver_name']} (${order['driver_phone']})', style: const TextStyle(fontSize: 12, color: Color(0xFF15803D))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                CustomButton(
                  text: isDispatched ? 'Update Dispatch Info' : 'Enter Dispatch & Driver Info',
                  icon: isDispatched ? Icons.edit : Icons.local_shipping,
                  variant: isDispatched ? ButtonVariant.outline : ButtonVariant.primary,
                  onPressed: () => _showDispatchDialog(context, order),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
