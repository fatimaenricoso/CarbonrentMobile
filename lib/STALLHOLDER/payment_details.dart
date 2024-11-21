import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> paymentData;

  PaymentDetailsPage(this.paymentData);

  @override
  Widget build(BuildContext context) {
    final paymentDate = (paymentData['dueDate'] as Timestamp).toDate();
    final formattedDate =
        DateFormat('MMMM d, yyyy \'at\' h:mm a').format(paymentDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailItem(
                      label: 'First Name',
                      value: paymentData['firstName'],
                    ),
                    DetailItem(
                        label: 'Middle Name', value: paymentData['middleName']),
                    DetailItem(
                        label: 'Last Name', value: paymentData['lastName']),
                    DetailItem(label: 'Due Date', value: formattedDate),
                    DetailItem(
                        label: 'Garbage Fee',
                        value: '₱${paymentData['garbageFee']}'),
                    DetailItem(
                        label: 'Daily Rent',
                        value: '₱${paymentData['dailyPayment'].toString()}'),
                    DetailItem(
                        label: 'Number of Days',
                        value: '${paymentData['noOfDays']}'),
                    DetailItem(
                      label: 'Interest Amount',
                      value: '₱${paymentData['amountIntRate']}',
                      color: paymentData['status'] == 'Overdue'
                          ? Colors.red
                          : Colors.green,
                    ),
                    DetailItem(
                      label: 'Interest Rate',
                      value: '${paymentData['interestRate']}%',
                      color: paymentData['status'] == 'Overdue'
                          ? Colors.red
                          : Colors.green,
                    ),
                    DetailItem(
                      label: 'Surcharge',
                      value: '₱${paymentData['surcharge']}',
                      color: paymentData['status'] == 'Overdue'
                          ? Colors.red
                          : Colors.green,
                    ),
                    DetailItem(
                      label: 'Total Amount Due',
                      value: '₱${paymentData['totalAmountDue']}',
                      color: paymentData['status'] == 'Overdue'
                          ? Colors.red
                          : Colors.green,
                    ),
                    DetailItem(
                      label: 'Status',
                      value: paymentData['status'],
                      color: paymentData['status'] == 'Overdue'
                          ? Colors.red
                          : Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isBold;

  const DetailItem({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentDetailsListPage extends StatelessWidget {
  final List<Map<String, dynamic>> overduePayments;
  final Map<String, dynamic>? recentPendingPayment;
  final NumberFormat currencyFormat;
  final Function(double) paymentCheckout;

  PaymentDetailsListPage({
    required this.overduePayments,
    this.recentPendingPayment,
    required this.currencyFormat,
    required this.paymentCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Details List',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recentPendingPayment != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Most Recent Pending Payment',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    DetailItem(
                        label: 'Total Amount',
                        value: currencyFormat
                            .format(recentPendingPayment!['total'] ?? 0.0),
                        isBold: true),
                    DetailItem(
                        label: 'Due Date',
                        value: DateFormat('MMMM d, yyyy hh:mm a').format(
                            recentPendingPayment!['dueDate']?.toDate() ??
                                DateTime.now())),
                  ],
                ),
              ),
            for (var payment in overduePayments)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overdue Payment',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    DetailItem(
                        label: 'Total Amount',
                        value: currencyFormat.format(payment['totalAmountDue']),
                        isBold: true),
                    DetailItem(
                        label: 'Due Date',
                        value: DateFormat('MMMM d, yyyy hh:mm a').format(
                            payment['dueDate']?.toDate() ?? DateTime.now())),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
