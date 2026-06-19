import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../domain/sale.dart';

/// Builds and shares a printable PDF receipt for a [Sale].
class ReceiptService {
  const ReceiptService();

  Future<void> shareReceipt(Sale sale) async {
    final bytes = await _build(sale);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${sale.invoiceNumber}.pdf',
    );
  }

  Future<void> printReceipt(Sale sale) async {
    await Printing.layoutPdf(onLayout: (_) => _build(sale));
  }

  Future<Uint8List> _build(Sale sale) async {
    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFF00897B);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(AppConstants.appName,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text(AppConstants.appTagline,
                    style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Divider(color: accent),
              _kv('Invoice', sale.invoiceNumber),
              _kv('Date', Formatters.dateTime(sale.createdAt)),
              _kv('Cashier', sale.cashierName),
              if (sale.customerName.isNotEmpty)
                _kv('Customer', sale.customerName),
              pw.Divider(),
              ...sale.items.map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(item.medicineName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            '${item.quantity} x ${Formatters.money(item.unitPrice)}',
                            style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(Formatters.money(item.subtotal),
                            style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ],
                ),
              ),
              pw.Divider(),
              _kv('Subtotal', Formatters.money(sale.subtotal)),
              if (sale.discount > 0)
                _kv('Discount', '- ${Formatters.money(sale.discount)}'),
              if (sale.tax > 0) _kv('Tax', Formatters.money(sale.tax)),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.Text(Formatters.money(sale.total),
                      style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: accent)),
                ],
              ),
              pw.Divider(),
              _kv('Payment', sale.paymentMethod.label),
              if (sale.paymentReference.isNotEmpty)
                _kv('Reference', sale.paymentReference),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text('Thank you for your purchase!',
                    style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _kv(String key, String value) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(key, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      );
}

final receiptService = const ReceiptService();
