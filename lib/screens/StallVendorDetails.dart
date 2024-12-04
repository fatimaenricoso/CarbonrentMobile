import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StallDetails extends StatefulWidget {
  final DocumentSnapshot vendor;

  const StallDetails({Key? key, required this.vendor}) : super(key: key);

  @override
  _StallDetailsState createState() => _StallDetailsState();
}

class _StallDetailsState extends State<StallDetails> {
  bool _isExpanded = false;
  String _selectedStatus = 'Unpaid'; // Default selected status
  List<DocumentSnapshot> _allPayments = [];

  @override
  void initState() {
    super.initState();
    _fetchAllPayments();
  }

  Future<void> _fetchAllPayments() async {
    String vendorId = widget.vendor.id;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('stall_payment')
        .where('vendorId', isEqualTo: vendorId)
        .get();

    setState(() {
      _allPayments = querySnapshot.docs;
    });
  }

  Map<String, List<DocumentSnapshot>> _groupPaymentsByMonth(List<DocumentSnapshot> payments) {
    Map<String, List<DocumentSnapshot>> groupedPayments = {};

    for (var payment in payments) {
      var paymentData = payment.data() as Map<String, dynamic>;
      DateTime date = (paymentData['status'] == 'paid')
          ? (paymentData['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now()
          : (paymentData['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      String month = DateFormat.yMMMM('en_US').format(date);

      if (!groupedPayments.containsKey(month)) {
        groupedPayments[month] = [];
      }
      groupedPayments[month]!.add(payment);
    }

    // Sort the grouped payments by date in descending order
    List<String> sortedMonths = groupedPayments.keys.toList();
    sortedMonths.sort((a, b) {
      DateTime dateA = DateFormat.yMMMM('en_US').parse(a);
      DateTime dateB = DateFormat.yMMMM('en_US').parse(b);
      return dateB.compareTo(dateA);
    });

    Map<String, List<DocumentSnapshot>> sortedGroupedPayments = {};
    for (var month in sortedMonths) {
      sortedGroupedPayments[month] = groupedPayments[month]!;
    }

    return sortedGroupedPayments;
  }

  List<DocumentSnapshot> _filterPaymentsByStatus(String status) {
    if (status == 'Unpaid') {
      // Combine Pending payments
      return _allPayments.where((payment) {
        var paymentData = payment.data() as Map<String, dynamic>;
        return paymentData['status'] == 'Pending' || paymentData['status'] == 'Overdue';
      }).toList();
    } else {
      return _allPayments.where((payment) {
        var paymentData = payment.data() as Map<String, dynamic>;
        return paymentData['status'] == status;
      }).toList();
    }
  }

  // New method to filter and display paid payments
  List<DocumentSnapshot> _filterPaidPayments() {
    return _allPayments.where((payment) {
      var paymentData = payment.data() as Map<String, dynamic>;
      return paymentData['status'] == 'paid';
    }).toList();
  }

  Future<void> _markAsPaid(List<DocumentSnapshot> payments) async {
    bool shouldProceed = await showConfirmationDialog(context, payments);

    if (shouldProceed) {
      for (var payment in payments) {
        await FirebaseFirestore.instance
            .collection('stall_payment')
            .doc(payment.id)
            .update({
          'status': 'paid',
          'paymentDate': Timestamp.fromDate(DateTime.now()),
          'paidBy': 'cash'
        });
      }
      _fetchAllPayments(); // Refresh the payments list
      _showPaymentMarkedDialog();
    }
  }

  Future<bool> showConfirmationDialog(BuildContext context, List<DocumentSnapshot> payments) async {
    num totalAmount = payments.fold<num>(0.0, (num sum, payment) {
      var paymentData = payment.data() as Map<String, dynamic>;
      if (paymentData['status'] == 'Pending') {
        return sum + (paymentData['total'] is int ? paymentData['total'].toDouble() : paymentData['total'] ?? 0.0);
      } else if (paymentData['status'] == 'Overdue') {
        return sum + (paymentData['totalAmountDue'] is int ? paymentData['totalAmountDue'].toDouble() : paymentData['totalAmountDue'] ?? 0.0);
      }
      return sum;
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

  void _showPaymentMarkedDialog() {
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
                    onPressed: () => Navigator.of(context).pop(),
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

  void _showPaymentDetails(DocumentSnapshot payment) {
    var paymentData = payment.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // Remove default padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0), // Green padding at the top
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
                      _buildDetailRows('First Name', paymentData['firstName'] ?? 'N/A'),
                      _buildDetailRows('Middle Name', paymentData['middleName'] ?? 'N/A'),
                      _buildDetailRows('Last Name', paymentData['lastName'] ?? 'N/A'),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      _buildDetailRows('Billing Cycle', paymentData['billingCycle'] ?? 'N/A'),
                      _buildDetailRows('Status', paymentData['status'] ?? 'N/A'),
                      _buildDetailRows('Due Date', DateFormat.yMMMMd('en_US').format((paymentData['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now())),
                      _buildDetailRows('Number of Days', (paymentData['noOfDays'] ?? 0).toString()),
                      _buildDetailRows('Garbage Fee', '₱${paymentData['garbageFee'] ?? 0}'),
                      _buildDetailRows('Penalty', '₱${paymentData['penalty'] ?? 0}'),
                      _buildDetailRows('Surcharge', '₱${paymentData['surcharge'] ?? 0}'),
                      if (paymentData.containsKey('total'))
                        _buildDetailRows('Partial Amount', '₱${paymentData['total'] ?? 0}'),
                      const Divider(),
                      _buildDetailRows('Total', '₱${paymentData['totalAmountDue'] ?? paymentData['total'] ?? 0}', labelColor: Colors.black, isBold: true),
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

  void _showOverduePaymentDetails(DocumentSnapshot payment) {
    var paymentData = payment.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // Remove default padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0), // Green padding at the top
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
                      _buildDetailRows('First Name', paymentData['firstName'] ?? 'N/A'),
                      _buildDetailRows('Middle Name', paymentData['middleName'] ?? 'N/A'),
                      _buildDetailRows('Last Name', paymentData['lastName'] ?? 'N/A'),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      _buildDetailRows('Billing Cycle', paymentData['billingCycle'] ?? 'N/A'),
                      _buildDetailRows('Status', paymentData['status'] ?? 'N/A'),
                      _buildDetailRows('Due Date', DateFormat.yMMMMd('en_US').format((paymentData['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now())),
                      _buildDetailRows('Number of Days', (paymentData['noOfDays'] ?? 0).toString()),
                      _buildDetailRows('Garbage Fee', '₱${paymentData['garbageFee'] ?? 0}'),
                      _buildDetailRows('Penalty', '₱${paymentData['penalty'] ?? 0}'),
                      _buildDetailRows('Surcharge', '₱${paymentData['surcharge'] ?? 0}'),
                      _buildDetailRows('Partial Amount', '₱${paymentData['total'] ?? 0}'),
                      const Divider(),
                      _buildDetailRows('Total Amount Due', '₱${paymentData['totalAmountDue'] ?? 0}', labelColor: Colors.black, isBold: true),
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
  var data = widget.vendor.data() as Map<String, dynamic>;
  var stallInfo = data['stallInfo'] as Map<String, dynamic>;
  List<DocumentSnapshot> filteredPayments = _selectedStatus == 'Paid' ? _filterPaidPayments() : _filterPaymentsByStatus(_selectedStatus);
  Map<String, List<DocumentSnapshot>> groupedPayments = _groupPaymentsByMonth(filteredPayments);

  // Calculate the total amount for unpaid payments
  num totalAmount = filteredPayments.fold<num>(0.0, (num sum, payment) {
    var paymentData = payment.data() as Map<String, dynamic>;
    if (paymentData['status'] == 'Pending') {
      return sum + (paymentData['total'] is int ? paymentData['total'].toDouble() : paymentData['total'] ?? 0.0);
    } else if (paymentData['status'] == 'Overdue') {
      return sum + (paymentData['totalAmountDue'] is int ? paymentData['totalAmountDue'].toDouble() : paymentData['totalAmountDue'] ?? 0.0);
    }
    return sum;
  });

  DateTime now = DateTime.now();
  bool canMarkAsPaid = filteredPayments.isNotEmpty && filteredPayments.every((payment) {
    var paymentData = payment.data() as Map<String, dynamic>;
    String billingCycle = paymentData['billingCycle'] ?? 'N/A';
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
        }
        ),
        title: const Text(
          "Stall Holders",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, // White background
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0), // Padding around the container
                margin: const EdgeInsets.only(top: 40.0), // Adjust the top margin to overlap with the green container
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoColumn(Icons.location_on, 'Location', stallInfo['location'] ?? 'N/A'),
                    _buildInfoColumn(Icons.calendar_today, 'Approved At', DateFormat.yMMMMd('en_US').format((data['approvedAt'] as Timestamp?)?.toDate() ?? DateTime.now())),
                    _buildInfoColumn(Icons.phone, 'Contact Number', data['contactNumber'] ?? 'N/A'),
                    if (_isExpanded) ...[
                      _buildInfoColumn(Icons.email, 'Email', data['email'] ?? 'N/A'),
                      _buildInfoColumn(Icons.person_add, 'Approved By', data['approvedBy'] ?? 'N/A'),
                      _buildInfoColumn(Icons.date_range, 'Date of Registration', DateFormat.yMMMMd('en_US').format((data['dateOfRegistration'] as Timestamp?)?.toDate() ?? DateTime.now())),
                      _buildInfoColumn(Icons.location_city, 'Barangay', data['barangay'] ?? 'N/A'),
                      _buildInfoColumn(Icons.location_city, 'City', data['city'] ?? 'N/A'),
                    ],
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isExpanded ? 'See Less' : 'See More',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.green, // Green background
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)), // Rounded top corners
                ),
                padding: const EdgeInsets.all(16.0), // Padding around the container
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300], // Set a background color
                      child: ClipOval(
                        child: Image.network(
                          data['profileImageUrls']?[0] ?? '', // Display the profile image
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded( // Allow full name to expand
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ensure full name is displayed correctly
                          Text(
                            '${data['firstName'] ?? 'N/A'} ${data['middleName'] ?? 'N/A'} ${data['lastName'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white, // Change text color to white for contrast
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stall Number: ${stallInfo['stallNumber'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 226, 220, 220), // Change text color to white for contrast
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Billing Cycle: ${data['billingCycle'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 226, 220, 220), // Change text color to white for contrast
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 1), // Space between the containers
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusButton('Unpaid'),
                _buildStatusButton('Paid'),
              ],
            ),
          ),
          const SizedBox(height: 16), // Space between the buttons and the payment details
          if (_selectedStatus == 'Unpaid')
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (filteredPayments.isNotEmpty)
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
                          children: filteredPayments.map((payment) {
                            var paymentData = payment.data() as Map<String, dynamic>;
                            if (paymentData['status'] == 'Pending') {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoColumnWithViewLink(
                                    Icons.calendar_today,
                                    'Due: ${DateFormat.yMMMMd('en_US').format((paymentData['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                                    '',
                                    subtitle: 'Billing Cycle: ${paymentData['billingCycle'] ?? 'N/A'}',
                                    iconColor: Colors.green,
                                    amount: 'Amount: ₱${paymentData['total'] ?? 0}',
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
                          children: filteredPayments.map((payment) {
                            var paymentData = payment.data() as Map<String, dynamic>;
                            if (paymentData['status'] == 'Overdue') {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoColumnWithViewLink(
                                    Icons.calendar_today,
                                    'Due Last: ${DateFormat.yMMMMd('en_US').format((paymentData['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                                    '',
                                    subtitle: 'Billing Cycle: ${paymentData['billingCycle'] ?? 'N/A'}',
                                    iconColor: Colors.green,
                                    amount: 'Amount: ₱${paymentData['totalAmountDue'] ?? 0}',
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
                  // const Divider(), // Add a divider for separation
                  _buildDetailRows(
                    'Total Amount',
                    '₱$totalAmount',
                    labelColor: Colors.black,
                    isBold: true,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: canMarkAsPaid
                          ? () => _markAsPaid(filteredPayments)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('You cannot mark as paid at this time.'),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjust padding for the button
                        backgroundColor: canMarkAsPaid ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Mark as Paid',
                        style: TextStyle(fontSize: 14), // Adjust text size for the button
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_selectedStatus == 'Paid')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (groupedPayments.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groupedPayments.keys.map((month) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            month,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: groupedPayments[month]!.map((payment) {
                              var paymentData = payment.data() as Map<String, dynamic>;
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16.0),
                                margin: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoColumnWithViewLink(
                                      Icons.calendar_today,
                                      'Paid on: ${DateFormat.yMMMMd('en_US').format((paymentData['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                                      '',
                                      subtitle: 'Billing Cycle: ${paymentData['billingCycle'] ?? 'N/A'}',
                                      iconColor: Colors.green,
                                      amount: 'Amount: ₱${paymentData.containsKey('totalAmountDue') ? paymentData['totalAmountDue'] : paymentData['total']}',
                                      payment: payment,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    }).toList(),
                  )
                else
                  const Text('No payments found for the selected status.'),
              ],
            )
          else
            const Text('No payments found for the selected status.'),
        ],
      ),
    ),
  );
}


  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Reduced space between rows
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5), // Reduced space before label
          Padding(
            padding: const EdgeInsets.only(left: 40.0), // Increased left padding for the label
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 2), // Reduced space between label and value
          Row(
            children: [
              Icon(icon, color: const Color.fromARGB(255, 152, 151, 151)), // Add icon for each label
              const SizedBox(width: 8), // Space between icon and value
              Expanded( // Allow value to occupy remaining space
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0), // Space to align with underline
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1), // Add a divider for separation
        ],
      ),
    );
  }

  // Helper method to build label-value rows with underline and view link
  Widget _buildInfoColumnWithViewLink(IconData icon, String label, String value, {String? subtitle, Color? iconColor, String? amount, DocumentSnapshot? payment, VoidCallback? onViewTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Reduced space between rows
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5), // Reduced space before label
          Row(
            children: [
              Icon(icon, color: iconColor ?? const Color.fromARGB(255, 152, 151, 151)), // Add icon for each label
              const SizedBox(width: 8), // Space between icon and value
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red, // Change color to red
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
          const SizedBox(height: 2), // Reduced space between label and value
          Padding(
            padding: const EdgeInsets.only(left: 40.0), // Increased left padding for the label
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
          const Divider(thickness: 1), // Add a divider for separation
        ],
      ),
    );
  }

  // Helper method to build status buttons
  Widget _buildStatusButton(String label) {
    bool isSelected = _selectedStatus == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = label;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            borderRadius: isSelected ? BorderRadius.zero : BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.green,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
