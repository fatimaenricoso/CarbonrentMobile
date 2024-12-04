import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Stallconfigtap extends StatefulWidget {
  final String vendorId;

  const Stallconfigtap({Key? key, required this.vendorId}) : super(key: key);

  @override
  _StallconfigtapState createState() => _StallconfigtapState();
}

class _StallconfigtapState extends State<Stallconfigtap> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _vendorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVendorDetails();
  }

  Future<void> _fetchVendorDetails() async {
    try {
      DocumentSnapshot vendorDoc = await _firestore
          .collection('approvedVendors')
          .doc(widget.vendorId)
          .get();

      if (vendorDoc.exists) {
        Map<String, dynamic> vendorData = vendorDoc.data() as Map<String, dynamic>;

        QuerySnapshot paymentSnapshot = await _firestore
            .collection('stall_payment')
            .where('vendorId', isEqualTo: widget.vendorId)
            .where('status', whereIn: ['Pending', 'Overdue'])
            .get();

        if (paymentSnapshot.docs.isNotEmpty) {
          List<Map<String, dynamic>> paymentDataList = paymentSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          paymentDataList.sort((a, b) => (a['dueDate'] as Timestamp).toDate().compareTo((b['dueDate'] as Timestamp).toDate()));

          Map<String, dynamic>? selectedPaymentData;
          for (var paymentData in paymentDataList) {
            if (paymentData['status'] == 'Overdue') {
              if (selectedPaymentData == null || (paymentData['dueDate'] as Timestamp).toDate().isBefore((selectedPaymentData['dueDate'] as Timestamp).toDate())) {
                selectedPaymentData = paymentData;
              }
            } else if (selectedPaymentData == null) {
              selectedPaymentData = paymentData;
            }
          }

          if (selectedPaymentData != null) {
            vendorData['status'] = selectedPaymentData['status'];
            vendorData['billingCycle'] = selectedPaymentData['billingCycle']; // Use billingCycle from stall_payment
            vendorData['dueDate'] = selectedPaymentData['dueDate']; // Add dueDate
            vendorData['total'] = selectedPaymentData['total']; // Add total
            vendorData['totalAmountDue'] = selectedPaymentData['totalAmountDue']; // Add totalAmountDue
            vendorData['garbageFee'] = selectedPaymentData['garbageFee']; // Add garbageFee
            vendorData['amount'] = selectedPaymentData['amount']; // Add amount
            vendorData['amountIntRate'] = selectedPaymentData['amountIntRate']; // Add amountIntRate
            vendorData['dailyPayment'] = selectedPaymentData['dailyPayment']; // Add dailyPayment
            vendorData['interestRate'] = selectedPaymentData['interestRate']; // Add interestRate
            vendorData['penalty'] = selectedPaymentData['penalty']; // Add penalty
            vendorData['noOfDays'] = selectedPaymentData['noOfDays']; // Add noOfDays
            vendorData['surcharge'] = selectedPaymentData['surcharge']; // Add surcharge
            vendorData['startDate'] = selectedPaymentData['startDate']; // Add startDate
          }
        }

        setState(() {
          _vendorData = vendorData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching vendor details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stall Configuration"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vendorData != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name: ${_vendorData!['firstName']} ${_vendorData!['lastName']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Billing Cycle: ${_vendorData!['billingCycle']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Status: ${_vendorData!['status']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Due Date: ${_vendorData!['dueDate'] != null ? (_vendorData!['dueDate'] as Timestamp).toDate().toString() : 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Total: ₱${_vendorData!['total']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Total Amount Due: ₱${_vendorData!['totalAmountDue']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Amount: ₱${_vendorData!['amount'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Amount Interest Rate: ${_vendorData!['amountIntRate'] ?? 'N/A'}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Daily Payment: ₱${_vendorData!['dailyPayment'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Garbage Fee: ₱${_vendorData!['garbageFee'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Interest Rate: ${_vendorData!['interestRate'] ?? 'N/A'}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Penalty: ₱${_vendorData!['penalty'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Number of Days: ${_vendorData!['noOfDays'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Surcharge: ₱${_vendorData!['surcharge'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Start Date: ${_vendorData!['startDate'] != null ? (_vendorData!['startDate'] as Timestamp).toDate().toString() : 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : const Center(child: Text("Vendor details not found")),
    );
  }
}
