import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ApproximateBadge extends StatelessWidget {
  final String label;
  final bool compact;

  const ApproximateBadge({
    super.key,
    this.label = 'Approximate Estimate',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Warm amber tint
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: compact ? 11 : 13,
            color: const Color(0xFFB45309),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF92400E),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
