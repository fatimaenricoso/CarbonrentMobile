import 'package:ambulantcollector/screens/EnforcerOffense.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EnforcerVendors extends StatefulWidget {
  const EnforcerVendors({Key? key}) : super(key: key);

  @override
  _EnforcerVendorsState createState() => _EnforcerVendorsState();
}

class _EnforcerVendorsState extends State<EnforcerVendors> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userLocation;
  List<DocumentSnapshot> _vendors = [];
  List<DocumentSnapshot> _filteredVendors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot userSnapshot = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: user.email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userSnapshot.docs.first;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userLocation = userData['location'];
        });
        print('User Location: $_userLocation'); // Debugging statement
        _fetchVendors();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchVendors() async {
    if (_userLocation != null) {
      QuerySnapshot vendorsSnapshot = await _firestore
          .collection('approvedVendors')
          .where('stallInfo.location', isEqualTo: _userLocation)
          .get();

      print('Vendors Snapshot: ${vendorsSnapshot.docs}'); // Debugging statement

      setState(() {
        _vendors = vendorsSnapshot.docs;
        _filteredVendors = _vendors;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Assigned Vendors",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Enter Vendor Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                suffixIcon: const Icon(Icons.search, color: Colors.green),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _filteredVendors = _filterVendors(_vendors);
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVendors.isNotEmpty
                    ? ListView.builder(
                        itemCount: _filteredVendors.length,
                        itemBuilder: (context, index) {
                          var vendor = _filteredVendors[index].data() as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 1.0),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Card(
                              margin: EdgeInsets.zero, // Remove default margin
                              child: ListTile(
                                title: _highlightMatch(
                                  '${vendor['firstName']} ${vendor['lastName']}',
                                  _searchQuery,
                                  const TextStyle(fontSize: 14, color: Colors.black),
                                ),
                                subtitle: Text('Location: ${vendor['stallInfo']['location']}'),
                                leading: vendor['profileImageUrls'] != null && vendor['profileImageUrls'].isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(vendor['profileImageUrls'][0]),
                                      )
                                    : const Icon(Icons.person),
                                onTap: () {
                                  _showVendorDetailsDialog(vendor, _filteredVendors[index].id);
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(child: Text("No vendors found")),
          ),
        ],
      ),
    );
  }

  List<DocumentSnapshot> _filterVendors(List<DocumentSnapshot> vendors) {
    return vendors.where((vendor) {
      var data = vendor.data() as Map<String, dynamic>;
      var fullName = '${data['firstName']} ${data['lastName']}'.toLowerCase();
      return fullName.contains(_searchQuery);
    }).toList();
  }

  Widget _highlightMatch(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    var matchIndex = text.toLowerCase().indexOf(query.toLowerCase());
    if (matchIndex == -1) {
      return Text(text, style: style);
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: style.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          TextSpan(text: text.substring(matchIndex + query.length)),
        ],
      ),
    );
  }

  void _showVendorDetailsDialog(Map<String, dynamic> vendor, String vendorId) {
    showDialog(
      context: context,
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Vendor Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.add, color: Colors.white),
                    //   onPressed: () {
                    //     // Handle add icon press
                    //   },
                    // ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Full Name:'),
                        Text('${vendor['firstName']} ${vendor['middleName']} ${vendor['lastName']}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Address:'),
                        Text('${vendor['barangay']} ${vendor['city']}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Billing Cycle:'),
                        Text('${vendor['billingCycle']}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Contact Number:'),
                        Text('${vendor['contactNumber']}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Email:'),
                        Text('${vendor['email']}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Location:'),
                        Text('${vendor['stallInfo']['location']}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rate Per Meter:'),
                        Text('${vendor['stallInfo']['ratePerMeter']}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Stall Number:'),
                        Text('${vendor['stallInfo']['stallNumber']}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Stall Size:'),
                        Text('${vendor['stallInfo']['stallSize']}'),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Close',
                            style: TextStyle(fontSize: 16, color: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorOffense(
                                  vendorName: '${vendor['firstName']} ${vendor['middleName']} ${vendor['lastName']}',
                                  location: vendor['stallInfo']['location'],
                                  stallNumber: vendor['stallInfo']['stallNumber'],
                                  vendorId: vendorId, // Pass the vendorId
                                  showBackButton: true, // Pass a flag to show the back button
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Create Violation',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
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
}
