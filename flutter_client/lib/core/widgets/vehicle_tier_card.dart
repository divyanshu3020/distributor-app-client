import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'approximate_badge.dart';

class VehicleTierCard extends StatelessWidget {
  final String tierName;
  final int totalPackages;
  final double approxFare;
  final String? description;
  final bool isTruck;

  const VehicleTierCard({
    super.key,
    required this.tierName,
    required this.totalPackages,
    required this.approxFare,
    this.description,
    this.isTruck = false,
  });

  IconData _getVehicleIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('heavy') || lower.contains('container')) {
      return Icons.fire_truck_outlined;
    } else if (lower.contains('truck')) {
      return Icons.local_shipping;
    } else if (lower.contains('mini') || lower.contains('pickup')) {
      return Icons.airport_shuttle;
    } else if (lower.contains('tempo') || lower.contains('ace')) {
      return Icons.electric_rickshaw;
    }
    return Icons.two_wheeler;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Refreshing light green tint for logistics
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getVehicleIcon(tierName),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tierName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (totalPackages > 100)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TRUCK TIER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Calculated for $totalPackages total standard packages',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFDCFCE7), thickness: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  ApproximateBadge(label: 'Approximate Freight', compact: true),
                ],
              ),
              Text(
                CurrencyFormatter.formatApprox(approxFare),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
            ),
          ],
        ],
      ),
    );
  }
}
