import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StallHistory extends StatefulWidget {
  const StallHistory({Key? key}) : super(key: key);

  @override
  _StallHistoryState createState() => _StallHistoryState();
}

class _StallHistoryState extends State<StallHistory> {
  final CollectionReference paymentCollectorRef = FirebaseFirestore.instance.collection('stall_payment');
  final CollectionReference collectorRef = FirebaseFirestore.instance.collection('admin_users');
  final CollectionReference vendorRef = FirebaseFirestore.instance.collection('approveVendors');
  String _selectedFilter = 'All';
  String _searchQuery = '';
  Map<String, bool> tappedContainers = {};
  List<DocumentSnapshot> filteredPayments = [];
  SharedPreferences? prefs;  // Make nullable
  bool isInitialized = false;

  String? currentCollectorEmail;
  String? currentCollectorLocation;
  List<String> vendorIdsWithSameLocation = [];

  @override
  void initState() {
    super.initState();
    _getCurrentCollectorDetails();
    _loadTappedContainers();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      await _getCurrentCollectorDetails();
      await _fetchVendorsWithSameLocation();
      _loadTappedContainers();
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  void _loadTappedContainers() {
    if (!mounted || prefs == null) return;

    setState(() {
      final tappedKeys = prefs!.getKeys().where((key) => key.startsWith('tapped_'));
      tappedContainers.clear();
      for (var key in tappedKeys) {
        final documentId = key.replaceFirst('tapped_', '');
        tappedContainers[documentId] = prefs!.getBool(key) ?? false;
      }
    });
  }

  Future<void> _saveTappedContainer(String documentId) async {
    if (prefs == null) return;

    await prefs!.setBool('tapped_$documentId', true);
    if (mounted) {
      setState(() {
        tappedContainers[documentId] = true;
      });
    }
  }

  Future<void> _getCurrentCollectorDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentCollectorEmail = user.email;

      final collectorSnapshot = await collectorRef.where('email', isEqualTo: currentCollectorEmail).limit(1).get();
      if (collectorSnapshot.docs.isNotEmpty) {
        final collectorData = collectorSnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          currentCollectorLocation = collectorData['location'];
        });
      }
    }
  }

  Future<void> _fetchVendorsWithSameLocation() async {
    if (currentCollectorLocation != null) {
      final vendorSnapshot = await vendorRef.where('stallInfo.location', isEqualTo: currentCollectorLocation).get();
      setState(() {
        vendorIdsWithSameLocation = vendorSnapshot.docs.map((doc) => doc.id).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 8),
            Text("Payment History", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.only(top: 0.0, left: 5.0, right: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Filter ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                _buildFilterButton('All'),
                const SizedBox(width: 10),
                _buildFilterButton('Today'),
                const SizedBox(width: 10),
                _buildFilterButton('This Week'),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Compact Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Enter date or Transaction ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.green), // Border color
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.green.shade700), // Focused border color
                ),
                suffixIcon: const Icon(Icons.search, color: Colors.green), // Icon color
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 10),

          // Payment History List
          Expanded(
            child: _buildPaymentHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _selectedFilter == filter ? Colors.green : const Color.fromARGB(255, 136, 135, 135)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.transparent,
        minimumSize: const Size(2, 25),
        padding: const EdgeInsets.symmetric(horizontal: 15),
      ),
      onPressed: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Text(
        filter,
        style: TextStyle(
          color: _selectedFilter == filter ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: vendorIdsWithSameLocation.isNotEmpty
          ? paymentCollectorRef
              .where('status', isEqualTo: 'paid')
              .where('vendorId', whereIn: vendorIdsWithSameLocation)
              .snapshots()
          : paymentCollectorRef
              .where('status', isEqualTo: 'paid')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        final allPayments = snapshot.data!.docs;
        final filteredPayments = _filterPayments(allPayments);

        if (filteredPayments.isEmpty) {
          return const Center(child: Text('No matching results'));
        }

        filteredPayments.sort((a, b) {
          DateTime dateA = (a['paymentDate'] as Timestamp).toDate();
          DateTime dateB = (b['paymentDate'] as Timestamp).toDate();
          return dateB.compareTo(dateA);
        });

        Map<String, List<DocumentSnapshot>> groupedPayments = {};
        for (var payment in filteredPayments) {
          DateTime paymentDate = (payment['paymentDate'] as Timestamp).toDate();
          String monthYear = DateFormat('MMMM yyyy').format(paymentDate);
          if (!groupedPayments.containsKey(monthYear)) {
            groupedPayments[monthYear] = [];
          }
          groupedPayments[monthYear]!.add(payment);
        }

        return ListView.builder(
          itemCount: groupedPayments.keys.length,
          itemBuilder: (context, index) {
            String monthYear = groupedPayments.keys.elementAt(index);
            List<DocumentSnapshot> payments = groupedPayments[monthYear]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    monthYear,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 70, 69, 69),
                    ),
                  ),
                ),
                ...payments.map((payment) {
                  final documentId = payment.id;
                  DateTime paymentDate = (payment['paymentDate'] as Timestamp).toDate();
                  final DateFormat formatter = DateFormat('MM/dd/yyyy');
                  final String paymentDateFormatted = formatter.format(paymentDate);

                  // Check if this container has been tapped from SharedPreferences
                  final bool isTapped = tappedContainers[documentId] ?? false;

                  final paymentData = payment.data() as Map<String, dynamic>;
                  final fullName = '${paymentData['firstName']} ${paymentData['middleName']} ${paymentData['lastName']}';
                  final amount = paymentData.containsKey('totalAmountDue')
                      ? '₱${paymentData['totalAmountDue'].toStringAsFixed(2)}'
                      : '₱${paymentData['total'].toStringAsFixed(2)}';

                  return GestureDetector(
                    onTap: () {
                      _saveTappedContainer(documentId);
                      // Navigate to payment receipt or details screen
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isTapped ? const Color.fromARGB(255, 252, 249, 249) : const Color.fromARGB(255, 238, 230, 230),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.green), // Green border
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: _highlightMatches(fullName, _searchQuery),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: _highlightMatches(paymentDateFormatted, _searchQuery),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Amount: $amount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Transaction ID: $documentId',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  List<InlineSpan> _highlightMatches(String text, String query) {
    final List<InlineSpan> spans = [];
    final RegExp regex = RegExp(query, caseSensitive: false);
    final matches = regex.allMatches(text);

    int lastEnd = 0;
    for (var match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans;
  }

  List<DocumentSnapshot> _filterPayments(List<DocumentSnapshot> allPayments) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // Start of the week (Monday)
    final formattedSearchQuery = _searchQuery.toLowerCase();

    List<DocumentSnapshot> filtered;

    // Apply filter based on the selected filter type
    if (_selectedFilter == 'Today') {
      filtered = allPayments.where((doc) {
        DateTime paymentDate = (doc['paymentDate'] as Timestamp).toDate();
        return DateFormat('MM/dd/yyyy').format(paymentDate) ==
            DateFormat('MM/dd/yyyy').format(now);
      }).toList();
    } else if (_selectedFilter == 'This Week') {
      filtered = allPayments.where((doc) {
        DateTime paymentDate = (doc['paymentDate'] as Timestamp).toDate();
        return paymentDate.isAfter(weekStart) && paymentDate.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    } else {
      filtered = allPayments; // No filter (All)
    }

    // Apply search query filter for transaction ID and date
    return filtered.where((doc) {
      DateTime paymentDate = (doc['paymentDate'] as Timestamp).toDate();
      String formattedDate = DateFormat('MM/dd/yyyy').format(paymentDate);
      String transactionId = doc.id.toLowerCase();
      return transactionId.contains(formattedSearchQuery) ||
          formattedDate.contains(formattedSearchQuery);
    }).toList();
  }
}
