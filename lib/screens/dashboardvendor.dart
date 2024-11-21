import 'package:ambulantcollector/screens/historyvendor.dart';
import 'package:ambulantcollector/screens/notificationsvendor.dart';
import 'package:ambulantcollector/screens/paymentvendor.dart';
import 'package:ambulantcollector/screens/profilevendor.dart';
import 'package:flutter/material.dart';

class DashboardVendor extends StatefulWidget {
  const DashboardVendor({super.key});

  @override
  _DashboardVendorState createState() => _DashboardVendorState();
}

class _DashboardVendorState extends State<DashboardVendor> {
  int _selectedIndex = 2; // Default to Dashboard

  final List<Widget> _screens = [
    const HistoryVendorScreen(),
    PaymentInfoScreen(),
    const Center(child: Text('Dashboard Content')), // Placeholder for the dashboard content
    const NotificationsVendorScreen(),
    const ProfileVendorScreen(),
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
          icon: Icon(Icons.payment),
          label: 'Payment',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
      ),
      body: _screens[_selectedIndex], // Switches between screens
      bottomNavigationBar: bottomNavigationBar(), // Custom bottom nav bar
    );
  }
}
