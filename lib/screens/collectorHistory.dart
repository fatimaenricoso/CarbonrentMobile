import 'package:ambulantcollector/screens/collectorreceipttap';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryVendor extends StatefulWidget {
  const HistoryVendor({super.key});

  @override
  _HistoryVendorState createState() => _HistoryVendorState();
}

class _HistoryVendorState extends State<HistoryVendor> {
  final CollectionReference paymentCollectorRef = FirebaseFirestore.instance.collection('payment_ambulant');
  final CollectionReference collectorRef = FirebaseFirestore.instance.collection('ambulant_collector');
  String _selectedFilter = 'All';
  String _searchQuery = '';
  Map<String, bool> tappedContainers = {};
  List<DocumentSnapshot> filteredPayments = [];
  SharedPreferences? prefs;  // Make nullable
  bool isInitialized = false;

  String? currentCollectorEmail;
  String? currentCollectorZone;

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
          currentCollectorZone = collectorData['zone'];
        });
      }
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
/*             Icon(Icons.people, color: Colors.white), */
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
      stream: paymentCollectorRef
          .where('zone', isEqualTo: currentCollectorZone)
          .where('collector_email', isEqualTo: currentCollectorEmail)
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
          DateTime dateA = (a['date'] as Timestamp).toDate();
          DateTime dateB = (b['date'] as Timestamp).toDate();
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          itemCount: filteredPayments.length,
          itemBuilder: (context, index) {
            final payment = filteredPayments[index];
            final documentId = payment.id;
            DateTime paymentDate = (payment['date'] as Timestamp).toDate();
            final DateFormat formatter = DateFormat('MM/dd/yyyy');
            final String paymentDateFormatted = formatter.format(paymentDate);

            // Check if this container has been tapped from SharedPreferences
            final bool isTapped = tappedContainers[documentId] ?? false;

            return GestureDetector(
              onTap: () {
                _saveTappedContainer(documentId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentReceipt(documentId: documentId),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTapped ? const Color.fromARGB(255, 252, 249, 249) : const Color.fromARGB(255, 238, 230, 230),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color.fromARGB(255, 226, 228, 226)),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Collected Amount:    ₱${payment['total_amount'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: 'Trans. ID: ',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                  children: _highlightMatches(documentId, _searchQuery),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 10), // Arrow icon
                            ],
                          ),
                        ],
                      ),
                      Positioned( //For the Date
                        top: 0,
                        right: 0,
                        child: RichText(
                          text: TextSpan(
                            text: '',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color.fromARGB(255, 86, 85, 85),
                            ),
                            children: _highlightMatches(paymentDateFormatted, _searchQuery),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
        style: const TextStyle(color: Colors.black),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans;
  }

/*   String _maskedEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 1) return email; // If too short to mask, show as-is

    final maskedPart = '*' * (atIndex - 2); // Mask everything except first and last characters before '@'
    return '${email[0]}$maskedPart${email[atIndex - 1]}${email.substring(atIndex)}';
  }
 */

  List<DocumentSnapshot> _filterPayments(List<DocumentSnapshot> allPayments) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // Start of the week (Monday)
    final formattedSearchQuery = _searchQuery.toLowerCase();

    List<DocumentSnapshot> filtered;

    // Apply filter based on the selected filter type
    if (_selectedFilter == 'Today') {
      filtered = allPayments.where((doc) {
        DateTime paymentDate = (doc['date'] as Timestamp).toDate();
        return DateFormat('MM/dd/yyyy').format(paymentDate) ==
            DateFormat('MM/dd/yyyy').format(now);
      }).toList();
    } else if (_selectedFilter == 'This Week') {
      filtered = allPayments.where((doc) {
        DateTime paymentDate = (doc['date'] as Timestamp).toDate();
        return paymentDate.isAfter(weekStart) && paymentDate.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    } else {
      filtered = allPayments; // No filter (All)
    }

    // Apply search query filter for transaction ID and date
    return filtered.where((doc) {
      DateTime paymentDate = (doc['date'] as Timestamp).toDate();
      String formattedDate = DateFormat('MM/dd/yyyy').format(paymentDate);
      String transactionId = doc.id.toLowerCase();
      return transactionId.contains(formattedSearchQuery) ||
          formattedDate.contains(formattedSearchQuery);
    }).toList();
  }
}
