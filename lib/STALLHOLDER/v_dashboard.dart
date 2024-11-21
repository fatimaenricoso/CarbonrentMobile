import 'package:ambulantcollector/STALLHOLDER/mainscaffold.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  User? _currentUser;
  Map<String, dynamic>? _vendorData;
  List<Map<String, dynamic>> _recentPayments = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      await _fetchVendorData(_currentUser!.email!);
      await _fetchRecentPayments(_vendorData?['vendorId']);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchVendorData(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('approvedVendors')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _vendorData = querySnapshot.docs.first.data();
        });
      }
    } catch (e) {
      print('Error fetching vendor data: $e');
    }
  }

  Future<void> _fetchRecentPayments(String? vendorId) async {
    if (vendorId == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stall_payment')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('date', descending: true)
          .limit(2)
          .get();

      setState(() {
        _recentPayments = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error fetching recent payments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2,
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopContainer(),
                  SizedBox(height: 20),
                  Divider(color: Colors.grey, thickness: 1), // Horizontal line
                  SizedBox(height: 20),
                  _buildRecentPaymentsContainer(),
                ],
              ),
            ),
    );
  }

  Widget _buildTopContainer() {
    if (_vendorData == null) return SizedBox.shrink();

    final billingCycle = _vendorData!['billingCycle'] ?? 'N/A';
    final totalBalance = _vendorData!['totalBalance'] ?? 'N/A';
    final nextRentalDueDate = _vendorData!['nextRentalDueDate'] ?? 'N/A';

    return Container(
      height: 150,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTopContainerItem('Billing Cycle', billingCycle),
            _buildTopContainerItem('Total Payment', totalBalance),
            _buildTopContainerItem('Due Date', nextRentalDueDate),
          ],
        ),
      ),
    );
  }

  Widget _buildTopContainerItem(String label, String value) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 41, 98, 46), // Radiant Green
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 16, color: const Color.fromARGB(179, 142, 89, 89)),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPaymentsContainer() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Payment History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 20, thickness: 1),
            _recentPayments.isEmpty
                ? Text(
                    'No recent payments found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  )
                : Column(
                    children: _recentPayments.map((payment) {
                      final date =
                          payment['date']?.toDate()?.toLocal()?.toString() ??
                              'N/A';
                      final amount = payment['amount'] ?? 'N/A';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Date: $date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Amount: $amount',
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
