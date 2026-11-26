import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/services/supabase_service.dart';
import '../models/quotation.dart';

class QuoteService extends ChangeNotifier {
  List<Quotation> _quotes = [];
  bool _isLoading = false;

  List<Quotation> get quotes => _quotes;
  bool get isLoading => _isLoading;

  Future<void> loadDistributorQuotes(String distributorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        final data = await sb.quotations
            .select()
            .eq('distributor_id', distributorId)
            .order('created_at', ascending: false);
        _quotes = (data as List).map((i) => Quotation.fromJson(i)).toList();
      } else {
        _quotes = [
          Quotation(
            id: 'mock-q-1',
            quoteNumber: 'QT-202611-1042',
            orderId: 'PO-202611-001',
            distributorId: distributorId,
            finalSubtotal: 48500.0,
            vehicleFare: 3200.0,
            taxAmount: 9306.0,
            grandTotal: 61006.0,
            status: 'locked',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
      }
    } catch (e) {
      debugPrint('Error loading quotations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Quotation?> getQuoteForOrder(String orderId) async {
    try {
      final sb = SupabaseService.instance;
      if (sb.isInitialized) {
        final data = await sb.quotations.select().eq('order_id', orderId).maybeSingle();
        if (data != null) {
          return Quotation.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Quote lookup warning: $e');
    }
    return null;
  }

  // Vehicle Image Mapping Helper
  static String getVehicleAsset(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('auto') || lower.contains('ape') || lower.contains('loader') || lower.contains('3-wheeler')) {
      return 'assets/vehicles/ape.png';
    } else if (lower.contains('tempo') || lower.contains('ace') || lower.contains('chota hathi')) {
      return 'assets/vehicles/ace.png';
    } else if (lower.contains('mini') || lower.contains('bolero') || lower.contains('pickup')) {
      return 'assets/vehicles/bolero.png';
    } else {
      // truck, container, eicher, heavy_truck
      return 'assets/vehicles/eicher.png';
    }
  }

  // Generate and download/print official Executive PDF Quote
  Future<void> generateAndPrintPdf({
    required String quoteNumber,
    required String orderNumber,
    required String distributorName,
    required String? distributorGst,
    required String? distributorAddress,
    required String vehicleTier,
    required double subtotal,
    required double vehicleFare,
    required double taxAmount,
    required double grandTotal,
    int? totalPackages,
  }) async {
    // 1. Preload the vehicle image asset
    Uint8List? vehicleBytes;
    try {
      final assetPath = getVehicleAsset(vehicleTier);
      final byteData = await rootBundle.load(assetPath);
      vehicleBytes = byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Could not load vehicle asset into PDF: $e');
    }

    final pdf = pw.Document();
    final vehicleImage = vehicleBytes != null ? pw.MemoryImage(vehicleBytes) : null;

    // Palette
    const primaryNavy = PdfColor.fromInt(0xFF0F2942);
    const secondaryBlue = PdfColor.fromInt(0xFF1E3A8A);
    const accentGreen = PdfColor.fromInt(0xFF059669);
    const neutralLight = PdfColor.fromInt(0xFFF8FAFC);
    const neutralBorder = PdfColor.fromInt(0xFFE2E8F0);
    const textDark = PdfColor.fromInt(0xFF0F172A);
    const textMuted = PdfColor.fromInt(0xFF64748B);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. DEMO WATERMARK BANNER
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                margin: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFEF3C7),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFF59E0B)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '*** DEMO EVALUATION PREVIEW — NOT FOR COMMERCIAL OR TAX INVOICE USE ***',
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFF92400E),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),

              // 2. HEADER: Brand Title + Document Meta
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Company Branding
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BHAGWATI PLASTICS',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Industrial Plastic Injection & Blow Molding Manufacturing',
                        style: pw.TextStyle(fontSize: 8.5, color: textMuted, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Plot 42, Industrial Area Phase 2 | GSTIN: 07AAAAA0000A1Z5', style: const pw.TextStyle(fontSize: 8, color: textMuted)),
                      pw.Text('Phone: +91 98765 43210 | Email: factory@bhagwatiplastics.com', style: const pw.TextStyle(fontSize: 8, color: textMuted)),
                    ],
                  ),

                  // Quote Badge & Dates
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: neutralLight,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: neutralBorder),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: const pw.BoxDecoration(
                            color: primaryNavy,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'OFFICIAL QUOTATION',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          quoteNumber,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: textDark),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Order Ref: #$orderNumber', style: const pw.TextStyle(fontSize: 8.5, color: textMuted)),
                        pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 8.5, color: textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.5, color: primaryNavy),
              pw.SizedBox(height: 10),

              // 3. TWO-COLUMN CARDS: Distributor (Billed To) + Logistics Vehicle Allocation
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Card A: Billed To
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: neutralLight,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: neutralBorder),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DISTRIBUTOR / BILLED TO',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryBlue),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            distributorName,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: textDark),
                          ),
                          pw.SizedBox(height: 2),
                          if (distributorGst != null && distributorGst.isNotEmpty)
                            pw.Text('GSTIN: $distributorGst', style: const pw.TextStyle(fontSize: 8, color: textMuted)),
                          if (distributorAddress != null && distributorAddress.isNotEmpty)
                            pw.Text('Address: $distributorAddress', style: const pw.TextStyle(fontSize: 8, color: textMuted)),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFFDCFCE7),
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                            ),
                            child: pw.Text(
                              'Verified B2B Wholesale Partner',
                              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: accentGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),

                  // Card B: Logistics Allocation WITH VEHICLE ICON/IMAGE
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF0FDF4),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFFBBF7D0)),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // Vehicle Icon / Image
                          if (vehicleImage != null)
                            pw.Container(
                              width: 60,
                              height: 50,
                              margin: const pw.EdgeInsets.only(right: 10),
                              child: pw.Image(vehicleImage, fit: pw.BoxFit.contain),
                            ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'ASSIGNED LOGISTICS ALLOCATION',
                                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF166534)),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  vehicleTier,
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: textDark),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  totalPackages != null ? 'Capacity: $totalPackages Packages' : 'Dynamic Sizing: Standard Packages',
                                  style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColor.fromInt(0xFFDCFCE7),
                                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                                  ),
                                  child: pw.Text(
                                    'Secure OTP Handshake On Arrival',
                                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: accentGreen),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // 4. FINANCIAL BREAKDOWN TABLE
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: neutralBorder),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    // Table Header
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: const pw.BoxDecoration(
                        color: primaryNavy,
                        borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(5)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Description & Schedule of Goods', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Text('Subtotal (INR)', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ],
                      ),
                    ),

                    // Row 1: Goods
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      color: neutralLight,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Factory Molded Polymer Goods', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                              pw.Text('Ready & Made-to-Order package batch fulfillment', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
                            ],
                          ),
                          pw.Text('Rs. ${subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, thickness: 0.5, color: neutralBorder),

                    // Row 2: Freight Allocation
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Dedicated Freight Allocation ($vehicleTier)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                              pw.Text('Vehicle sizing calculated by package count', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
                            ],
                          ),
                          pw.Text('Rs. ${vehicleFare.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, thickness: 0.5, color: neutralBorder),

                    // Row 3: Taxes
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      color: neutralLight,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Goods & Services Tax (18% GST)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDark)),
                              pw.Text('CGST (9%) + SGST (9%) on taxable turnover', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
                            ],
                          ),
                          pw.Text('Rs. ${taxAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, thickness: 1, color: primaryNavy),

                    // Grand Total Row
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFEFF6FF),
                        borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(5)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('TOTAL PAYABLE AMOUNT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryNavy)),
                              pw.Text('Official Locked Quotation (Taxes & Freight Included)', style: pw.TextStyle(fontSize: 7.5, color: accentGreen, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Text(
                            'Rs. ${grandTotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryNavy),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // 5. TERMS & CONDITIONS
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: neutralLight,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: neutralBorder),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Factory Terms & Fulfillment Policy:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: primaryNavy)),
                    pw.SizedBox(height: 4),
                    pw.Text('1. Final Quotation has been locked based on standard package batch counts and confirmed machine allocation.', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
                    pw.Text('2. Driver verification and goods clearance are completed via physical arrival OTP entry inside the mobile app.', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
                    pw.Text('3. Made-to-order injection molded items cannot be cancelled once production tooling commences.', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
                  ],
                ),
              ),
              pw.Spacer(),

              // 6. FOOTER & AUTHORIZATION SIGNATORY
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Generated electronically by Bhagwati Plastics B2B Platform', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
                      pw.Text('Computer Generated Invoice — No physical signature required', style: const pw.TextStyle(fontSize: 7, color: textMuted)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 140,
                        height: 1,
                        color: textDark,
                        margin: const pw.EdgeInsets.only(bottom: 4),
                      ),
                      pw.Text('Authorized Factory Signatory', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark)),
                      pw.Text('Bhagwati Plastic Manufacturing HQ', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Quotation_$quoteNumber.pdf',
    );
  }
}
