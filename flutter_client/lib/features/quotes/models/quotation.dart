class Quotation {
  final String id;
  final String quoteNumber;
  final String orderId;
  final String distributorId;
  final double finalSubtotal;
  final double vehicleFare;
  final double taxAmount;
  final double grandTotal;
  final String status;
  final String? pdfStoragePath;
  final String? pdfPublicUrl;
  final DateTime createdAt;

  Quotation({
    required this.id,
    required this.quoteNumber,
    required this.orderId,
    required this.distributorId,
    required this.finalSubtotal,
    required this.vehicleFare,
    required this.taxAmount,
    required this.grandTotal,
    required this.status,
    this.pdfStoragePath,
    this.pdfPublicUrl,
    required this.createdAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'] as String,
      quoteNumber: json['quote_number'] as String,
      orderId: json['order_id'] as String,
      distributorId: json['distributor_id'] as String,
      finalSubtotal: (json['final_subtotal'] as num).toDouble(),
      vehicleFare: (json['vehicle_fare'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      grandTotal: (json['grand_total'] as num).toDouble(),
      status: json['status'] as String? ?? 'locked',
      pdfStoragePath: json['pdf_storage_path'] as String?,
      pdfPublicUrl: json['pdf_public_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
