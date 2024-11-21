// import 'package:ambulantcollector/STALLHOLDER/pending_payment.dart';
import 'package:ambulantcollector/STALLHOLDER/payrental.dart';
import 'package:ambulantcollector/STALLHOLDER/rent_details.dart';
import 'package:ambulantcollector/STALLHOLDER/v_dashboard.dart';
import 'package:ambulantcollector/STALLHOLDER/profile_page.dart';
import 'package:ambulantcollector/STALLHOLDER/settings_page.dart';
import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MainScaffold extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    Key? key,
    required this.child,
    this.currentIndex = 2, // Default to "Home" tab
  }) : super(key: key);

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? vendorData;
  String? vendorId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _fetchVendorData();
  }

  Future<void> _fetchVendorData() async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('approvedVendors')
            .where('email', isEqualTo: currentUser.email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final vendorDoc = querySnapshot.docs.first;
          setState(() {
            vendorData = vendorDoc.data();
            vendorId = vendorDoc.id; // Store the document ID
          });
          print('Vendor Data: $vendorData');
          print('Vendor ID: $vendorId');
        } else {
          print('No approved vendor found for the current user.');
        }
      } catch (e) {
        print('Error fetching vendor data: $e');
      }
    } else {
      print('No user is currently signed in.');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      switch (_currentIndex) {
        case 0:
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => RentdetailsPage()));
          break;
        case 1:
          if (vendorId != null && vendorData != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(),
              ),
            );
          } else {
            // Show loading indicator while fetching data
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Loading vendor data. Please wait...'),
                duration: Duration(seconds: 2),
              ),
            );
            // Retry fetching vendor data
            _fetchVendorData().then((_) {
              if (vendorId != null && vendorData != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Unable to load payment screen. Please try again.'),
                  ),
                );
              }
            });
          }
          break;
        case 2:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomePage()));
          break;
        case 3:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => ProfilePage()));
          break;
        case 4:
        // Navigator.pushReplacement(context,
        //     MaterialPageRoute(builder: (context) => PendingPaymentPage()));
        // break;
      }
    });
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UnifiedLoginScreen()),
      );
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map index to app bar titles
    final titles = [
      'Rent History',
      'Pay Rent',
      'Home Page',
      'Profile Page',
      // 'Pending Payments',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          titles[_currentIndex], // Use the current index to set the title
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: _logout,
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Fixes background color
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.green,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        selectedIconTheme: const IconThemeData(
            color: Colors.black), // Ensures selected icon is black
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Rent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.pending),
          //   label: 'Pending Payment',
          // ),
        ],
      ),
    );
  }
}
