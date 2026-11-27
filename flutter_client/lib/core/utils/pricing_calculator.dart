class PricingBreakdown {
  final double subtotal;
  final double vehicleFare;
  final double taxAmount;
  final double grandTotal;

  const PricingBreakdown({
    required this.subtotal,
    required this.vehicleFare,
    required this.taxAmount,
    required this.grandTotal,
  });
}

class PricingCalculator {
  // Standard B2B Industrial Goods GST Rate: 18%
  static const double gstRate = 0.18;

  /// Centralized calculation of goods subtotal, freight, GST and grand total.
  /// All app modules (Cart, Quotation, PDF, Orders) MUST use this single source of truth.
  static PricingBreakdown compute({
    required double subtotal,
    required double vehicleFare,
  }) {
    final cleanSubtotal = subtotal < 0 ? 0.0 : subtotal;
    final cleanFare = vehicleFare < 0 ? 0.0 : vehicleFare;
    final taxAmount = (cleanSubtotal + cleanFare) * gstRate;
    final grandTotal = cleanSubtotal + cleanFare + taxAmount;

    return PricingBreakdown(
      subtotal: cleanSubtotal,
      vehicleFare: cleanFare,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
    );
  }
}
