import 'package:ambulantcollector/screens/StallBillingConfig.dart';
import 'package:ambulantcollector/screens/StallHistory.dart';
import 'package:ambulantcollector/screens/StallProfile.dart';
import 'package:ambulantcollector/screens/StallVendorlist.dart';
import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StallDashboard extends StatefulWidget {
  const StallDashboard({Key? key}) : super(key: key);

  @override
  _StallDashboardState createState() => _StallDashboardState();
}

class _StallDashboardState extends State<StallDashboard> {
  int _selectedIndex = 2; // Set to the Dashboard by default
  String currentUserEmail = '';
  double totalAmountPaidToday = 0.0; // Total amount for the day

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDetails(); // Fetch user's details on initialization
  }

  // Fetch the current user's email using Firebase Auth
  Future<void> _fetchCurrentUserDetails() async {
    try {
      currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      if (mounted) {
        setState(() {}); // Trigger rebuild with updated user email
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  // Start listening to the payment updates in real-time
  Stream<double> _totalAmountPaidTodayStream() {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return FirebaseFirestore.instance
        .collection('stall_payment')
        .where('status', isEqualTo: 'paid')
        .snapshots()
        .map((paymentSnapshot) {
      double totalAmount = 0.0;
      for (var doc in paymentSnapshot.docs) {
        Timestamp paymentDate = doc['paymentDate'];
        String paymentDateString = DateFormat('yyyy-MM-dd').format(paymentDate.toDate());

        // Check if payment is made today
        if (paymentDateString == todayDate) {
          if (doc.data().containsKey('totalAmountDue')) {
            totalAmount += (doc['totalAmountDue'] as num).toDouble();
          } else {
            totalAmount += (doc['total'] as num).toDouble();
          }
        }
      }
      return totalAmount;
    });
  }

  final List<Widget> _screens = [
    const StallHistory(),
    const StallScreen(),
    const StallDashboard(),
    const StallPending(),
    const StallProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget bottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.green,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.white,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      iconSize: 20,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Stall',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pending_actions),
          label: 'Pending',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 60, // Increased height
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                ),
                child: const Center(
                  child: Text(
                    'Confirm Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Are you sure you want to logout?'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('No', style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Yes', style: TextStyle(color: Colors.green)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logout();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 2
          ? AppBar(
              title: const Text(
                "Stall Collector Dashboard",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              backgroundColor: Colors.green,
              centerTitle: true,
              automaticallyImplyLeading: false, // Remove the back button
            )
          : null, // No AppBar for other screens
      body: _selectedIndex == 2
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: StreamBuilder<double>(
                        stream: _totalAmountPaidTodayStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasData) {
                            totalAmountPaidToday = snapshot.data!;
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Collected Today',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₱${totalAmountPaidToday.toStringAsFixed(2)}', // Display amount in PHP
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _confirmLogout,
                                child: const Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      "Logout",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Add more widgets for the dashboard as needed
                  ],
                ),
              ),
            )
          : _screens[_selectedIndex],
      bottomNavigationBar: bottomNavigationBar(),
    );
  }
}
