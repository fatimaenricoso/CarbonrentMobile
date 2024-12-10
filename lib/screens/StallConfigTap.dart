import 'package:ambulantcollector/screens/StallReceiptPreview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Stallconfigtap extends StatefulWidget {
  final String vendorId;

  const Stallconfigtap({Key? key, required this.vendorId}) : super(key: key);

  @override
  _StallconfigtapState createState() => _StallconfigtapState();
}

class _StallconfigtapState extends State<Stallconfigtap> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _vendorData;
  List<Map<String, dynamic>> _payments = [];
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
            .where('status', whereIn: ['Pending', 'Overdue', 'paid'])
            .get();

        if (paymentSnapshot.docs.isNotEmpty) {
          List<Map<String, dynamic>> paymentDataList = paymentSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Include the document ID
            return data;
          }).toList();
          paymentDataList.sort((a, b) => (a['dueDate'] as Timestamp).toDate().compareTo((b['dueDate'] as Timestamp).toDate()));

          setState(() {
            _vendorData = vendorData;
            _payments = paymentDataList;
            _isLoading = false;
          });
        } else {
          setState(() {
            _vendorData = vendorData;
            _isLoading = false;
          });
        }
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

  Future<void> _markAsPaid(List<Map<String, dynamic>> payments) async {
    bool shouldProceed = await showConfirmationDialog(context, payments);

    if (shouldProceed) {
      for (var payment in payments) {
        await _firestore
            .collection('stall_payment')
            .doc(payment['id'])
            .update({
          'status': 'paid',
          'paymentDate': Timestamp.fromDate(DateTime.now()),
          'paidBy': 'cash'
        });
      }
      _fetchVendorDetails(); // Refresh the payments list
      _showPaymentMarkedDialog(payments);
    }
  }

  Future<bool> showConfirmationDialog(BuildContext context, List<Map<String, dynamic>> payments) async {
    num totalAmount = payments.fold<num>(0.0, (num sum, payment) {
      if (payment.containsKey('totalAmountDue')) {
        return sum + (payment['totalAmountDue'] is int ? payment['totalAmountDue'].toDouble() : payment['totalAmountDue'] ?? 0.0);
      } else {
        return sum + (payment['total'] is int ? payment['total'].toDouble() : payment['total'] ?? 0.0);
      }
    });

    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Confirm Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Please confirm that you want to mark these payments as paid.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Details',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 13),
                      _buildDetailRows('Total Amount', '₱$totalAmount', labelColor: Colors.black, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Text(
                    'Do you want to mark these payments as paid?',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'No',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Yes',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }

  void _showPaymentMarkedDialog(List<Map<String, dynamic>> payments) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                ),
                child: const Text(
                  'Payment Marked as Paid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The payments have been successfully marked as paid.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToReceiptPreview(payments);
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToReceiptPreview(List<Map<String, dynamic>> paidPayments) {
    String vendorFullName = '${_vendorData?['firstName'] ?? 'N/A'} ${_vendorData?['middleName'] ?? 'N/A'} ${_vendorData?['lastName'] ?? 'N/A'}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptPreview(payments: paidPayments, vendorFullName: vendorFullName),
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                    color: Colors.green,
                  ),
                  child: const Center(
                    child: Text(
                      'Payment Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      _buildDetailRows('First Name', payment['firstName'] ?? 'N/A'),
                      _buildDetailRows('Middle Name', payment['middleName'] ?? 'N/A'),
                      _buildDetailRows('Last Name', payment['lastName'] ?? 'N/A'),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      _buildDetailRows('Billing Cycle', payment['billingCycle'] ?? 'N/A'),
                      _buildDetailRows('Status', payment['status'] ?? 'N/A'),
                      _buildDetailRows('Due Date', DateFormat.yMMMMd('en_US').format((payment['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now())),
                      _buildDetailRows('Number of Days', (payment['noOfDays'] ?? 0).toString()),
                      _buildDetailRows('Garbage Fee', '₱${payment['garbageFee'] ?? 0}'),
                      _buildDetailRows('Penalty', '₱${payment['penalty'] ?? 0}'),
                      _buildDetailRows('Surcharge', '₱${payment['surcharge'] ?? 0}'),
                      if (payment.containsKey('total'))
                        _buildDetailRows('Partial Amount', '₱${payment['total'] ?? 0}'),
                      const Divider(),
                      _buildDetailRows('Total', '₱${payment['totalAmountDue'] ?? payment['total'] ?? 0}', labelColor: Colors.black, isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showOverduePaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                    color: Colors.green,
                  ),
                  child: const Center(
                    child: Text(
                      'Overdue Payment Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      _buildDetailRows('First Name', payment['firstName'] ?? 'N/A'),
                      _buildDetailRows('Middle Name', payment['middleName'] ?? 'N/A'),
                      _buildDetailRows('Last Name', payment['lastName'] ?? 'N/A'),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      _buildDetailRows('Billing Cycle', payment['billingCycle'] ?? 'N/A'),
                      _buildDetailRows('Status', payment['status'] ?? 'N/A'),
                      _buildDetailRows('Due Date', DateFormat.yMMMMd('en_US').format((payment['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now())),
                      _buildDetailRows('Number of Days', (payment['noOfDays'] ?? 0).toString()),
                      _buildDetailRows('Garbage Fee', '₱${payment['garbageFee'] ?? 0}'),
                      _buildDetailRows('Penalty', '₱${payment['penalty'] ?? 0}'),
                      _buildDetailRows('Surcharge', '₱${payment['surcharge'] ?? 0}'),
                      _buildDetailRows('Partial Amount', '₱${payment['total'] ?? 0}'),
                      const Divider(),
                      _buildDetailRows('Total Amount Due', '₱${payment['totalAmountDue'] ?? 0}', labelColor: Colors.black, isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRows(String label, String value, {Color labelColor = const Color.fromARGB(255, 111, 110, 110), bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: labelColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    bool canMarkAsPaid = _payments.isNotEmpty && _payments.every((payment) {
      String billingCycle = payment['billingCycle'] ?? 'N/A';
      if (billingCycle == 'Monthly') {
        return now.day >= 1 && now.day <= 7;
      } else if (billingCycle == 'Weekly') {
        return now.weekday == DateTime.monday;
      } else if (billingCycle == 'Daily') {
        return true;
      }
      return false;
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Payment Information",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vendorData != null
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_payments.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_payments.any((payment) => payment['status'] == 'Pending' || payment['status'] == 'Overdue'))
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pending Payments',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      children: _payments.map((payment) {
                                        if (payment['status'] == 'Pending') {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildInfoColumnWithViewLink(
                                                Icons.calendar_today,
                                                'Due: ${DateFormat.yMMMMd('en_US').format((payment['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                                                '',
                                                subtitle: 'Billing Cycle: ${payment['billingCycle'] ?? 'N/A'}',
                                                iconColor: Colors.green,
                                                amount: 'Amount: ₱${payment['total'] ?? 0}',
                                                payment: payment,
                                              ),
                                            ],
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Overdue Payments',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      children: _payments.map((payment) {
                                        if (payment['status'] == 'Overdue') {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildInfoColumnWithViewLink(
                                                Icons.calendar_today,
                                                'Due Last: ${DateFormat.yMMMMd('en_US').format((payment['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                                                '',
                                                subtitle: 'Billing Cycle: ${payment['billingCycle'] ?? 'N/A'}',
                                                iconColor: Colors.green,
                                                amount: 'Amount: ₱${payment['totalAmountDue'] ?? 0}',
                                                payment: payment,
                                                onViewTap: () => _showOverduePaymentDetails(payment),
                                              ),
                                            ],
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }).toList(),
                                    ),
                                  ],
                                )
                              else
                                const Text('No payments found for the selected status.'),
                              // const Divider(),
                              _buildDetailRows(
                                'Total Amount',
                                '₱${_payments.fold<num>(0.0, (num sum, payment) {
                                  if (payment.containsKey('totalAmountDue')) {
                                    return sum + (payment['totalAmountDue'] is int ? payment['totalAmountDue'].toDouble() : payment['totalAmountDue'] ?? 0.0);
                                  } else {
                                    return sum + (payment['total'] is int ? payment['total'].toDouble() : payment['total'] ?? 0.0);
                                  }
                                })}',
                                labelColor: Colors.black,
                                isBold: true,
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  onPressed: canMarkAsPaid
                                      ? () => _markAsPaid(_payments)
                                      : () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('You cannot mark as paid at this time.'),
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    backgroundColor: canMarkAsPaid ? Colors.green : Colors.grey,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Mark as Paid',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          const Text('No payments found for the selected status.'),
                      ],
                    ),
                  ),
                )
              : const Center(child: Text("Vendor details not found")),
    );
  }

  Widget _buildInfoColumnWithViewLink(IconData icon, String label, String value, {String? subtitle, Color? iconColor, String? amount, Map<String, dynamic>? payment, VoidCallback? onViewTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(icon, color: iconColor ?? const Color.fromARGB(255, 152, 151, 151)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
              if (payment != null)
                GestureDetector(
                  onTap: onViewTap ?? () => _showPaymentDetails(payment),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                if (amount != null)
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
        ],
      ),
    );
  }
}
