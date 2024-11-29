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
          ? (paymentData['paymentDate'] as Timestamp).toDate()
          : (paymentData['dueDate'] as Timestamp).toDate();
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
    return _allPayments.where((payment) {
      var paymentData = payment.data() as Map<String, dynamic>;
      // Map the statuses correctly
      if (status == 'Unpaid' && paymentData['status'] == 'Pending') {
        return true;
      } else if (status == 'Paid' && paymentData['status'] == 'paid') {
        return true;
      } else if (status == 'Overdue' && paymentData['status'] == 'Overdue') {
        return true;
      }
      return false;
    }).toList();
  }

  Future<void> _markAsPaid(DocumentSnapshot payment) async {
    bool shouldProceed = await showConfirmationDialog(context, payment);

    if (shouldProceed) {
      await FirebaseFirestore.instance
          .collection('stall_payment')
          .doc(payment.id)
          .update({
        'status': 'paid',
        'paymentDate': Timestamp.fromDate(DateTime.now()),
        'paidBy': 'cash'
      });
      _fetchAllPayments(); // Refresh the payments list
      _showPaymentMarkedDialog();
    }
  }

  Future<bool> showConfirmationDialog(BuildContext context, DocumentSnapshot payment) async {
    var paymentData = payment.data() as Map<String, dynamic>;
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
                        'Please confirm that you want to mark this payment as paid.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Details',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 13),
                      _buildDetailRows('First Name', paymentData['firstName']),
                      _buildDetailRows('Middle Name', paymentData['middleName']),
                      _buildDetailRows('Last Name', paymentData['lastName']),
                      _buildDetailRows('Billing Cycle', paymentData['billingCycle']),
                      _buildDetailRows('Status', paymentData['status']),
                      _buildDetailRows('Due Date', DateFormat.yMMMMd('en_US').format((paymentData['dueDate'] as Timestamp).toDate())),
                      _buildDetailRows('Number of Days', paymentData['noOfDays'].toString()),
                      _buildDetailRows('Garbage Fee', '₱${paymentData['garbageFee']}'),
                      _buildDetailRows('Penalty', '₱${paymentData['penalty']}'),
                      _buildDetailRows('Surcharge', '₱${paymentData['surcharge']}'),
                      const Divider(),
                      _buildDetailRows('Total', '₱${paymentData['total']}', labelColor: Colors.black, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Text(
                    'Do you want to mark this payment as paid?',
                    style: TextStyle(fontSize: 13),
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
                      'The payment has been successfully marked as paid.',
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                      _buildDetailRows('First Name', paymentData['firstName']),
                      _buildDetailRows('Middle Name', paymentData['middleName']),
                      _buildDetailRows('Last Name', paymentData['lastName']),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      _buildDetailRows('Billing Cycle', paymentData['billingCycle']),
                      _buildDetailRows('Status', paymentData['status']),
                      _buildDetailRows('Due Date', DateFormat.yMMMMd('en_US').format((paymentData['dueDate'] as Timestamp).toDate())),
                      _buildDetailRows('Number of Days', paymentData['noOfDays'].toString()),
                      _buildDetailRows('Garbage Fee', '₱${paymentData['garbageFee']}'),
                      _buildDetailRows('Penalty', '₱${paymentData['penalty']}'),
                      _buildDetailRows('Surcharge', '₱${paymentData['surcharge']}'),
                      const Divider(),
                      _buildDetailRows('Total', '₱${paymentData['total']}', labelColor: Colors.black, isBold: true),
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
    List<DocumentSnapshot> filteredPayments = _filterPaymentsByStatus(_selectedStatus);
    Map<String, List<DocumentSnapshot>> groupedPayments = _groupPaymentsByMonth(filteredPayments);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendor Details"),
        backgroundColor: Colors.green,
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
                      _buildInfoColumn(Icons.location_on, 'Location', stallInfo['location']),
                      _buildInfoColumn(Icons.calendar_today, 'Approved At', DateFormat.yMMMMd('en_US').format((data['approvedAt'] as Timestamp).toDate())),
                      _buildInfoColumn(Icons.phone, 'Contact Number', data['contactNumber']),
                      if (_isExpanded) ...[
                        _buildInfoColumn(Icons.email, 'Email', data['email']),
                        _buildInfoColumn(Icons.person_add, 'Approved By', data['approvedBy']),
                        _buildInfoColumn(Icons.date_range, 'Date of Registration', DateFormat.yMMMMd('en_US').format((data['dateOfRegistration'] as Timestamp).toDate())),
                        _buildInfoColumn(Icons.location_city, 'Barangay', data['barangay']),
                        _buildInfoColumn(Icons.location_city, 'City', data['city']),
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
                            data['profileImageUrls'][0], // Display the profile image
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
                              '${data['firstName']} ${data['middleName']} ${data['lastName']}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white, // Change text color to white for contrast
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stall Number: ${stallInfo['stallNumber']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 226, 220, 220), // Change text color to white for contrast
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Billing Cycle: ${data['billingCycle']}',
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
                  _buildStatusButton('Overdue'),
                  _buildStatusButton('Paid'),
                ],
              ),
            ),
            const SizedBox(height: 16), // Space between the buttons and the payment details
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
                          return GestureDetector(
                            onTap: () => _showPaymentDetails(payment),
                            child: Container(
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
                                  _buildInfoColumnWithButton(
                                    Icons.calendar_today,
                                    _selectedStatus == 'Paid' ? 'Paid on' : 'Due',
                                    _selectedStatus == 'Paid'
                                        ? DateFormat.yMMMMd('en_US').format((paymentData['paymentDate'] as Timestamp).toDate())
                                        : DateFormat.yMMMMd('en_US').format((paymentData['dueDate'] as Timestamp).toDate()),
                                    subtitle: 'Amount: ₱${paymentData['total']}',
                                    payment: payment,
                                    billingCycle: paymentData['billingCycle'],
                                    dueDate: (paymentData['dueDate'] as Timestamp).toDate(),
                                    billingCycleText: paymentData['billingCycle'], // Pass the billing cycle text
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }

  // Helper method to build label-value rows with underline
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

  // Helper method to build label-value rows with underline and a button
  Widget _buildInfoColumnWithButton(IconData icon, String label, String value, {String? subtitle, DocumentSnapshot? payment, required String billingCycle, required DateTime dueDate, required String billingCycleText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Reduced space between rows
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 0), // Reduced space before label
          Padding(
            padding: const EdgeInsets.only(left: 40.0), // Increased left padding for the label
            child: Text(
              '$label: $value', // Combine label and value
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red, // Change color to red
              ),
            ),
          ),
          const SizedBox(height: 0), // Reduced space between label and value
          Row(
            children: [
              Icon(icon, color: Colors.green), // Change icon color to green
              const SizedBox(width: 8), // Space between icon and value
              Expanded( // Allow value to occupy remaining space
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0), // Space to align with underline
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Billing Cycle: $billingCycleText', // Display the billing cycle
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_selectedStatus == 'Unpaid' || _selectedStatus == 'Overdue')
                ElevatedButton(
                  onPressed: _isMarkAsPaidButtonEnabled(billingCycle, dueDate) ? () => _markAsPaid(payment!) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Adjust padding for smaller button
                    minimumSize: const Size(40, 20), // Adjust minimum size for smaller button
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Mark as Paid',
                    style: TextStyle(fontSize: 12), // Adjust text size for larger text
                  ),
                ),
            ],
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

  // Helper method to build detail rows for the dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  bool _isMarkAsPaidButtonEnabled(String billingCycle, DateTime dueDate) {
    DateTime now = DateTime.now();

    if (billingCycle.toLowerCase() == 'daily') {
      // Check if today is the due date
      return now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day;
    } else if (billingCycle.toLowerCase() == 'weekly') {
      // Check if today is the due date and it is a Monday
      return now.weekday == DateTime.monday && now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day;
    } else if (billingCycle.toLowerCase() == 'monthly') {
      // Check if today is within the first 7 days of the due date month and not before the due date
      DateTime startOfMonth = DateTime(dueDate.year, dueDate.month, 1);
      DateTime endOfMonth = DateTime(dueDate.year, dueDate.month, 7);
      return now.isAfter(startOfMonth) && now.isBefore(endOfMonth.add(const Duration(days: 1))) && now.isBefore(dueDate);
    }
    return false;
  }
}
