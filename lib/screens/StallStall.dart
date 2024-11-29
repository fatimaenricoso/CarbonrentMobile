import 'package:ambulantcollector/screens/StallVendorDetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StallScreen extends StatefulWidget {
  const StallScreen({Key? key}) : super(key: key);

  @override
  _StallScreenState createState() => _StallScreenState();
}

class _StallScreenState extends State<StallScreen> {
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
        if (userData['position'] == 'Collector') {
          setState(() {
            _userLocation = userData['location'];
          });
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
        title: const Text("Approved Vendors"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name',
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
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(vendor['profileImageUrls'][0]),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StallDetails(vendor: _filteredVendors[index]),
                                    ),
                                  );
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
}
