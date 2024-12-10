import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StallReceiptPaid extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  final String vendorFullName;

  const StallReceiptPaid({Key? key, required this.payments, required this.vendorFullName}) : super(key: key);

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
            Navigator.of(context).pop(true);
          },
        ),
        title: const Text(
          "Receipt",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: payments.map((payment) {
            return Column(
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
                      'Vendor Name',
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      vendorFullName,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Date',
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      _formatDate(payment['paymentDate'].toDate()),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Billing Cycle',
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      payment['billingCycle'],
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Number of Days',
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      payment['noOfDays'].toString(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Garbage Fee',
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      '₱${payment['garbageFee']}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Penalty',
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      '₱${payment['penalty']}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Surcharge',
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      '₱${payment['surcharge']}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₱${payment['total'] ?? payment['totalAmountDue']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
