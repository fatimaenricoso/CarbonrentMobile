import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyCollected extends StatefulWidget {
  const DailyCollected({super.key});

  @override
  _DailyCollectedState createState() => _DailyCollectedState();
}

class _DailyCollectedState extends State<DailyCollected> {
  final CollectionReference paymentCollection =
      FirebaseFirestore.instance.collection('payment_ambulant');
  final CollectionReference collectorCollection =
      FirebaseFirestore.instance.collection('ambulant_collector');

  String? currentUserEmail;
  String? currentUserZone;
  Map<String, Map<String, dynamic>>? dailyTotals;
  final _searchController = TextEditingController();
  List<String>? filteredDates;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserEmail();
  }

  Future<void> fetchCurrentUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserEmail = user.email;
      });
      fetchUserZone();
    }
  }

  Future<void> fetchUserZone() async {
    if (currentUserEmail == null) return;

    QuerySnapshot snapshot = await collectorCollection
        .where('email', isEqualTo: currentUserEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        currentUserZone = snapshot.docs.first['zone'];
      });
    }
  }

  Future<Map<String, Map<String, dynamic>>> getDailyTotals() async {
    if (currentUserZone == null) return {};

    QuerySnapshot snapshot = await paymentCollection
        .where('zone', isEqualTo: currentUserZone)
        .get();

    Map<String, Map<String, dynamic>> dailyTotals = {};

    for (var doc in snapshot.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      String formattedDate = DateFormat('MM/dd/yyyy').format(date);
      double amount = doc['total_amount'] is int ? (doc['total_amount'] as int).toDouble() : doc['total_amount'];
      String vendorNumber = doc['vendor_number'].toString(); // Convert vendor_number to string

      if (dailyTotals.containsKey(formattedDate)) {
        if (dailyTotals[formattedDate]!.containsKey(vendorNumber)) {
          dailyTotals[formattedDate]![vendorNumber]['amount'] += amount;
        } else {
          dailyTotals[formattedDate]![vendorNumber] = {
            'amount': amount,
          };
        }
      } else {
        dailyTotals[formattedDate] = {
          vendorNumber: {
            'amount': amount,
          },
        };
      }
    }

    // Sort the dailyTotals by date in descending order
    return Map.fromEntries(
      dailyTotals.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String getRelativeDate(String date) {
    DateTime parsedDate = DateFormat('MM/dd/yyyy').parse(date);
    DateTime now = DateTime.now();
    Duration difference = now.difference(parsedDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '1 week ago';
    }
  }

  Future<void> showVendorDetailsDialog(String date, Map<String, dynamic> vendorTotals) async {
    showDialog(
      context: context,
      builder: (context) {
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
                child: Center(
                  child: Text(
                    'Vendor Details:   $date',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
/*                       fontWeight: FontWeight.bold,
 */                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 15),
                    ListView.separated(
                      shrinkWrap: true,
                      itemCount: vendorTotals.length,
                      separatorBuilder: (context, index) => const Divider(height: 15, color: Colors.grey),
                      itemBuilder: (context, index) {
                        String vendorNumber = vendorTotals.keys.elementAt(index);
                        double amount = vendorTotals[vendorNumber]['amount'];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Vendor No. $vendorNumber',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  'Amount:  ₱${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
/*             Icon(Icons.receipt_rounded, color: Colors.white),
 */            SizedBox(width: 15),
            Text("Collected Amount", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16), // Space between AppBar and Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  // Filter dates based on the search input
                  filteredDates = dailyTotals?.keys
                      .where((date) => date.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search a Date',
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
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, Map<String, dynamic>>>(
              future: getDailyTotals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                dailyTotals = snapshot.data!;
                filteredDates ??= dailyTotals?.keys.toList(); // Ensure filteredDates is initialized

                if (filteredDates!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No match found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredDates?.length ?? 0,
                  itemBuilder: (context, index) {
                    String date = filteredDates![index];
                    Map<String, dynamic> vendorTotals = dailyTotals?[date] ?? {};
                    double totalAmount = vendorTotals.values.fold(0.0, (sum, entry) => sum + entry['amount']);
                    int totalVendors = vendorTotals.length;

                    return GestureDetector(
                      onTap: () {
                        showVendorDetailsDialog(date, vendorTotals);
                      },
                      child: Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: 'Date: ',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      children: _highlightMatches(date, _searchController.text),
                                    ),
                                  ),
                                  Text(
                                    getRelativeDate(date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Divider(
                                color: Colors.grey.shade300,
                                thickness: 1.0,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Vendors: $totalVendors',
                                style: const TextStyle(
                                  fontSize: 12,
/*                                   fontWeight: FontWeight.bold,
 */                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Total Amount: ₱${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                   fontWeight: FontWeight.bold,
                                  color: Colors.black,
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
            ),
          ),
        ],
      ),
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
}
