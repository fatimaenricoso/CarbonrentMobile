import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SelectVendorsScreen extends StatefulWidget {
  final String payor;
  final String paymentDate;
  final String totalFees;
  final Map<String, String> feeSummary;
  final int numberOfTickets;
  final String totalAmount;

  const SelectVendorsScreen({
    Key? key,
    required this.payor,
    required this.paymentDate,
    required this.totalFees,
    required this.feeSummary,
    required this.numberOfTickets,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _SelectVendorsScreenState createState() => _SelectVendorsScreenState();
}

class _SelectVendorsScreenState extends State<SelectVendorsScreen> {
  List<String> selectedVendors = [];
  String searchQuery = '';
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;
  final List<Map<String, dynamic>> _savedPayments = []; // List to hold saved payment details
  bool selectAll = false; // Track select all state

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchApprovedVendors();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
  }

  String cleanAmount(String amount) {
    // Remove the currency symbol and any commas or spaces
    return amount.replaceAll(RegExp(r'[^\d.]'), '');
  }

  Future<void> _undoLastPayment(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('payments').doc(docId).delete(); // Remove from Firestore
      _savedPayments.removeWhere((payment) => payment['id'] == docId); // Remove from local list

      // Show confirmation message after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment details removed successfully!')),
      );

      // Refresh the UI
      setState(() {});
    } catch (e) {
      print("Error undoing payment: $e");
    }
  }

   void _toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      selectedVendors = selectAll
          ? _vendors.map((vendor) => vendor['id'] as String).toList() // Cast to String
          : [];
    });
  }

Future<void> _fetchApprovedVendors() async {
  setState(() {
    _isLoading = true;
  });

  try {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      QuerySnapshot collectorQuerySnapshot = await FirebaseFirestore.instance
          .collection('ambulant_collector')
          .where('email', isEqualTo: user.email)
          .get();

      if (collectorQuerySnapshot.docs.isNotEmpty) {
        var collectorDoc = collectorQuerySnapshot.docs.first;
        var collectorData = collectorDoc.data() as Map<String, dynamic>;

        if (collectorData.containsKey('collector')) {
          String collectorId = collectorData['collector'];

          // Fetch only a limited number of vendors for pagination
          QuerySnapshot vendorSnapshot = await FirebaseFirestore.instance
              .collection('approved_vendors')
              .where('collector', isEqualTo: collectorId)
              .where('status', isEqualTo: 'Approved')
              .limit(10)  // Fetch only 10 vendors at a time
              .get();

          setState(() {
            _vendors = vendorSnapshot.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'full_name': '${data['first_name']} ${data['last_name']}',
              };
            }).toList();
            _isLoading = false;
          });
        }
      }
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print("Error fetching vendors: $e");
  }
}



  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
    });
  }

   Future<String?> _processPayment(
  BuildContext context,
  String vendorId,
  String totalAmount,
) async {
  final url = Uri.parse('https://api.paymongo.com/v1/payment_intents');
  final String secretApiKey = 'sk_test_UWP3hXVRoBAk4GuH8Q85Dvrk'; // Your secret key
  final String clientKey = 'pk_test_1m9SJyLLxoSTupHBjY1KXoVf'; // Replace with your client key

  // Clean the totalAmount before parsing
  final cleanedAmount = cleanAmount(totalAmount);

  // Prepare the payment link data
  final paymentData = {
    'data': {
      'attributes': {
        'amount': (double.parse(cleanedAmount) * 100).toInt(), // Convert to centavos
        'currency': 'PHP',
        'payment_method_allowed': [
          "gcash" // Only GCash as the allowed payment method
        ],
        'description': 'Payment for Vendor: $vendorId',
        'client_key': clientKey // Use your client key here for client-side operations
      },
    },
  };

  try {
    // Make the request to PayMongo API
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$secretApiKey:'))}', // Use secret key for auth
        'Content-Type': 'application/json',
      },
      body: jsonEncode(paymentData),
    );

    // Check if the request was successful
    if (response.statusCode == 200) {
      // Parse the response
      final responseData = json.decode(response.body);
      
      // Check if checkout_url is available in the response
      if (responseData['data']['attributes'].containsKey('checkout_url')) {
        String paymentUrl = responseData['data']['attributes']['checkout_url'];
        
        // You can also handle other statuses here if needed
        return paymentUrl; // Return the checkout URL
      } else {
        // Handle case where checkout_url is not available
        print('Checkout URL not found in the response.');
        return null;
      }
    } else {
      // Handle error based on the status code
      print('Failed to create payment intent: ${response.statusCode} ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
      return null;
    }
  } catch (e) {
    print('Error processing payment: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment processing failed!')),
    );
    return null; // Return null if there's an error
  }
}


Future<void> _savePaymentDetails(String vendorId, String? paymentUrl) async {
  // Prepare payment data
  final paymentData = {
    'vendor_id': vendorId,
    'payor': widget.payor,
    'payment_date': widget.paymentDate,
    'total_fees': widget.totalFees,
    'fee_summary': widget.feeSummary,
    'number_of_tickets': widget.numberOfTickets,
    'total_amount': widget.totalAmount,
    'payment_url': paymentUrl ?? '', // Save payment URL if available
    'status': 'Pending', // Initial status of the payment
  };

  // Save to Firestore and add to local saved payments list
  DocumentReference docRef = await FirebaseFirestore.instance.collection('payments').add(paymentData);
  _savedPayments.add({'id': docRef.id, ...paymentData}); // Store payment details with document ID

  // Show confirmation message after saving
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Payment details saved successfully!')),
  );

  // Enable Undo action after saving
  setState(() {});
}

void _saveSelectedVendors(BuildContext context) async {
  // Show a loading indicator while processing
  setState(() {
    _isLoading = true;
  });

  try {
    for (var vendorId in selectedVendors) {
      final vendor = _vendors.firstWhere((vendor) => vendor['id'] == vendorId);
      
      // Process the payment and get the payment link
      String? paymentUrl = await _processPayment(context, vendor['id'], widget.totalAmount);
      
      if (paymentUrl != null) {
        // Show success message for each vendor
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment initiated successfully for ${vendor['full_name']}!')),
        );
      } else {
        // Handle the case where payment processing failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed for vendor: ${vendor['full_name']}')),
        );
      }
    }
  } catch (e) {
    print('Error saving selected vendors: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An error occurred while saving payments.')),
    );
  } finally {
    // Hide loading indicator
    setState(() {
      _isLoading = false;
    });
  }
}


  
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredVendors = _vendors.where((vendor) {
      return vendor['full_name']!.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
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
                Icon(Icons.check_circle, color: Colors.white), // Icon next to the text
                SizedBox(width: 8), // Space between icon and text
                Text(
                  "Select Vendor",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Set text color to white
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.green, // Set background color to green
          elevation: 1.0,
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary Section
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payor
                    Row(
                      children: [
                        const Text(
                          'Collector: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${widget.payor}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Payment Date
                    Row(
                      children: [
                        const Text(
                          'Date Issued: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${widget.paymentDate}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Summary of Fees
                    const Text(
                      'Summary of Fees:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Dynamic List of Fees
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.feeSummary.length,
                      itemBuilder: (context, index) {
                        String feeName = widget.feeSummary.keys.elementAt(index);
                        String feeValue = widget.feeSummary[feeName]!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                feeName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                feeValue,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Check for Ticket Rate before displaying Number of Tickets and Total Amount
                    if (widget.feeSummary.containsKey('Ticket Rate')) ...[
                      // Number of Tickets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Number of Tickets:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${widget.numberOfTickets}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Total Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Ticket Amount:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            widget.totalAmount,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Total Fees
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Fees:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.totalFees,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

        // Search Bar Section
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            height: 40, 
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(255, 33, 168, 53)), // Green border
              borderRadius: const BorderRadius.all(Radius.circular(8)), // Rounded corners
            ),
            child: Stack(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query;
                    });
                  },
                  style: const TextStyle(color: Color.fromARGB(255, 17, 16, 16)),
                  decoration: const InputDecoration(
                    hintText: 'Search vendors...',
                    hintStyle: TextStyle(color: Color.fromARGB(255, 196, 195, 195)),
                    border: InputBorder.none, // Remove default border
                    focusedBorder: InputBorder.none, // Remove focused border
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color.fromARGB(255, 33, 168, 53),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Select All Checkbox
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between the checkbox and button
                children: [
                  Row(
                    children: [
                      Checkbox(
                        activeColor: const Color.fromARGB(255, 41, 190, 46), // Color when checked
                        value: selectAll,
                        onChanged: _toggleSelectAll,
                      ),
                      const Text('Select All'),
                    ],
                  ),
                 ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 224, 250, 219),
                      foregroundColor: const Color.fromARGB(255, 49, 118, 2), // Text color of the button
                      padding: const EdgeInsets.symmetric(horizontal: 14.0), // Horizontal padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0), // Adjust the radius here
                      ),
                    ),
                    onPressed: selectedVendors.isEmpty
                        ? null
                        : () {
                            _saveSelectedVendors(context);
                          },
                    child: const Text('Send to All'),
                  ),
                ],
              ),
              const SizedBox(height: 12,),
              // List of Vendors with Checkboxes
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredVendors.length,
                      itemBuilder: (context, index) {
                        final vendor = filteredVendors[index];
                        bool isSaved = _savedPayments.any((payment) => payment['vendor_id'] == vendor['id']);
                        bool isSelected = selectedVendors.contains(vendor['id']);

                        return ListTile(
                          leading: Checkbox(
                            activeColor: const Color.fromARGB(255, 41, 190, 46),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedVendors.add(vendor['id']);
                                } else {
                                  selectedVendors.remove(vendor['id']);
                                }
                                selectAll = selectedVendors.length == filteredVendors.length;
                              });
                            },
                          ),
                          title: RichText(
                            text: TextSpan(
                              children: _highlightMatches(vendor['full_name'], searchQuery),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          trailing: Container(
                            width: 70,
                            height: 35,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 224, 250, 219),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextButton(
                              onPressed: () {
                                if (!isSaved) {
                                  _savePaymentDetails(vendor['id'], vendor['full_name']);
                                } else {
                                  final savedPayment = _savedPayments.firstWhere((payment) => payment['vendor_id'] == vendor['id']);
                                  _undoLastPayment(savedPayment['id']);
                                }
                              },
                              child: Text(
                                isSaved ? 'Undo' : 'Save',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isSaved ? const Color.fromARGB(255, 32, 114, 3) : const Color.fromARGB(255, 49, 118, 2),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
           )
         );
       }
}

      List<TextSpan> _highlightMatches(String text, String query) {
          if (query.isEmpty) {
            return [TextSpan(text: text)];
          }

          List<TextSpan> spans = [];
          RegExp regExp = RegExp(RegExp.escape(query), caseSensitive: false);
          Iterable<RegExpMatch> matches = regExp.allMatches(text);

          int start = 0;
          for (var match in matches) {
            if (match.start > start) {
              spans.add(TextSpan(text: text.substring(start, match.start)));
            }
            spans.add(TextSpan(
              text: text.substring(match.start, match.end),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ));
            start = match.end;
          }
          if (start < text.length) {
            spans.add(TextSpan(text: text.substring(start)));
          }

          return spans;
        }