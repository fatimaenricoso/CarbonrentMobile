import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'collectorreceipt.dart'; // Import the CollectorReceipt page

class CollectorSpace extends StatefulWidget {
  @override
  _CollectorSpaceState createState() => _CollectorSpaceState();
}

class _CollectorSpaceState extends State<CollectorSpace> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? collectorZone;
  String? collectorLocation;
  String? collectorEmail;
  String? collectorAddress;
  String? collectorContact;
  String? collectors; // Added collector field
  String? collectorId; // Added collector ID field
  double? spaceRate;
  int _numberOfTickets = 0;
  double _totalAmount = 0.0;
  TextEditingController _numberOfTicketsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCollectorDetails();
    _fetchSpaceRate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset the form state when the widget is rebuilt
    _resetForm();
  }

  Future<void> _fetchCollectorDetails() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      var collectorSnapshot = await _firestore
          .collection('ambulant_collector')
          .where('email', isEqualTo: user.email)
          .get();

      if (collectorSnapshot.docs.isNotEmpty) {
        var collectorData = collectorSnapshot.docs.first.data() as Map<String, dynamic>;
        collectorZone = collectorData['zone'];
        collectorLocation = collectorData['location'];
        collectorEmail = collectorData['email'];
        collectorAddress = collectorData['Address_collector'];
        collectorContact = collectorData['contact_collector'];
        collectors = collectorData['collector']; // Fetch collector field
        collectorId = collectorSnapshot.docs.first.id; // Fetch collector ID
        collectorLocation = collectorData['location']; // Fetch collector location
      }
    } catch (e) {
      // print('Error fetching collector details: $e');
    }
  }

  Future<void> _fetchSpaceRate() async {
    try {
      var rateSnapshot = await _firestore.collection('rate').get();
      for (var doc in rateSnapshot.docs) {
        if (doc.data().containsKey('space_rate')) {
          setState(() {
            spaceRate = doc.data()['space_rate']?.toDouble();
          });
          break;
        }
      }
    } catch (e) {
      // print('Error fetching space rate: $e');
    }
  }

  void _incrementTickets() {
    setState(() {
      _numberOfTickets++;
      _numberOfTicketsController.text = _numberOfTickets.toString();
      _calculateTotalAmount();
    });
  }

  void _decrementTickets() {
    setState(() {
      _numberOfTickets = _numberOfTickets > 0 ? _numberOfTickets - 1 : 0;
      _numberOfTicketsController.text = _numberOfTickets.toString();
      _calculateTotalAmount();
    });
  }

  void _calculateTotalAmount() {
    setState(() {
      _totalAmount = (spaceRate ?? 0) * _numberOfTickets;
    });
  }

  Future<int> _getNextVendorNumber() async {
    var today = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(today);
    DocumentReference vendorNumberDoc = _firestore.collection('vendor_numbers').doc(formattedDate);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(vendorNumberDoc);

      if (!snapshot.exists) {
        transaction.set(vendorNumberDoc, {'current_vendor_number': 1});
        return 1;
      }

      int currentVendorNumber = (snapshot.data() as Map<String, dynamic>)['current_vendor_number'] ?? 0;
      int nextVendorNumber = currentVendorNumber + 1;
      transaction.update(vendorNumberDoc, {'current_vendor_number': nextVendorNumber});
      return nextVendorNumber;
    });
  }

  Future<void> _addPayment(int numberOfTickets) async {
    var today = DateTime.now();
    DateFormat('yyyy-MM-dd').format(today);

    int vendorNumber = await _getNextVendorNumber();
    print('Next vendor_number: $vendorNumber');

    try {
      DocumentReference paymentDocRef = await _firestore.collection('payment_ambulant').add({
        'date': today,
        'zone': collectorZone,
        'number_of_tickets': numberOfTickets,
        'space_rate': spaceRate,
        'total_amount': _totalAmount,
        'collector_email': collectorEmail,
        'collector_address': collectorAddress,
        'collector_contact': collectorContact,
        'vendor_number': vendorNumber,
        'collector': collectors, // Store collector field
        'vendorId': collectorId, // Store collector ID
        'location': collectorLocation, // Store collector location
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  "Success",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: const Text(
              "Successfully added payment.",
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                child: const Text("OK", style: TextStyle(color: Colors.green)),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CollectorReceipt(documentId: paymentDocRef.id),
                    ),
                  ).then((_) {
                    // Reset the form when navigating back
                    _resetForm();
                  });
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // print('Error adding payment: $e');
    }
  }

  void _resetForm() {
    setState(() {
      _numberOfTickets = 0;
      _numberOfTicketsController.text = '';
      _totalAmount = 0.0;
    });
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
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
                      'Please review all the information below before confirming. As you cannot edit or undo once confirmed.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Payment Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Zone', style: TextStyle(fontSize: 12)),
                        Text(collectorZone ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Location', style: TextStyle(fontSize: 12)),
                        Text(collectorLocation ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date', style: TextStyle(fontSize: 12)),
                        Text(DateFormat('MM/dd/yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Space Rate', style: TextStyle(fontSize: 12)),
                        Text('₱${spaceRate?.toStringAsFixed(2) ?? 'N/A'} per sqm', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Number of Tickets', style: TextStyle(fontSize: 12)),
                        Text(_numberOfTickets.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('₱${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Text(
                  'Do you want to confirm collection?',
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
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
/*             Icon(Icons.assignment, color: Colors.white),
 */            SizedBox(width: 8),
            Text("Collect Rent Payment", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zone: $collectorZone',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Location: $collectorLocation',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Date: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rate: ₱${spaceRate?.toStringAsFixed(2) ?? 'N/A'} per sqm',
                      style: const TextStyle(
                        fontSize: 15,
                        // fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          controller: _numberOfTicketsController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _numberOfTickets = int.tryParse(value) ?? 0;
                              _calculateTotalAmount();
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Enter occupied size',
                            labelStyle: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              // fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.green),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.05),
                            contentPadding: const EdgeInsets.fromLTRB(16, 16, 50, 16),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _incrementTickets,
                                child: const Icon(
                                  Icons.arrow_drop_up,
                                  color: Color(0xFF2E7D32),
                                  size: 24,
                                ),
                              ),
                              InkWell(
                                onTap: _decrementTickets,
                                child: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF2E7D32),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₱${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_numberOfTickets <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Field cannot be 0 or empty.'),
                            backgroundColor: Color.fromARGB(255, 96, 95, 95),
                          ),
                        );
                        return;
                      }
                      bool shouldProceed = await _showConfirmationDialog(context);
                      if (shouldProceed) {
                        _addPayment(_numberOfTickets);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Confirm Payment'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
