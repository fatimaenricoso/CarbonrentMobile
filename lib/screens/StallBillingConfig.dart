import 'package:ambulantcollector/screens/StallConfigTap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StallPending extends StatefulWidget {
  const StallPending({Key? key}) : super(key: key);

  @override
  _StallPendingState createState() => _StallPendingState();
}

class _StallPendingState extends State<StallPending> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userLocation;
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _filteredVendors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // Default filter

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

      List<Map<String, dynamic>> filteredVendors = [];
      for (var vendorDoc in vendorsSnapshot.docs) {
        String vendorId = vendorDoc.id;
        QuerySnapshot paymentSnapshot = await _firestore
            .collection('stall_payment')
            .where('vendorId', isEqualTo: vendorId)
            .where('status', whereIn: ['Pending', 'Overdue'])
            .get();

        if (paymentSnapshot.docs.isNotEmpty) {
          List<Map<String, dynamic>> paymentDataList = paymentSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          paymentDataList.sort((a, b) => (a['dueDate'] as Timestamp).toDate().compareTo((b['dueDate'] as Timestamp).toDate()));

          Map<String, dynamic>? selectedPaymentData;
          for (var paymentData in paymentDataList) {
            if (paymentData['status'] == 'Overdue') {
              if (selectedPaymentData == null || (paymentData['dueDate'] as Timestamp).toDate().isBefore((selectedPaymentData['dueDate'] as Timestamp).toDate())) {
                selectedPaymentData = paymentData;
              }
            } else if (selectedPaymentData == null) {
              selectedPaymentData = paymentData;
            }
          }

          if (selectedPaymentData != null) {
            var vendorData = vendorDoc.data() as Map<String, dynamic>;
            vendorData['status'] = selectedPaymentData['status'];
            vendorData['billingCycle'] = selectedPaymentData['billingCycle']; // Use billingCycle from stall_payment
            vendorData['id'] = vendorId; // Add vendor ID
            vendorData['dueDate'] = selectedPaymentData['dueDate']; // Add dueDate
            vendorData['total'] = selectedPaymentData['total']; // Add total
            vendorData['totalAmountDue'] = selectedPaymentData['totalAmountDue']; // Add totalAmountDue
            filteredVendors.add(vendorData);
          }
        }
      }

      setState(() {
        _vendors = vendorsSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add vendor ID
          return data;
        }).toList();
        _filteredVendors = filteredVendors;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _selectedFilter = filter;
      _filterVendors();
    });
  }

  Future<void> _filterVendors() async {
    List<Map<String, dynamic>> filteredVendors = [];
    for (var vendor in _vendors) {
      String vendorId = vendor['id'];
      QuerySnapshot paymentSnapshot = await _firestore
          .collection('stall_payment')
          .where('vendorId', isEqualTo: vendorId)
          .where('status', whereIn: ['Pending', 'Overdue'])
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> paymentDataList = paymentSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        paymentDataList.sort((a, b) => (a['dueDate'] as Timestamp).toDate().compareTo((b['dueDate'] as Timestamp).toDate()));

        Map<String, dynamic>? selectedPaymentData;
        for (var paymentData in paymentDataList) {
          if (paymentData['status'] == 'Overdue') {
            if (selectedPaymentData == null || (paymentData['dueDate'] as Timestamp).toDate().isBefore((selectedPaymentData['dueDate'] as Timestamp).toDate())) {
              selectedPaymentData = paymentData;
            }
          } else if (selectedPaymentData == null) {
            selectedPaymentData = paymentData;
          }
        }

        if (selectedPaymentData != null) {
          var fullName = '${vendor['firstName']} ${vendor['lastName']}'.toLowerCase();
          var billingCycle = selectedPaymentData['billingCycle']?.toLowerCase();

          bool nameMatch = fullName.contains(_searchQuery);
          bool filterMatch = _selectedFilter == 'all' || billingCycle == _selectedFilter;

          if (nameMatch && filterMatch) {
            vendor['status'] = selectedPaymentData['status'];
            vendor['billingCycle'] = selectedPaymentData['billingCycle']; // Use billingCycle from stall_payment
            vendor['dueDate'] = selectedPaymentData['dueDate']; // Add dueDate
            vendor['total'] = selectedPaymentData['total']; // Add total
            vendor['totalAmountDue'] = selectedPaymentData['totalAmountDue']; // Add totalAmountDue
            filteredVendors.add(vendor);
          }
        }
      }
    }
    setState(() {
      _filteredVendors = filteredVendors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pending Payments",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterButtons(),
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
                  _filterVendors();
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
                          var vendor = _filteredVendors[index];
                          var dueDate = (vendor['dueDate'] as Timestamp).toDate();
                          var now = DateTime.now();
                          var daysDifference = dueDate.difference(now).inDays;
                          String dueMessage;
                          Color dueColor;

                          if (dueDate.isAtSameMomentAs(now)) {
                            dueMessage = 'Due today';
                            dueColor = Colors.orange;
                          } else if (dueDate.isAfter(now)) {
                            dueMessage = 'Due in $daysDifference days';
                            dueColor = Colors.green;
                          } else {
                            dueMessage = 'Due ${daysDifference.abs()} days ago';
                            dueColor = Colors.red;
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Stallconfigtap(vendorId: vendor['id']),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 1.0),
                                borderRadius: BorderRadius.circular(8.0),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _highlightMatch(
                                          '${vendor['firstName']} ${vendor['lastName']}',
                                          _searchQuery,
                                          const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          'Location: ${vendor['stallInfo']['location']}',
                                          style: const TextStyle(fontSize: 14, color: Colors.black),
                                        ),
                                        Text(
                                          'Status: ${vendor['status']}',
                                          style: const TextStyle(fontSize: 14, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        vendor['totalAmountDue'] != null
                                            ? 'Total: ₱${vendor['totalAmountDue']}'
                                            : 'Total: ₱${vendor['total']}',
                                        style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        dueMessage,
                                        style: TextStyle(color: dueColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFilterButton('All', 'all'),
            _buildFilterButton('Daily', 'daily'),
            _buildFilterButton('Weekly', 'weekly'),
            _buildFilterButton('Monthly', 'monthly'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyFilter(filter),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: _selectedFilter == filter ? Colors.green : Colors.transparent,
            border: Border(
              right: BorderSide(color: Colors.grey[300]!, width: 1.0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: _selectedFilter == filter ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
