import 'package:ambulantcollector/screens/EnforcerVendor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'EnforcerHistory.dart';
import 'EnforcerOffense.dart';
import 'EnforcerProfile.dart';
import 'unifiedloginscreen.dart';

class EnforcerDashboard extends StatefulWidget {
  const EnforcerDashboard({Key? key}) : super(key: key);

  @override
  _EnforcerDashboardState createState() => _EnforcerDashboardState();
}

class _EnforcerDashboardState extends State<EnforcerDashboard> {
  int _selectedIndex = 2; // Set to the Dashboard by default
  String currentUserEmail = '';
  int totalViolationsToday = 0; // Total violations for the day

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

  // Start listening to the violation updates in real-time
  Stream<int> _totalViolationsTodayStream() {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return FirebaseFirestore.instance
        .collection('Market_violations')
        .where('status', isEqualTo: 'To be Reviewed')
        .snapshots()
        .map((violationSnapshot) {
      int totalViolations = 0;
      for (var doc in violationSnapshot.docs) {
        Timestamp violationDate = doc['date'];
        String violationDateString = DateFormat('yyyy-MM-dd').format(violationDate.toDate());

        // Check if violation is made today
        if (violationDateString == todayDate) {
          totalViolations++;
        }
      }
      return totalViolations;
    });
  }

  Stream<Map<String, Map<String, int>>> _offenseDataStream() {
    return FirebaseFirestore.instance
        .collection('Market_violations')
        .where('status', isEqualTo: 'To be Reviewed')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      Map<String, Map<String, int>> offenseData = {};

      for (var doc in snapshot.docs) {
        String vendorName = doc['vendorName'];
        String warning = doc['warning'];

        if (!offenseData.containsKey(vendorName)) {
          offenseData[vendorName] = {'1st': 0, '2nd': 0, 'Final': 0};
        }

        if (warning == '1st Offense') {
          offenseData[vendorName]!['1st'] = (offenseData[vendorName]!['1st'] ?? 0) + 1;
        } else if (warning == '2nd Offense') {
          offenseData[vendorName]!['2nd'] = (offenseData[vendorName]!['2nd'] ?? 0) + 1;
        } else if (warning == 'Final Offense') {
          offenseData[vendorName]!['Final'] = (offenseData[vendorName]!['Final'] ?? 0) + 1;
        }
      }

      return offenseData;
    }).handleError((error) {
      print('Error fetching offense data: $error');
      return {};
    });
  }

  final List<Widget> _screens = [
    const EnforcerHistory(),
    const EnforcerVendors(),
    const EnforcerDashboard(),
    VendorOffense(vendorName: '', location: '', stallNumber: '', vendorId: '',),
    const EnforcerProfile(),
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
          label: 'Vendors',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report),
          label: 'Offense',
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
                "Enforcer Dashboard",
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
                      child: StreamBuilder<int>(
                        stream: _totalViolationsTodayStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasData) {
                            totalViolationsToday = snapshot.data!;
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Violations Today',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    totalViolationsToday.toString(), // Display count of violations
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
                    const SizedBox(height: 20),
                    const Text(
                      'Vendor Offenses',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 13),
                    StreamBuilder<Map<String, Map<String, int>>>(
                      stream: _offenseDataStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return _buildOffenseBarChart(snapshot.data!);
                        }
                        return const Text('No violations found.');
                      },
                    ),
                  ],
                ),
              ),
            )
          : _screens[_selectedIndex],
      bottomNavigationBar: bottomNavigationBar(),
    );
  }

  Widget _buildOffenseBarChart(Map<String, Map<String, int>> data) {
    List<String> vendorNames = data.keys.toList();
    List<BarChartGroupData> barGroups = [];
    double maxValue = 0.0;

    for (int i = 0; i < vendorNames.length; i++) {
      String vendorName = vendorNames[i];
      Map<String, int> offenses = data[vendorName]!;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (offenses['1st'] ?? 0) > 0 ? 1 : 0,
              color: Colors.blue,
              width: 20,
              borderRadius: BorderRadius.zero, // Remove curved edges
            ),
            BarChartRodData(
              toY: (offenses['2nd'] ?? 0) > 0 ? 2 : 0,
              color: Colors.green,
              width: 20,
              borderRadius: BorderRadius.zero, // Remove curved edges
            ),
            BarChartRodData(
              toY: (offenses['Final'] ?? 0) > 0 ? 3 : 0,
              color: Colors.red,
              width: 20,
              borderRadius: BorderRadius.zero, // Remove curved edges
            ),
          ],
          showingTooltipIndicators: [], // Set to an empty list to remove tooltips
        ),
      );

      num totalOffenses = (offenses['1st'] ?? 0) + (offenses['2nd'] ?? 0) + (offenses['Final'] ?? 0);
      if (totalOffenses > maxValue) {
        maxValue = totalOffenses.toDouble();
      }
    }

    // Determine the interval based on the maximum value
    double interval;
    if (maxValue > 10) {
      interval = 3;
    } else if (maxValue > 3) {
      interval = 2;
    } else {
      interval = 1;
    }

    return Column(
      children: [
        Container(
          height: 250, // Increased height to accommodate two-line text
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(0), // Remove curved edges
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      String vendorName = vendorNames[value.toInt()];
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          vendorName.split(' ').first,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10, // Adjust font size
                          ),
                        ),
                      );
                    },
                    reservedSize: 30, // Increased reserved size to fit two-line text
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1, // Set interval to 1 for text labels
                    getTitlesWidget: (double value, TitleMeta meta) {
                      String label;
                      if (value == 1) {
                        label = '1st';
                      } else if (value == 2) {
                        label = '2nd';
                      } else if (value == 3) {
                        label = 'Final';
                      } else {
                        label = '';
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10, // Adjust font size
                          ),
                        ),
                      );
                    },
                    reservedSize: 40, // Increase reserved size to fit numbers
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (double value) {
                  // Draw lines at each specific interval
                  return FlLine(
                    color: Colors.grey.withOpacity(0.5),
                    strokeWidth: 1,
                  );
                },
              ),
              maxY: 3, // Set maxY to 3 for text labels
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('1st'),
              const SizedBox(width: 16),
              Container(
                width: 20,
                height: 20,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              const Text('2nd'),
              const SizedBox(width: 16),
              Container(
                width: 20,
                height: 20,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              const Text('Final'),
            ],
          ),
        ),
      ],
    );
  }
}
