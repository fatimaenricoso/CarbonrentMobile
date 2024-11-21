import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppraisalDetailsTap extends StatefulWidget {
  final String goodsName;
  final String appSize;
  final String appRate;
  final int quantity;
  final String unitMeasure;
  final double totalAmount;
  final DateTime createdDate;
  final String documentId;
  final String appraiserAppraisal;
  final String appraiserEmail;
  final String appraisalAddress;
  final String contactAppraisal;
  final String appraisee;
  final String unitassign;

  const AppraisalDetailsTap({
    Key? key,
    required this.goodsName,
    required this.appSize,
    required this.appRate,
    required this.quantity,
    required this.unitMeasure,
    required this.totalAmount,
    required this.createdDate,
    required this.documentId,
    required this.appraiserAppraisal,
    required this.appraiserEmail,
    required this.appraisalAddress,
    required this.contactAppraisal,
    required this.appraisee,
    required this.unitassign,
  }) : super(key: key);

  @override
  _AppraisalDetailsTapState createState() => _AppraisalDetailsTapState();
}

class _AppraisalDetailsTapState extends State<AppraisalDetailsTap> {
  bool _showQR = false;

  Future<pw.Font> _loadRegularFont() async {
    final fontData = await rootBundle.load('lib/assets/font/NotoSans-Regular.ttf');
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  Future<pw.Font> _loadBoldFont() async {
    final fontData = await rootBundle.load('lib/assets/font/NotoSans-Bold.ttf');
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  Future<Uint8List?> _generateQRCode() async {
    final qrData = 'Product Name: ${widget.goodsName}\nSize: ${widget.appSize}\nRate: ₱${double.parse(widget.appRate).toStringAsFixed(2)}\nQuantity: ${widget.quantity}\nUnit Measure: ${widget.unitMeasure}\nTotal Amount: ₱${widget.totalAmount.toStringAsFixed(2)}\nDate Issued: ${_formatDate(widget.createdDate)}\nTransaction ID: ${widget.documentId}';
    final qrCode = await QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(300); // Increase the size to 300
    final bytes = qrCode?.buffer.asUint8List();
    return bytes;
  }

  void _printForm(BuildContext context) async {
    final doc = pw.Document();
    final regularFont = await _loadRegularFont();
    final boldFont = await _loadBoldFont();
    final qrCodeImage = await _generateQRCode();

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
                  '${widget.unitassign}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '${widget.appraisalAddress}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '${widget.contactAppraisal}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
                ),
              ),
              pw.SizedBox(height: 25),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Appraisal Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: boldFont),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                  'Appraiser: ${widget.appraiserAppraisal}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
                ),
              pw.Text(
                'Appraisee: ${widget.appraisee}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
              ),
              pw.Text(
                'Transaction ID: ${widget.documentId}',
                style: pw.TextStyle(fontSize: 10, font: regularFont),
              ),
              pw.Text(
                'Date Issued: ${_formatDate(widget.createdDate)}',
                style: pw.TextStyle(fontSize: 10, font: regularFont),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Payment Details',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Product Name', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(widget.goodsName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Size', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(widget.appSize, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Appraisal Rate', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('₱${double.parse(widget.appRate).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Quantity', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(widget.quantity.toString(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
               pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Unit Measure', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(widget.unitMeasure, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Amount:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
                  pw.Text('₱${widget.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
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
          "Appraisal Receipt",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                  widget.unitassign,
                  style: const TextStyle(fontSize: 9, color: Colors.black),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  widget.appraisalAddress,
                  style: const TextStyle(fontSize: 9, color: Colors.black),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  widget.contactAppraisal,
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
              ),
              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Appraisal Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
             Text(
                 'Appraiser: ${widget.appraiserAppraisal}',
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
              Text(
                'Appraisee: ${widget.appraisee}',
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ),
              Text(
                'Transaction ID: ${widget.documentId}',
                style: const TextStyle(fontSize: 10/* , fontStyle: FontStyle.italic */),
              ),
              Text(
                'Date Issued: ${_formatDate(widget.createdDate)}',
                style: const TextStyle(fontSize: 10/* , fontStyle: FontStyle.italic */),
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Product Name',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    widget.goodsName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Size',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    widget.appSize,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Appraisal Rate',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '₱${double.parse(widget.appRate).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    widget.quantity.toString(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Unit Measure',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    widget.unitMeasure,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₱${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: () => _printForm(context),
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
                        data: 'Product Name: ${widget.goodsName}\nSize: ${widget.appSize}\nRate: ₱${double.parse(widget.appRate).toStringAsFixed(2)}\nQuantity: ${widget.quantity}\nUnit Measure: ${widget.unitMeasure}\nTotal Amount: ₱${widget.totalAmount.toStringAsFixed(2)}\nDate Issued: ${_formatDate(widget.createdDate)}\nTransaction ID: ${widget.documentId}',
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
      ),
    );
  }
}

class AppraisalDetailsPage extends StatelessWidget {
  final String documentId;

  const AppraisalDetailsPage({Key? key, required this.documentId}) : super(key: key);

  Future<Map<String, dynamic>> _fetchAppraisalDetails(String documentId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('appraisals').doc(documentId).get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    } else {
      throw Exception('Document does not exist');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAppraisalDetails(documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available'));
          } else {
            final data = snapshot.data!;
            return AppraisalDetailsTap(
              goodsName: data['goods_name'],
              appSize: data['app_size'],
              appRate: data['app_rate'].toString(),
              quantity: data['quantity'],
              unitMeasure: data['unit_measure'],
              totalAmount: data['total_amount'].toDouble(),
              createdDate: (data['created_date'] as Timestamp).toDate(),
              documentId: documentId,
              appraiserAppraisal: data['appraisal'],
              appraisee: data['appraisee_name'],
              appraiserEmail: data['appraiser_email'],
              appraisalAddress: data['Address_appraisal'],
              unitassign: data['appraisal_assign'],
              contactAppraisal: data['contact_appraisal'],
            );
          }
        },
      ),
    );
  }
}
