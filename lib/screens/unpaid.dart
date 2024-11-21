import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Unpaid extends StatefulWidget {
  @override
  _UnpaidState createState() => _UnpaidState();
}

class _UnpaidState extends State<Unpaid> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _unpaidVendors = [];
  List<Map<String, dynamic>> _filteredVendors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showRecent = true; // Default to showing recent vendors
  Color _recentButtonBorderColor = Colors.grey; // Initial border color
  Color _overdueButtonBorderColor = Colors.grey; // Initial border color
  Color _recentButtonTextColor = Colors.grey; // Initial text color
  Color _overdueButtonTextColor = Colors.grey; // Initial text color

  @override
  void initState() {
    super.initState();
    _fetchUnpaidVendors();
  }

  Future<void> _fetchUnpaidVendors() async {
    User? user = _auth.currentUser;
    String collectorEmail = user?.email ?? '';

    // Fetch vendors with Pending status and valid payment_date of type Timestamp
    QuerySnapshot querySnapshot = await _firestore
        .collection('payments')
        .where('status', isEqualTo: 'Pending')
        .where('collector_email', isEqualTo: collectorEmail)
        .get();

    setState(() {
      _unpaidVendors = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      _filterByRecent(); // Filter to show only recent vendors by default
      _isLoading = false;
    });
  }

  void _filterVendors(String query) {
    setState(() {
      _searchQuery = query;
      _filteredVendors = _unpaidVendors.where((vendor) {
        final vendorName = vendor['vendor_name']?.toLowerCase() ?? '';
        final vendorId = vendor['id'].toString().toLowerCase();
        return vendorName.contains(query.toLowerCase()) || vendorId.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _filterByRecent() {
    setState(() {
      _showRecent = true; // Set to show recent
      _recentButtonBorderColor = Colors.green; // Change border color to green
      _recentButtonTextColor = Colors.green; // Change text color to green
      _overdueButtonBorderColor = Colors.grey; // Reset overdue border color
      _overdueButtonTextColor = Colors.grey; // Reset overdue text color
      DateTime today = DateTime.now();
      _filteredVendors = _unpaidVendors.where((vendor) {
        if (vendor['payment_date'] is Timestamp) {
          DateTime paymentDate = (vendor['payment_date'] as Timestamp).toDate();
          return paymentDate.year == today.year && paymentDate.month == today.month && paymentDate.day == today.day;
        }
        return false; // Exclude vendors with invalid payment_date
      }).toList();
    });
  }

  void _filterByOverdue() {
    setState(() {
      _showRecent = false; // Set to show overdue
      _overdueButtonBorderColor = Colors.green; // Change border color to green
      _overdueButtonTextColor = Colors.green; // Change text color to green
      _recentButtonBorderColor = Colors.grey; // Reset recent border color
      _recentButtonTextColor = Colors.grey; // Reset recent text color
      DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
      _filteredVendors = _unpaidVendors.where((vendor) {
        if (vendor['payment_date'] is Timestamp) {
          DateTime paymentDate = (vendor['payment_date'] as Timestamp).toDate();
          return paymentDate.year == yesterday.year && paymentDate.month == yesterday.month && paymentDate.day == yesterday.day;
        }
        return false; // Exclude vendors with invalid payment_date
      }).toList();
    });
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    if (!lowerText.contains(lowerQuery)) {
      return Text(text);
    }

    final int startIndex = lowerText.indexOf(lowerQuery);
    final int endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), // Back icon with white color
            onPressed: () {
              Navigator.of(context).pop(); // Navigate back to the previous screen
            },
          ),
          title: const Text(""), // Empty title to avoid spacing issues
          flexibleSpace: const Center( // Center the content
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the text and icon
              mainAxisSize: MainAxisSize.min, // Minimize the space taken by the Row
              children: [
                Icon(Icons.pending, color: Colors.white), // Icon next to the text
                SizedBox(width: 8), // Space between icon and text
                Text(
                  "Pending Payment",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Set text color to white
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.green, // Set background color to green
/*           elevation: 1.0,
 */        ),
      body: Column(
        children: [
          // Filter Buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text('Filter ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16), // Add spacing between the label and buttons
                TextButton(
                  style: TextButton.styleFrom(
                    side: BorderSide(color: _recentButtonBorderColor), // Dynamic border color
                  ),
                  onPressed: _filterByRecent, // Set to recent
                  child: Text(
                    'Recent',
                    style: TextStyle(color: _recentButtonTextColor), // Dynamic text color
                  ),
                ),
                const SizedBox(width: 16), // Add spacing between buttons
                TextButton(
                  style: TextButton.styleFrom(
                    side: BorderSide(color: _overdueButtonBorderColor), // Dynamic border color
                  ),
                  onPressed: _filterByOverdue, // Set to overdue
                  child: Text(
                    'Overdue',
                    style: TextStyle(color: _overdueButtonTextColor), // Dynamic text color
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search vendor name or id',
                labelStyle: const TextStyle(color: Colors.black),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                disabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
              cursorColor: Colors.green,
              onChanged: _filterVendors,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVendors.isEmpty
                    ? const Center(child: Text('No unpaid vendors found.'))
                    : ListView.builder(
                        itemCount: _filteredVendors.length,
                        itemBuilder: (context, index) {
                          final vendor = _filteredVendors[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            elevation: 4,
                            child: ListTile(
                              title: _buildHighlightedText(vendor['vendor_name'] ?? 'No Name', _searchQuery),
                              subtitle: _buildHighlightedText('Status: ${vendor['status']}', _searchQuery),
                              trailing: _buildHighlightedText('ID: ${vendor['id']}', _searchQuery),
                              onTap: () {
                                // Unfocus the TextField when a vendor is tapped
                                FocusScope.of(context).unfocus();
                                // Handle vendor selection if needed
                                print('Selected vendor: ${vendor['full_name']}');
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          }
