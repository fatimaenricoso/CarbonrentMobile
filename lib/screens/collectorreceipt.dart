import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CollectorReceipt extends StatefulWidget {
  final String documentId;

  const CollectorReceipt({Key? key, required this.documentId}) : super(key: key);

  @override
  _CollectorReceiptState createState() => _CollectorReceiptState();
}

class _CollectorReceiptState extends State<CollectorReceipt> {
  bool _showQR = false;

  Future<pw.Font> _loadRegularFont() async {
    final fontData = await rootBundle.load('lib/assets/font/NotoSans-Regular.ttf');
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  Future<pw.Font> _loadBoldFont() async {
    final fontData = await rootBundle.load('lib/assets/font/NotoSans-Bold.ttf');
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  Future<Uint8List?> _generateQRCode(Map<String, dynamic> data) async {
    final qrData = 'Vendor Number: ${data['vendor_number']}\nNumber of Tickets: ${data['number_of_tickets']}\nSpace Rate: ₱${data['space_rate'].toStringAsFixed(2)}\nTotal Amount: ₱${data['total_amount'].toStringAsFixed(2)}\nDate Issued: ${_formatDate(data['date'].toDate())}\nTransaction ID: ${widget.documentId}';
    final qrCode = await QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(300); // Increase the size to 300
    final bytes = qrCode?.buffer.asUint8List();
    return bytes;
  }

  void _printForm(BuildContext context, Map<String, dynamic> data) async {
    final doc = pw.Document();
    final regularFont = await _loadRegularFont();
    final boldFont = await _loadBoldFont();
    final qrCodeImage = await _generateQRCode(data);

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'CARBONRENT',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.green, font: boldFont),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Receipt',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.black, font: boldFont),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '${data['collector_address']}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '${data['collector_contact']}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
                ),
              ),
              pw.SizedBox(height: 25),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Transaction Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: boldFont),
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Vendor Number: ${data['vendor_number']}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                  pw.SizedBox(), // Empty space to align with the right side
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date Issued', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(_formatDate(data['date'].toDate()), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Transaction ID', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(widget.documentId, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Collector', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                  pw.Text(data['collector'], style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Payment Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: boldFont),
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Number of Tickets', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(data['number_of_tickets'].toString(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Space Rate', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('₱${data['space_rate'].toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Amount', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                  pw.Text('₱${data['total_amount'].toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.SizedBox(height: 35),
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(qrCodeImage!),
                  width: 300, // Increase the size to 300
                  height: 300, // Increase the size to 300
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Scan to share details',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm:ss a').format(date);
  }

  Future<Map<String, dynamic>> _fetchPaymentDetails(String documentId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('payment_ambulant').doc(documentId).get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    } else {
      throw Exception('Document does not exist');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(true); // Pop with a result indicating form should be cleared
          },
        ),
        title: const Text(
          "Collector Receipt",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchPaymentDetails(widget.documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available'));
          } else {
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'CARBONRENT',
                        style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Receipt',
                        style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        data['collector_address'],
                        style: const TextStyle(fontSize: 9, color: Colors.black),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        data['collector_contact'],
                        style: const TextStyle(fontSize: 10, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Transaction Details',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Collector',
                          style: TextStyle(fontSize: 10),
                        ),
                        Text(
                          data['collector'],
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
/*                     const SizedBox(height: 5),
 */                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Vendor Number',
             /*              'Vendor Number: ${data['vendor_number']}', */
                          style: TextStyle(fontSize: 10),
                        ),
                         Text(
                          '${data['vendor_number']}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
/*                     const SizedBox(height: 5),
 */                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Date Issued',
                          style: TextStyle(fontSize: 10),
                        ),
                        Text(
                          _formatDate(data['date'].toDate()),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
/*                     const SizedBox(height: 5),
 */                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction ID',
                          style: TextStyle(fontSize: 10),
                        ),
                        Text(
                          widget.documentId,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
/*                     const Divider(),
                    const SizedBox(height: 10), */
                    const Text(
                      'Payment Details',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Number of Tickets',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          data['number_of_tickets'].toString(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
/*                     const SizedBox(height: 5),
 */                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Space Rate',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '₱${data['space_rate'].toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₱${data['total_amount'].toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton.icon(
                          onPressed: () => _printForm(context, data),
                          icon: const Icon(Icons.print, color: Colors.green),
                          label: const Text('Print', style: TextStyle(color: Colors.green, decoration: TextDecoration.underline)),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showQR = true;
                            });
                          },
                          icon: const Icon(Icons.qr_code, color: Colors.green),
                          label: const Text('Scan QR', style: TextStyle(color: Colors.green, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_showQR)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: 'Vendor Number: ${data['vendor_number']}\nNumber of Tickets: ${data['number_of_tickets']}\nSpace Rate: ₱${data['space_rate'].toStringAsFixed(2)}\nTotal Amount: ₱${data['total_amount'].toStringAsFixed(2)}\nDate Issued: ${_formatDate(data['date'].toDate())}\nTransaction ID: ${widget.documentId}',
                              version: QrVersions.auto, // Automatically select the best version
                              size: 200.0,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Scan to share details',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
