import 'package:ambulantcollector/STALLHOLDER/mainscaffold.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RentdetailsPage extends StatelessWidget {
  const RentdetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0, // Set the index to match the "Rent" tab
      child: RecentPaymentSummary(),
    );
  }
}

class RecentPaymentSummary extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Payment Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 12.0),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('stall_payment')
                .where('vendorId', isEqualTo: _auth.currentUser?.uid)
                .where('status', isEqualTo: 'Paid')
                .orderBy('paymentDate', descending: true)
                .limit(1)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No recent payment found.'));
              }

              final paymentData =
                  snapshot.data!.docs.first.data() as Map<String, dynamic>;
              final paymentDate =
                  (paymentData['paymentDate'] as Timestamp).toDate();
              final formattedDate =
                  DateFormat('MMMM d, yyyy \'at\' h:mm a').format(paymentDate);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentDetailsPage(paymentData),
                    ),
                  );
                },
                child: SizedBox(
                  width: double.infinity, // Ensures the Card takes full width
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount Due',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '₱${paymentData['totalAmountDue']}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          SizedBox(height: 6.0),
                          Text(
                            'Payment Date: $formattedDate',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PaymentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> paymentData;

  PaymentDetailsPage(this.paymentData);

  @override
  Widget build(BuildContext context) {
    final paymentDate = (paymentData['paymentDate'] as Timestamp).toDate();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.green.shade700, width: 2.0),
                  left: BorderSide(color: Colors.green.shade700, width: 2.0),
                  right: BorderSide(color: Colors.green.shade700, width: 2.0),
                  bottom: BorderSide(color: Colors.green.shade700, width: 2.0),
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
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
                    DetailItem(label: 'Payment Date', value: formattedDate),
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
                        value: '₱${paymentData['amountIntRate']}'),
                    DetailItem(
                        label: 'Interest Rate',
                        value: '${paymentData['interestRate']}%'),
                    DetailItem(
                        label: 'Surcharge',
                        value: '₱${paymentData['surcharge']}'),
                    DetailItem(
                        label: 'Total Amount Due',
                        value: '₱${paymentData['totalAmountDue']}'),
                    DetailItem(label: 'Status', value: paymentData['status']),
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

  const DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
