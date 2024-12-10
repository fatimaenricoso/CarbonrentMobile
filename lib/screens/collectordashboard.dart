import 'package:ambulantcollector/screens/collectedTotal.dart';
import 'package:ambulantcollector/screens/collectorHistory.dart';
import 'package:ambulantcollector/screens/collectorProfile.dart';
import 'package:ambulantcollector/screens/collector_ambulant.dart';
import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 2; // Default to Dashboard
  String currentZone = ''; // To store the current collector's zone
  double totalAmountPaidToday = 0.0; // Total amount for the day

  @override
  void initState() {
    super.initState();
    _fetchCurrentCollectorZone(); // Fetch collector's zone on initialization
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fetch the current collector's zone and email using Firebase Auth
  Future<void> _fetchCurrentCollectorZone() async {
    try {
      String currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      print('Current email: $currentEmail');

      if (currentEmail.isNotEmpty) {
        // Fetch collector data based on email
        final collectorSnapshot = await FirebaseFirestore.instance
            .collection('ambulant_collector')
            .where('email', isEqualTo: currentEmail)
            .limit(1)
            .get();

        if (collectorSnapshot.docs.isNotEmpty) {
          currentZone = collectorSnapshot.docs.first.data()['zone'] ?? '';
          print('Current zone: $currentZone');
          if (mounted) {
            setState(() {}); // Trigger rebuild with updated zone
          }
        } else {
          print('Collector not found for email: $currentEmail');
        }
      } else {
        print('No user is currently logged in.');
      }
    } catch (e) {
      print('Error fetching collector zone: $e');
    }
  }

  // Start listening to the payment updates in real-time
  Stream<double> _totalAmountPaidTodayStream() {
    String currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return FirebaseFirestore.instance
        .collection('payment_ambulant')
        .where('zone', isEqualTo: currentZone)
        .where('collector_email', isEqualTo: currentEmail)
        .snapshots()
        .map((paymentSnapshot) {
      double totalAmount = 0.0;
      for (var doc in paymentSnapshot.docs) {
        Timestamp paymentDate = doc['date'];
        String paymentDateString = DateFormat('yyyy-MM-dd').format(paymentDate.toDate());

        // Check if payment is made today
        if (paymentDateString == todayDate) {
          totalAmount += (doc['total_amount'] as num).toDouble();
        }
      }
      return totalAmount;
    });
  }

  Stream<Map<String, double>> _weeklyPaymentsStream() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    print('Current date: $now');
    print('Start of week: $startOfWeek');
    print('End of week: $endOfWeek');

    return FirebaseFirestore.instance
        .collection('payment_ambulant')
        .where('zone', isEqualTo: currentZone)
        .where('collector_email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .snapshots()
        .map((paymentSnapshot) {
      Map<String, double> weeklyPayments = {};
      for (var doc in paymentSnapshot.docs) {
        Timestamp paymentDate = doc['date'];
        DateTime paymentDateTime = paymentDate.toDate();

        print('Payment date: $paymentDateTime');

        // Ensure the payment date is within the current week
        if (paymentDateTime.isAfter(startOfWeek) && paymentDateTime.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          String dayOfWeek = DateFormat('E').format(paymentDateTime);
          double totalAmount = (doc['total_amount'] as num).toDouble();

          print('Payment day: $dayOfWeek, Amount: $totalAmount');

          if (weeklyPayments.containsKey(dayOfWeek)) {
            weeklyPayments[dayOfWeek] = weeklyPayments[dayOfWeek]! + totalAmount;
          } else {
            weeklyPayments[dayOfWeek] = totalAmount;
          }
        }
      }
      print('Weekly payments: $weeklyPayments');
      return weeklyPayments;
    });
  }

  final List<Widget> _screens = [
    const HistoryVendor(),
    const DailyCollected(),
    const Dashboard(),
    CollectorSpace(),
    const ProfileScreen(),
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
          label: 'Daily',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Collect',
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
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
/*             Icon(Icons.dashboard, color: Colors.white),
 */                  SizedBox(width: 8),
                  Text("Collector Dashboard", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              backgroundColor: Colors.green,
              elevation: 1.0,
              centerTitle: true,
            )
          : null,
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
                    const SizedBox(height: 20),
                    const Text(
                      'Weekly Collections',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 13),
                    StreamBuilder<Map<String, double>>(
                      stream: _weeklyPaymentsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Column(
                            children: [
                              Text(
                                _getWeekDateRange(),
                                style: const TextStyle(
                                  fontSize: 11,
                                 /*  fontWeight: FontWeight.bold, */
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDynamicBarChart(snapshot.data!),
                            ],
                          );
                        }
                        return const Text('No payments for this week.');
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

  String _getWeekDateRange() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${DateFormat('MM/dd/yyyy').format(startOfWeek)} - ${DateFormat('MM/dd/yyyy').format(endOfWeek)}';
  }

  Widget _buildDynamicBarChart(Map<String, double> data) {
    List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<BarChartGroupData> barGroups = [];
    double maxValue = 0.0;

    // Ensure the days of the week are in the correct order
    daysOfWeek.forEach((day) {
      double totalAmount = data[day] ?? 0.0;
      barGroups.add(
        BarChartGroupData(
          x: daysOfWeek.indexOf(day),
          barRods: [
            BarChartRodData(
              toY: totalAmount,
              color: Colors.green,
              width: 20,
              borderRadius: BorderRadius.zero, // Remove curved edges
            ),
          ],
          showingTooltipIndicators: [], // Set to an empty list to remove tooltips
        ),
      );
      if (totalAmount > maxValue) {
        maxValue = totalAmount;
      }
    });

    // Determine the interval based on the maximum value
    double interval;
    if (maxValue > 3000) {
      interval = 1000;
    } else if (maxValue > 1500) {
      interval = 500;
    } else if (maxValue > 500) {
      interval = 250;
    } else if (maxValue > 100) {
      interval = 100;
    } else {
      interval = 50;
    }

    return Container(
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
                  String day = daysOfWeek[value.toInt()];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      day,
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
                interval: interval, // Set interval dynamically
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${value.toStringAsFixed(0)}',
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
          maxY: (maxValue / interval).ceil() * interval, // Round up to the next interval
        ),
      ),
    );
  }
}
