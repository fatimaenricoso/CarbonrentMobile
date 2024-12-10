import 'package:ambulantcollector/screens/AppraisalProducts.dart';
import 'package:ambulantcollector/screens/appraisalAppraise.dart';
import 'package:ambulantcollector/screens/appraisalGraph.dart';
import 'package:ambulantcollector/screens/appraisalHistory.dart';
import 'package:ambulantcollector/screens/appraisalProfile.dart';
import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppraisalDashboard extends StatefulWidget {
  const AppraisalDashboard({Key? key}) : super(key: key);

  @override
  _AppraisalDashboardState createState() => _AppraisalDashboardState();
}

class _AppraisalDashboardState extends State<AppraisalDashboard> {
  int _selectedIndex = 2; // Set to the Appraisal Dashboard by default
  String currentAppraiserEmail = '';
  String currentAppraisalValue = '';
  double totalAmountPaidToday = 0.0; // Total amount for the day

  @override
  void initState() {
    super.initState();
    _fetchCurrentAppraiserDetails(); // Fetch appraiser's details on initialization
  }

  // Fetch the current appraiser's email and appraisal value using Firebase Auth
  Future<void> _fetchCurrentAppraiserDetails() async {
    try {
      currentAppraiserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      if (currentAppraiserEmail.isNotEmpty) {
        // Fetch appraiser data based on email
        final appraiserSnapshot = await FirebaseFirestore.instance
            .collection('appraisal_user')
            .where('email', isEqualTo: currentAppraiserEmail)
            .limit(1)
            .get();

        if (appraiserSnapshot.docs.isNotEmpty) {
          currentAppraisalValue = appraiserSnapshot.docs.first.data()['appraisal_assign'] ?? '';
          if (mounted) {
            setState(() {}); // Trigger rebuild with updated appraisal value
          }
        } else {
          print('Appraiser not found for email: $currentAppraiserEmail');
        }
      } else {
        print('No user is currently logged in.');
      }
    } catch (e) {
      print('Error fetching appraiser details: $e');
    }
  }

  // Start listening to the payment updates in real-time
  Stream<double> _totalAmountPaidTodayStream() {
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return FirebaseFirestore.instance
        .collection('appraisals')
        .where('appraiser_email', isEqualTo: currentAppraiserEmail)
        .where('appraisal_assign', isEqualTo: currentAppraisalValue)
        .snapshots()
        .map((appraisalSnapshot) {
      double totalAmount = 0.0;
      for (var doc in appraisalSnapshot.docs) {
        Timestamp appraisalDate = doc['created_date'];
        String appraisalDateString = DateFormat('yyyy-MM-dd').format(appraisalDate.toDate());

        // Check if appraisal is made today
        if (appraisalDateString == todayDate) {
          totalAmount += (doc['total_amount'] as num).toDouble();
        }
      }
      return totalAmount;
    });
  }

  Stream<Map<String, Map<String, double>>> _weeklyAppraisalsStream() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    return FirebaseFirestore.instance
        .collection('appraisals')
        .where('appraiser_email', isEqualTo: currentAppraiserEmail)
        .where('appraisal_assign', isEqualTo: currentAppraisalValue)
        .snapshots()
        .map((appraisalSnapshot) {
      Map<String, double> weeklyAppraisals = {};
      for (var doc in appraisalSnapshot.docs) {
        Timestamp appraisalDate = doc['created_date'];
        DateTime appraisalDateTime = appraisalDate.toDate();

        if (appraisalDateTime.isAfter(startOfWeek) && appraisalDateTime.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          String goodsName = doc['goods_name'];
          double totalAmount = (doc['total_amount'] as num).toDouble();

          if (weeklyAppraisals.containsKey(goodsName)) {
            weeklyAppraisals[goodsName] = weeklyAppraisals[goodsName]! + totalAmount;
          } else {
            weeklyAppraisals[goodsName] = totalAmount;
          }
        }
      }

      // Get the top 6 products for the current week
      List<MapEntry<String, double>> sortedWeeklyAppraisals = weeklyAppraisals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      Map<String, double> top6WeeklyAppraisals = Map.fromEntries(sortedWeeklyAppraisals.take(6));

      return {'current_week': top6WeeklyAppraisals};
    });
  }

  Stream<Map<String, Map<String, Map<String, dynamic>>>> _monthlyAppraisalsStream() {
    return FirebaseFirestore.instance
        .collection('appraisals')
        .where('appraiser_email', isEqualTo: currentAppraiserEmail)
        .where('appraisal_assign', isEqualTo: currentAppraisalValue)
        .snapshots()
        .map((appraisalSnapshot) {
      Map<String, Map<String, Map<String, dynamic>>> monthlyAppraisals = {};
      for (var doc in appraisalSnapshot.docs) {
        Timestamp appraisalDate = doc['created_date'];
        String appraisalDateString = DateFormat('yyyy-MM').format(appraisalDate.toDate());

        String goodsName = doc['goods_name'];
        double totalAmount = (doc['total_amount'] as num).toDouble();
        int quantity = (doc['quantity'] as num).toInt();
        String unitMeasure = doc['unit_measure'];

        if (monthlyAppraisals.containsKey(appraisalDateString)) {
          if (monthlyAppraisals[appraisalDateString]!.containsKey(goodsName)) {
            monthlyAppraisals[appraisalDateString]![goodsName]!['total_amount'] += totalAmount;
            monthlyAppraisals[appraisalDateString]![goodsName]!['quantity'] += quantity;
          } else {
            monthlyAppraisals[appraisalDateString]![goodsName] = {
              'total_amount': totalAmount,
              'quantity': quantity,
              'unit_measure': unitMeasure,
            };
          }
        } else {
          monthlyAppraisals[appraisalDateString] = {
            goodsName: {
              'total_amount': totalAmount,
              'quantity': quantity,
              'unit_measure': unitMeasure,
            }
          };
        }
      }
      return monthlyAppraisals;
    });
  }

  final List<Widget> _screens = [
    const HistoryScreen(),
    const AppraisalCollectedScreen(),
    const AppraisalDashboard(),
    AppraisalCollect(),
    const AppraisalProfile(),
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
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.approval_outlined),
          label: 'Appraisal',
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
                "Appraisal Dashboard",
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
                    const SizedBox(height: 20),
                    const Text(
                      'Weekly Appraisals',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
  
                    StreamBuilder<Map<String, Map<String, double>>>(
                      stream: _weeklyAppraisalsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          print('Error: ${snapshot.error}');
                          return const Text('Error fetching weekly appraisals.');
                        }
                        if (snapshot.hasData) {
                          Map<String, Map<String, double>>? data = snapshot.data;
                          if (data != null && data.isNotEmpty) {
                            Map<String, double> currentWeekData = data['current_week'] ?? {};
                            if (currentWeekData.isNotEmpty) {
                              return Column(
                                children: [
                                  Text(
                                    'This Week: ${_getWeekDateRange()}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDynamicBarChart(currentWeekData),
                                  const SizedBox(height: 20),
                                ],
                              );
                            } else {
                              return const Text('No appraisal found in this week.');
                            }
                          } else {
                            return const Text('No appraisal found in this week.');
                          }
                        }
                        return const Text('No appraisal found in this week.');
                      },
                    ),
                    const Text(
                      'Monthly Appraisals',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<Map<String, Map<String, Map<String, dynamic>>>>(
                      stream: _monthlyAppraisalsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          List<String> months = snapshot.data!.keys.toList();
                          months.sort((a, b) => DateTime.parse('$b-01').compareTo(DateTime.parse('$a-01')));

                          return Column(
                            children: months.map((month) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMMM yyyy').format(DateTime.parse('$month-01')),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                     fontWeight: FontWeight.bold, 
                                    ),
                                  ),
                                  const SizedBox(height: 3), // Add space between month label and containers
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: snapshot.data![month]!.length,
                                    itemBuilder: (context, index) {
                                      var goodsName = snapshot.data![month]!.keys.elementAt(index);
                                      var totalAmount = snapshot.data![month]![goodsName]!['total_amount'];
                                      var quantity = snapshot.data![month]![goodsName]!['quantity'];
                                      var unitMeasure = snapshot.data![month]![goodsName]!['unit_measure'];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProductGraphScreen(goodsName: goodsName),
                                            ),
                                          );
                                        },
                                        child: Card(
                                          margin: const EdgeInsets.symmetric(vertical: 5),
                                          elevation: 0, // shadow
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            side: const BorderSide(color: Colors.grey, width: 0.5), // Add green border
                                          ),
                                          color: Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.all(9),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  goodsName,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Total Amount: ₱${totalAmount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Quantity: $quantity $unitMeasure',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 15), // Add space between the last container of the previous month and the next month label
                                ],
                              );
                            }).toList(),
                          );
                        }
                        return const Text('No appraisals for this month.');
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
    List<BarChartGroupData> barGroups = [];
    double maxValue = data.values.reduce((a, b) => a > b ? a : b);

    // Determine the interval based on the maximum value
    double interval;
    if (maxValue > 3000) {
      interval = 1000;
    } else if (maxValue > 1500) {
      interval = 500;
    } else {
      interval = 250;
    }

    data.forEach((goodsName, totalAmount) {
      barGroups.add(
        BarChartGroupData(
          x: barGroups.length,
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
    });

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
                  String goodsName = data.keys.elementAt(value.toInt());
                  if (goodsName.length > 8) {
                    String firstPart = goodsName.substring(0, 4);
                    String secondPart = goodsName.substring(4);
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: RichText(
                        text: TextSpan(
                          text: '$firstPart\n$secondPart',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10, // Adjust font size
                          ),
                        ),
                      ),
                    );
                  } else {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        goodsName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10, // Adjust font size
                        ),
                      ),
                    );
                  }
                },
                reservedSize: 30, // Increased reserved size to fit two-line text
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval, // Set interval dynamically
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value % interval == 0) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        '${(value / interval * interval).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10, // Adjust font size
                        ),
                      ),
                    );
                  }
                  return Container(); // Don't show titles that are not multiples of the interval
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
