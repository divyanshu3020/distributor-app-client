import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending_quote':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = 'Pending Quote';
        icon = Icons.hourglass_empty;
        break;
      case 'confirmed':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        label = 'Order Confirmed';
        icon = Icons.check_circle_outline;
        break;
      case 'in_production':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'In Production';
        icon = Icons.precision_manufacturing_outlined;
        break;
      case 'packing':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        label = 'Packing Goods';
        icon = Icons.inventory_2_outlined;
        break;
      case 'dispatched':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Dispatched';
        icon = Icons.local_shipping_outlined;
        break;
      case 'out_for_delivery':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'Out for Delivery';
        icon = Icons.near_me_outlined;
        break;
      case 'delivered':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        label = 'Delivered';
        icon = Icons.verified_outlined;
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = status.replaceAll('_', ' ').toUpperCase();
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
