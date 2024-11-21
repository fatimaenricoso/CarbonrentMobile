import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Thursday extends StatelessWidget {
  final CollectionReference approvedVendorsRef =
      FirebaseFirestore.instance.collection('approved_vendors');

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
                Icon(Icons.assignment, color: Colors.white), // Icon next to the text
                SizedBox(width: 8), // Space between icon and text
                Text(
                  "Thursday Vendors",
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
      body: _buildThursdayVendorList(context),
    );
  }

  Widget _buildThursdayVendorList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: approvedVendorsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No vendors assigned on Thursday'));
        }

        final vendors = snapshot.data!.docs;

        final thursdayVendors = vendors.where((vendor) {
          // Check for vendors assigned on Thursday
          return _isVendorAssignedOnDay(vendor, 'Thursday');
        }).toList();

        if (thursdayVendors.isEmpty) {
          return const Center(child: Text('No vendors assigned on Thursday'));
        }

        return ListView.builder(
          itemCount: thursdayVendors.length,
          itemBuilder: (context, index) {
            final vendor = thursdayVendors[index];
            final firstName = vendor['first_name'];
            final lastName = vendor['last_name'];
            final vendorId = vendor.id; // Get the vendor ID for deletion

            // Find the specific field that contains 'Thursday'
            String? thursdayField = _findThursdayField(vendor);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$lastName, $firstName",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Assigned on: Thursday',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (thursdayField != null) {
                          _deleteVendorAssignment(vendorId, thursdayField, context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No Thursday assignment found')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isVendorAssignedOnDay(QueryDocumentSnapshot vendor, String day) {
    final vendorData = vendor.data() as Map<String, dynamic>?;

    if (vendorData == null) {
      return false;
    }

    for (int i = 1; i <= 10; i++) {
      final fieldValue = vendorData['day_assign_$i'];
      if (fieldValue == day) {
        return true;
      }
    }
    return false;
  }

  String? _findThursdayField(QueryDocumentSnapshot vendor) {
    final vendorData = vendor.data() as Map<String, dynamic>?;

    if (vendorData == null) {
      return null;
    }

    for (int i = 1; i <= 10; i++) {
      final fieldValue = vendorData['day_assign_$i'];
      if (fieldValue == 'Thursday') {
        return 'day_assign_$i'; // Return the specific field name
      }
    }
    return null; // No Thursday assignment found
  }

  Future<void> _deleteVendorAssignment(String vendorId, String fieldName, BuildContext context) async {
    try {
      // Get the vendor document reference
      DocumentReference vendorDocRef = approvedVendorsRef.doc(vendorId);

      // Update the Firestore document to remove the assigned day
      await vendorDocRef.update({
        fieldName: FieldValue.delete(), // Use the dynamic field name
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor assignment deleted')),
      );
    } catch (e) {
      print('Error deleting vendor assignment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
