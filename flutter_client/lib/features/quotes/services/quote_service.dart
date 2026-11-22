import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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

  // Generate and download/print official PDF Quote
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
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // DEMO WATERMARK BANNER
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                margin: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber100,
                  border: pw.Border.all(color: PdfColors.amber600),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '*** DEMO EVALUATION PREVIEW — NOT FOR COMMERCIAL OR TAX INVOICE USE ***',
                    style: pw.TextStyle(
                      color: PdfColors.amber900,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),

              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BHAGWATI PLASTICS',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Quality Molded Polymer Products & Logistics', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Plot 42, Industrial Area Phase 2 | GSTIN: 07AAAAA0000A1Z5', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Phone: +91 98765 43210 | Email: orders@bhagwatiplastics.com', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: PdfColors.blue800,
                        child: pw.Text(
                          'FINAL OFFICIAL QUOTATION',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(quoteNumber, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text('Order: #$orderNumber', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 12),

              // Billed To & Logistics Grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DISTRIBUTOR (BILLED TO)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                          pw.SizedBox(height: 4),
                          pw.Text(distributorName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          if (distributorGst != null) pw.Text('GSTIN: $distributorGst', style: const pw.TextStyle(fontSize: 9)),
                          if (distributorAddress != null) pw.Text('Address: $distributorAddress', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('LOGISTICS & DISPATCH ALLOCATION', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                          pw.SizedBox(height: 4),
                          pw.Text('Vehicle Tier: $vehicleTier', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          pw.Text('Delivery Handshake: Secure Driver OTP', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('Pricing Status: LOCKED & CONFIRMED', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Price Breakdown Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Particulars', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount (INR)', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Factory Molded Goods Subtotal', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs. ${subtotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Dedicated Freight Allocation ($vehicleTier)', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs. ${vehicleFare.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Goods & Services Tax (18% GST)', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs. ${taxAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('GRAND TOTAL PAYABLE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rs. ${grandTotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Terms & Conditions
              pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text('1. Final Quotation has been locked based on package count and confirmed factory allocation.', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('2. Driver verification is completed via physical arrival OTP entry into the mobile app.', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('3. Goods made to order cannot be cancelled after injection tooling commencement.', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 24),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by Bhagwati Plastics App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Authorized Factory Signatory', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
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
