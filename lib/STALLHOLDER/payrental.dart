//updated on 11.21.2024
import 'package:ambulantcollector/STALLHOLDER/history_payment.dart';
import 'package:ambulantcollector/STALLHOLDER/mainscaffold.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
import 'payment_details.dart'; // Import the new file

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  User? currentUser;
  Map<String, dynamic>? recentPendingPayment;
  List<Map<String, dynamic>> overduePayments = [];
  double totalOverdueAmount = 0.0;
  String? documentIDasReferenceID;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    initializePaymentData();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> initializePaymentData() async {
    try {
      setState(() {
        isLoading = true;
      });

      currentUser = _auth.currentUser;
      await fetchRecentPendingPayment();
      await fetchOverduePayments();
      await checkAndScheduleNextPayment(); // Ensure this is called to schedule the next payment
    } catch (e) {
      print('Error initializing payment data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchRecentPendingPayment() async {
    try {
      final paymentsQuery = await FirebaseFirestore.instance
          .collection('stall_payment')
          .where('vendorId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'Pending')
          .orderBy('dueDate', descending: true)
          .limit(1)
          .get();

      if (paymentsQuery.docs.isNotEmpty) {
        DocumentSnapshot paymentDocument = paymentsQuery.docs.first;
        documentIDasReferenceID = paymentDocument.id; // Get the document ID
        print('Document ID as reference ID: $documentIDasReferenceID');
        setState(() {
          recentPendingPayment =
              paymentsQuery.docs.first.data() as Map<String, dynamic>;
        });
      } else {
        print('No pending payments found.');
      }
    } catch (e) {
      print('Error fetching recent pending payment: $e');
    }
  }

  Future<void> fetchOverduePayments() async {
    try {
      final paymentsQuery = await FirebaseFirestore.instance
          .collection('stall_payment')
          .where('vendorId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'Overdue')
          .get();

      if (paymentsQuery.docs.isNotEmpty) {
        for (var doc in paymentsQuery.docs) {
          await updateOverduePayment(
              doc.id, doc.data() as Map<String, dynamic>);
        }
        setState(() {
          overduePayments = paymentsQuery.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          totalOverdueAmount = overduePayments
              .map((payment) => payment['totalAmountDue'] as double)
              .reduce((a, b) => a + b);
        });
      } else {
        print('No overdue payments found.');
      }
    } catch (e) {
      print('Error fetching overdue payments: $e');
    }
  }

  Future<void> paymentCheckout(double amountDue) async {
    final url = Uri.parse('https://api.paymongo.com/v1/checkout_sessions');
    const credentials =
        'Basic c2tfdGVzdF9VV1AzaFhWUm9CQWs0R3vIOFE4NUR2cms6YzJ0ZmRHVnpkRjlWVjFBemFGaFdVbTlDUVdzMFIzVklPRkU0TlVSMmNtczY='; // Replace with actual credentials
    final body = {
      'data': {
        'type': 'checkout_session',
        'attributes': {
          'success_url':
              'https://redirecting-flutter-checkout-paymongo.netlify.app/',
          'cancel_url':
              'https://redirecting-flutter-checkout-paymongo.netlify.app/',
          'payment_method_allowed': ['card', 'gcash', 'grab_pay', 'paymaya'],
          'payment_method_options': {
            'card': {'request_three_d_secure': 'any'}
          },
          'payment_method_types': [
            // 'card',
            'gcash',
            // 'grab_pay',
            // 'paymaya',
          ],
          'description': 'Rental Payment',
          'line_items': [
            {
              'name': 'Test Item',
              'quantity': 1,
              'amount': (amountDue * 100).toInt(),
              'currency': 'PHP',
            },
          ],
          'billing': {
            'name': 'Payor Name',
          },
          "reference_number": documentIDasReferenceID,
          'statement_descriptor': 'string',
        }
      }
    };

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': credentials,
    };

    final response =
        await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      print(response.body);
      var responseBody = jsonDecode(response.body);
      print(responseBody);
      print('Checkout Session ID: ${responseBody['data']['id']}');
      var checkoutURL =
          Uri.parse(responseBody['data']['attributes']['checkout_url']);
      // Using the checkout_session.payment.paid webhooks = ['data']['attributes']['data']['attributes']['payments']['attributes']['status']
      print(checkoutURL);
      if (await canLaunchUrl(checkoutURL)) {
        await launchUrl(
          checkoutURL,
          mode: LaunchMode.externalApplication,
          // mode: LaunchMode.inAppWebView,
        );
        await updatePaymentStatus(amountDue);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(),
          ),
        );
      } else {
        throw 'Could not launch $checkoutURL';
      }
    } else {
      print('Error: ${response.body}');
    }
  }

  Future<void> updatePaymentStatus(double amountDue) async {
    try {
      final paymentDocRef = FirebaseFirestore.instance
          .collection('stall_payment')
          .doc(documentIDasReferenceID);

      await paymentDocRef.update({
        'status': 'Paid',
        'paymentDate': DateTime.now(),
      });

      // Fetch billing configuration
      final billingConfigSnapshot =
          await FirebaseFirestore.instance.collection('billingconfig').get();
      final billingConfig =
          billingConfigSnapshot.docs.fold<Map<String, dynamic>>({}, (acc, doc) {
        acc[doc.data()['title']] = doc.data();
        return acc;
      });

      // Fetch the current payment document
      final paymentDoc = await paymentDocRef.get();
      final paymentData = paymentDoc.data() as Map<String, dynamic>;

      // Calculate the next due date based on the billing cycle
      final dueDate = (paymentData['dueDate'] as Timestamp).toDate();
      final billingCycle = paymentData['billingCycle'];
      DateTime nextDueDate = DateTime.now(); // Initialize with a default value
      int noOfDays = 0; // Initialize with a default value

      if (billingCycle == 'Daily') {
        nextDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day + 1);
        noOfDays = 1;
      } else if (billingCycle == 'Weekly') {
        nextDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day + 7);
        noOfDays = 7;
      } else if (billingCycle == 'Monthly') {
        nextDueDate = DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
        noOfDays = DateTime(dueDate.year, dueDate.month + 1, 0).day;
      }

      // Calculate the daily payment
      final ratePerMeter = billingConfig['RateperMeter']['value1'];
      final stallSize = paymentData['stallSize'];
      final dailyPayment = ratePerMeter * stallSize;

      // Calculate the amount
      final amount = dailyPayment * noOfDays;

      // Calculate the garbage fee
      final garbageFee = billingConfig['Garbage Fee']['value1'] * noOfDays;

      // Calculate the penalty if the vendor status is overdue
      double penalty = 0;
      double surcharge = 0;
      if (paymentData['status'] == 'Overdue') {
        final penaltyPercentage =
            billingConfig['Penalty'][billingCycle == 'Daily'
                ? 'value3'
                : billingCycle == 'Weekly'
                    ? 'value2'
                    : 'value1'];
        penalty = penaltyPercentage;
        surcharge = penalty + (amount * penaltyPercentage / 100);
      }

      // Calculate the total
      final total = amount + garbageFee + surcharge;

      // Check if there is already a pending payment for the next due date
      final pendingPaymentsQuery = await FirebaseFirestore.instance
          .collection('stall_payment')
          .where('vendorId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'Pending')
          .where('dueDate', isGreaterThanOrEqualTo: nextDueDate)
          .get();

      if (pendingPaymentsQuery.docs.isEmpty) {
        // Store the next payment in the stall_payment collection with an auto ID
        await FirebaseFirestore.instance.collection('stall_payment').add({
          'vendorId': currentUser?.uid,
          'firstName': paymentData['firstName'],
          'middleName': paymentData['middleName'],
          'lastName': paymentData['lastName'],
          'status': 'Pending',
          'currentDate': DateTime.now(),
          'dueDate': nextDueDate,
          'noOfDays': noOfDays,
          'dailyPayment': dailyPayment,
          'amount': amount,
          'garbageFee': garbageFee,
          'penalty': penalty,
          'surcharge': surcharge,
          'total': total,
          'billingCycle': billingCycle,
        });
      }

      // Optionally, you can store additional payment details if needed
      await storePaymentDetails(amountDue);
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }

  Future<void> storePaymentDetails(double amountDue) async {
    try {
      final vendorDoc = await FirebaseFirestore.instance
          .collection('approvedVendors')
          .doc(currentUser?.uid)
          .get();

      if (!vendorDoc.exists) {
        print('No vendor found with ID: ${currentUser?.uid}');
        return;
      }

      final vendorData = vendorDoc.data() as Map<String, dynamic>;
      final firstName = vendorData['firstName'];
      final middleName = vendorData['middleName'];
      final lastName = vendorData['lastName'];

      final paymentDocRef =
          FirebaseFirestore.instance.collection('stall_payment').doc();

      await paymentDocRef.set({
        'vendorId': currentUser?.uid,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'status': 'Paid',
        'amountDue': amountDue,
        'paymentDate': DateTime.now(),
        'numOfDays': recentPendingPayment?['noOfDays'] ?? 0,
        'dailyRent': recentPendingPayment?['dailyPayment'] ?? 0.0,
        'garbageFee': recentPendingPayment?['garbageFee'] ?? 0.0,
        'surcharge': recentPendingPayment?['surcharge'] ?? 0.0,
        'totalAmountDue': amountDue,
        'dueDate': recentPendingPayment?['dueDate'] ??
            DateTime.now(), // Store the due date in Firestore
        'billingCycle': recentPendingPayment?['billingCycle'] ??
            'monthly', // Store the billing cycle in Firestore
      });
    } catch (e) {
      print('Error storing payment details: $e');
    }
  }

  Future<void> checkAndScheduleNextPayment() async {
    try {
      // Fetch the current date
      final currentDate = DateTime.now();

      // Fetch the current user's billing cycle
      final vendorDoc = await FirebaseFirestore.instance
          .collection('approvedVendors')
          .doc(currentUser?.uid)
          .get();

      if (!vendorDoc.exists) {
        print('No vendor found with ID: ${currentUser?.uid}');
        return;
      }

      final vendorData = vendorDoc.data() as Map<String, dynamic>;
      final billingCycle = vendorData['billingCycle'];

      // Fetch billing configuration
      final billingConfigSnapshot =
          await FirebaseFirestore.instance.collection('billingconfig').get();
      final billingConfig =
          billingConfigSnapshot.docs.fold<Map<String, dynamic>>({}, (acc, doc) {
        acc[doc.data()['title']] = doc.data();
        return acc;
      });

      // Fetch the most recent payment document
      final paymentQuery = await FirebaseFirestore.instance
          .collection('stall_payment')
          .where('vendorId', isEqualTo: currentUser?.uid)
          .orderBy('dueDate', descending: true)
          .limit(1)
          .get();

      if (paymentQuery.docs.isNotEmpty) {
        final paymentData =
            paymentQuery.docs.first.data() as Map<String, dynamic>;
        final dueDate = (paymentData['dueDate'] as Timestamp).toDate();
        final status = paymentData['status'];

        // Check if the due date has passed or the status is "Paid"
        if (currentDate.isAfter(dueDate) && status == 'Pending') {
          // Update the status to "Overdue"
          await FirebaseFirestore.instance
              .collection('stall_payment')
              .doc(paymentQuery.docs.first.id)
              .update({'status': 'Overdue'});

          // Update the stored payment with new calculations
          await updateOverduePayment(paymentQuery.docs.first.id, paymentData);
        }

        if (currentDate.isAfter(dueDate) || status == 'Paid') {
          // Calculate the next due date based on the billing cycle
          DateTime nextDueDate =
              DateTime.now(); // Initialize with a default value
          int noOfDays = 0; // Initialize with a default value

          if (billingCycle == 'Daily') {
            nextDueDate =
                DateTime(dueDate.year, dueDate.month, dueDate.day + 1);
            noOfDays = 1;
          } else if (billingCycle == 'Weekly') {
            nextDueDate =
                DateTime(dueDate.year, dueDate.month, dueDate.day + 7);
            noOfDays = 7;
          } else if (billingCycle == 'Monthly') {
            nextDueDate =
                DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
            noOfDays = DateTime(dueDate.year, dueDate.month + 1, 0).day;
          }

          // Calculate the daily payment
          final ratePerMeter = billingConfig['RateperMeter']['value1'];
          final stallSize = vendorData['stallInfo']['stallSize'];
          final dailyPayment = ratePerMeter * stallSize;

          // Calculate the amount
          final amount = dailyPayment * noOfDays;

          // Calculate the garbage fee
          final garbageFee = billingConfig['Garbage Fee']['value1'] * noOfDays;

          // Calculate the penalty if the vendor status is overdue
          double penalty = 0;
          double surcharge = 0;
          if (status == 'Overdue') {
            final penaltyPercentage =
                billingConfig['Penalty'][billingCycle == 'Daily'
                    ? 'value3'
                    : billingCycle == 'Weekly'
                        ? 'value2'
                        : 'value1'];
            penalty = penaltyPercentage;
            surcharge = penalty + (amount * penaltyPercentage / 100);
          }

          // Calculate the total
          final total = amount + garbageFee + surcharge;

          // Store the next payment in the stall_payment collection with an auto ID
          await FirebaseFirestore.instance.collection('stall_payment').add({
            'vendorId': currentUser?.uid,
            'firstName': vendorData['firstName'],
            'middleName': vendorData['middleName'],
            'lastName': vendorData['lastName'],
            'status': 'Pending',
            'currentDate': currentDate,
            'dueDate': nextDueDate,
            'noOfDays': noOfDays,
            'dailyPayment': dailyPayment,
            'amount': amount,
            'garbageFee': garbageFee,
            'penalty': penalty,
            'surcharge': surcharge,
            'total': total,
            'billingCycle': billingCycle,
          });
        }
      }
    } catch (e) {
      print('Error scheduling next payment: $e');
    }
  }

  Future<void> updateOverduePayment(
      String documentID, Map<String, dynamic> paymentData) async {
    try {
      // Fetch billing configuration
      final billingConfigSnapshot =
          await FirebaseFirestore.instance.collection('billingconfig').get();
      final billingConfig =
          billingConfigSnapshot.docs.fold<Map<String, dynamic>>({}, (acc, doc) {
        acc[doc.data()['title']] = doc.data();
        return acc;
      });

      final billingCycle = paymentData['billingCycle'];

      // Calculate the penalty percentage
      final penaltyPercentage = billingConfig['Penalty'][billingCycle == 'Daily'
          ? 'value3'
          : billingCycle == 'Weekly'
              ? 'value2'
              : 'value1'];

      // Calculate the surcharge
      final surcharge = (paymentData['amount'] * penaltyPercentage / 100);

      // Calculate the total
      final total =
          paymentData['amount'] + paymentData['garbageFee'] + surcharge;

      // Calculate the number of months overdue
      final dueDate = (paymentData['dueDate'] as Timestamp).toDate();
      final currentDate = DateTime.now();
      final monthsOverdue = (currentDate.year - dueDate.year) * 12 +
          currentDate.month -
          dueDate.month;

      // Calculate the interest rate only if the overdue period spans into the next month
      final interestRate = monthsOverdue > 0 ? 0.02 * monthsOverdue : 0.0;
      final amountIntRate = total * interestRate;
      final totalAmountDue = total + amountIntRate;

      // Update the stored payment with the new values
      await FirebaseFirestore.instance
          .collection('stall_payment')
          .doc(documentID)
          .update({
        'surcharge': surcharge,
        'total': total,
        'interestRate': interestRate,
        'amountIntRate': amountIntRate,
        'totalAmountDue': totalAmountDue,
      });
    } catch (e) {
      print('Error updating overdue payment: $e');
    }
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(days: 1), (timer) {
      checkAndScheduleNextPayment();
    });
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MainScaffold(
        currentIndex: 1,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    double totalPaymentAmount =
        totalOverdueAmount + (recentPendingPayment?['total'] ?? 0.0);

    // Calculate the total of the two payments
    double totalOfTwoPayments = 0.0;
    if (overduePayments.length >= 2) {
      totalOfTwoPayments = overduePayments[0]['totalAmountDue'] +
          overduePayments[1]['totalAmountDue'];
    }

    return MainScaffold(
      currentIndex: 1,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              // Total Payment section comes first
              if (overduePayments.isNotEmpty || recentPendingPayment != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentDetailsListPage(
                            overduePayments: overduePayments,
                            recentPendingPayment: recentPendingPayment!,
                            currencyFormat: currencyFormat,
                            paymentCheckout: paymentCheckout),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overdue & Pending Payment',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormat.format(totalPaymentAmount),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                      color: Color.fromARGB(255, 119, 116, 116),
                                      width: 0.2), // Add grey border
                                ),
                              ),
                              onPressed: () {
                                paymentCheckout(totalPaymentAmount);
                              },
                              child: const Text(
                                'Pay in full',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '(${overduePayments.length} Overdue Payments & ${recentPendingPayment != null ? 1 : 0} Pending Payment)',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 5), //space
              // Overdue Payments section comes second
              if (overduePayments.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'Overdue Payments',
                    //   style: TextStyle(
                    //       fontSize: 18,
                    //       fontWeight: FontWeight.bold,
                    //       color: Colors.grey[800]),
                    // ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentDetailsListPage(
                                overduePayments: overduePayments,
                                recentPendingPayment: null,
                                currencyFormat: currencyFormat,
                                paymentCheckout: paymentCheckout),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Overdue',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),
                            ),
                            Text(
                              '(${overduePayments.length} Overdue Payments)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currencyFormat.format(totalOverdueAmount),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800]),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(
                                          color: Color.fromARGB(
                                              255, 119, 116, 116),
                                          width: 0.2), // Add grey border
                                    ),
                                  ),
                                  onPressed: () {
                                    paymentCheckout(totalOverdueAmount);
                                  },
                                  child: const Text(
                                    'Pay Now',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const Divider(),
                            const SizedBox(height: 22),
                            Text(
                              'Pay partially',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                            // const SizedBox(
                            //   height: 14,
                            // ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currencyFormat.format(totalOfTwoPayments),
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800]),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(
                                          color: Color.fromARGB(
                                              255, 119, 116, 116),
                                          width: 0.2), // Add grey border
                                    ),
                                  ),
                                  onPressed: () {
                                    paymentCheckout(totalOfTwoPayments);
                                  },
                                  child: const Text(
                                    'Pay now',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20), //space
              // Most Recent Pending Payment section comes third
              if (recentPendingPayment != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PaymentDetailsPage(recentPendingPayment!),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Most Recent Pending Payment',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormat.format(
                                  recentPendingPayment!['total'] ?? 0.0),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                      color: Color.fromARGB(255, 119, 116, 116),
                                      width: 0.2), // Add grey border
                                ),
                              ),
                              onPressed: () {
                                paymentCheckout(
                                    recentPendingPayment!['total'] ?? 0.0);
                              },
                              child: const Text(
                                'Pay Now',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRow(
                            'Due Date',
                            DateFormat('MMMM d, yyyy hh:mm a').format(
                                recentPendingPayment!['dueDate']?.toDate() ??
                                    DateTime.now())),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
