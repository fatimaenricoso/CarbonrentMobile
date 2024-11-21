import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
  

class Paid extends StatefulWidget {
  @override
  _PaidState createState() => _PaidState();
}

class _PaidState extends State<Paid> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _unpaidVendors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnpaidVendors();
  }

  Future<void> _fetchUnpaidVendors() async {
    // Get the currently logged-in collector's email
    User? user = _auth.currentUser;
    String collectorEmail = user?.email ?? '';

    // Fetch vendors with Pending status
    QuerySnapshot querySnapshot = await _firestore
        .collection('payments')
        .where('status', isEqualTo: 'paid')
        .where('collector_email', isEqualTo: collectorEmail)
        .get();

    // Extract vendor data
    setState(() {
      _unpaidVendors = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
      _isLoading = false;
    });
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
                Icon(Icons.payments, color: Colors.white), // Icon next to the text
                SizedBox(width: 8), // Space between icon and text
                Text(
                  "Paid Vendors",
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _unpaidVendors.isEmpty
              ? const Center(child: Text('No unpaid vendors found.'))
              : ListView.builder(
                  itemCount: _unpaidVendors.length,
                  itemBuilder: (context, index) {
                    final vendor = _unpaidVendors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        title: Text(vendor['vendor_name'] ?? 'No Name'),
                        subtitle: Text('Status: ${vendor['status']}'),
                        trailing: Text('ID: ${vendor['id']}'),
                        onTap: () {
                          // Handle vendor selection if needed
                          print('Selected vendor: ${vendor['vendor_name']}');
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
