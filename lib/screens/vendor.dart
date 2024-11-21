import 'package:ambulantcollector/screens/add_vendor.dart';
import 'package:ambulantcollector/screens/approve_vendor.dart';
import 'package:ambulantcollector/screens/assignpayment_all.dart';
import 'package:ambulantcollector/screens/dashboardvendor.dart';
import 'package:ambulantcollector/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:ambulantcollector/screens/status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Vendor extends StatefulWidget {
  const Vendor({Key? key}) : super(key: key);

  @override
  _VendorState createState() => _VendorState();
}

class _VendorState extends State<Vendor> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
  String _selectedStatus = 'All';
  String _searchQuery = '';

   @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back icon with white color
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardVendor()), // Navigate to Dashboard
            );
          },
        ),
        title: const Text(""), // Empty title to avoid spacing issues
        flexibleSpace: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the text and icon
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add, color: Colors.white), // Icon next to the text
              SizedBox(width: 8),
              Text(
                "Add Vendors",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40,
                    child: Icon(Icons.person, size: 50, color: Colors.blueGrey[900]),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    'User Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Drawer Body
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _createDrawerItem(
                    icon: Icons.person,
                    text: 'My Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignPaymentAllScreen(), // Navigate to ProfileScreen
                        ),
                      );
                    },
                  ),
                  _createDrawerItem(
                    icon: Icons.app_registration,
                    text: 'Registration',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Vendor(),
                        ),
                      );
                    },
                  ),
                  _createDrawerItem(
                    icon: Icons.business,
                    text: 'Vendors',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ApproveVendor(),
                        ),
                      );
                    },
                  ),
                  _createDrawerItem(
                    icon: Icons.settings,
                    text: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(), // Navigate to SettingsScreen
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Filter Navigation Bar
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  _buildFilterButton('All'),
                  _buildFilterButton('Pending'),
                  _buildFilterButton('Request Info'),
                ],
              ),
            ),
            // Search TextField
            TextField(
              decoration: const InputDecoration(
/*                 labelText: 'Search by last name or number',
 */                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildUserList(),
            ),
          ],
        ),
      ),
      // Add FloatingActionButton for adding a new vendor
      floatingActionButton: Tooltip(
        message: 'Add Vendor',
        child: FloatingActionButton(
          onPressed: _navigateToAddVendorScreen,
          backgroundColor: const Color.fromARGB(255, 53, 176, 39),
          child: const Icon(
            Icons.add,
            color: Colors.white, // Set the icon color to white
          ), // Set the button background color
        ),
      ),
      )
    );
  }

  void _navigateToAddVendorScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVendorScreen(),
      ),
    );
  }

  Widget _buildFilterButton(String status) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _selectedStatus == status ? Colors.green : Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Adjust the curve here
        ),
        backgroundColor: Colors.transparent, // Ensure no background color
      ),
      onPressed: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Text(
        status,
        style: TextStyle(
          color: _selectedStatus == status ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

Widget _buildUserList() {
  return StreamBuilder<QuerySnapshot>(
    stream: usersRef.orderBy('created_at').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (!snapshot.hasData) {
        return const Center(child: Text('No data available'));
      }

      // Get all users from the snapshot
      final allUsers = snapshot.data!.docs;

      // Filter the users based on status and search query
      final filteredUsers = allUsers.where((user) {
        final status = user['status'] as String;
        final bool matchesStatus = _selectedStatus == 'All'
            ? ['Pending', 'Request Info'].contains(status)
            : _mapStatusToFilter(status) == _selectedStatus;
        final bool matchesQuery = user['last_name'].toString().toLowerCase().contains(_searchQuery) ||
            getNumberFromDocumentId(user.id).contains(_searchQuery);
        return matchesStatus && matchesQuery;
      }).toList();

      if (filteredUsers.isEmpty) {
        return const Center(child: Text('No matching results'));
      }

      return ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
/*           final number = getNumberFromDocumentId(user.id);
 */       final first = user['first_name'];
          final last = user['last_name'];
          final String vendorId = user.id; // Get the vendor document ID
          final String status = user['status'] ?? 'Pending'; // Get the status field from Firestore
          final String actionLabel = _mapStatusToActionLabel(status);
          final Color actionColor = _mapStatusToActionColor(status);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatusScreen(vendorId: vendorId),
                        )
                      );
                    },
                    child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green, // Color background only for the profile icon
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  ),
                  const SizedBox(width: 15),
                  // Details and action buttons
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$last, ${first[0]}.",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Status: $actionLabel',
                          style: TextStyle(
                            color: actionColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (status != 'Approved' && status != 'Declined') ...[
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                               _showApproveDialog(context, vendorId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green, // Background color
                                  foregroundColor: Colors.white, // Text color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8), // Rounded corners
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Approve'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  _showDeclineDialog(context, vendorId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 120, 116, 116), // Background color
                                  foregroundColor: Colors.white, // Text color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8), // Rounded corners
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Decline'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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

void _showApproveDialog(BuildContext context, String vendorId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Approval'),
        content: const Text('Are you sure you want to approve this vendor?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleApproval(vendorId);
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
        ],
      );
    },
  );
}

void _showDeclineDialog(BuildContext context, String vendorId) {
  final TextEditingController reasonController = TextEditingController();
  String selectedReason = '';
  List<String> suggestedReasons = [
    'Document requested not uploaded',
    'Uploaded fake ID',
    'Incomplete application',
    'Incorrect information provided',
    'Application does not meet criteria',
  ];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Method to set the reason
          void setReason(String reason) {
            setState(() {
              reasonController.text = reason;
              selectedReason = reason;
            });
          }

          // Method to clear the reason
          void clearReason() {
            setState(() {
              reasonController.clear();
              selectedReason = '';
            });
          }

          // Method to remove a suggested reason
          void removeSuggestedReason(String reason) {
            setState(() {
              suggestedReasons.remove(reason);
              // Clear the selected reason if it matches the removed one
              if (selectedReason == reason) {
                clearReason();
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // Curve all edges equally
            ),
            titlePadding: const EdgeInsets.all(0), // Remove default padding
            title: Container(
              decoration: const BoxDecoration(
                color: Colors.green, // Green color for the top bar
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(15.0), // Curve the top edges
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: const Text(
                'Decline Vendor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            content: SizedBox(
              width: 300, // Fixed width for the dialog
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(''),
                  const SizedBox(height: 10),
                  // Column with rectangular boxes for reasons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: suggestedReasons.map((reason) {
                      return _buildReasonButton(
                        reason,
                        setReason,
                        () => removeSuggestedReason(reason), // Pass the specific reason to remove
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  // Text field with max length of 50 characters
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter a reason for declining',
                      suffixIcon: selectedReason.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: clearReason,
                            )
                          : null,
                    ),
                    onChanged: (text) {
                      setState(() {
                        selectedReason = text;
                      });
                    },
                    maxLines: null, // Allow multiple lines
                    maxLength: 150, // Limit the number of characters to 50
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selectedReason.isNotEmpty
                    ? () {
                        Navigator.of(context).pop();
                        _handleDecline(vendorId, selectedReason); // Updated call
                      }
                    : null, // Disable button if no reason is entered
                child: const Text('Decline'),
              ),
            ],
          );
        },
      );
    },
  );
}


Widget _buildReasonButton(String reason, void Function(String) onTap, void Function() onClear) {
  return Container(
    margin: const EdgeInsets.only(bottom: 5),
    child: SizedBox(
      width: 220, // Set a fixed width for the button
      height: 30, // Set a fixed height for the button
      child: ElevatedButton(
        onPressed: () => onTap(reason),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300], // Background color
          foregroundColor: Colors.black, // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          padding: const EdgeInsets.all(0), // Remove extra padding inside the button
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                reason,
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 14),
              onPressed: onClear, // Clear the reason when the 'X' is clicked
            ),
          ],
        ),
      ),
    ),
  );
}



// Method for handling approval
void _handleApproval(String vendorId) async {
  // Debugging: Check the current user
  User? currentUser = FirebaseAuth.instance.currentUser;
  print('Current user: $currentUser');

  // Proceed only if user is logged in
  if (currentUser == null) {
    print('No logged-in user found.');
    return;
  }

  DocumentReference usersDocRef = usersRef.doc(vendorId);
  
  try {
    String approverEmail = currentUser.email ?? 'Unknown';
    DateTime approvalTime = DateTime.now(); // Capture the current time

    // Update the vendor's status and add approval metadata
    await usersDocRef.update({
      'status': 'Approved',
      'approved_by': approverEmail,
      'approved_at': approvalTime,
    });

    DocumentSnapshot vendorSnapshot = await usersDocRef.get();

    if (vendorSnapshot.exists) {
      Map<String, dynamic> vendorData = vendorSnapshot.data() as Map<String, dynamic>;

      if (vendorData['status'] == 'Approved') {
        await FirebaseFirestore.instance
            .collection('approved_vendors')
            .doc(vendorId)
            .set(vendorData);
      } else {
        print('Vendor status is not approved.');
      }
    } else {
      print('Vendor not found.');
    }
  } catch (e) {
    print('Error approving vendor: $e');
  }
}

  // Method for handling decline
  void _handleDecline(String vendorId, String reason) {
  // Logic for declining a vendor
  usersRef.doc(vendorId).update({
    'status': 'Declined',
    'decline_reason': reason,
  });
}

 // Method to map status to filter value
  String _mapStatusToFilter(String status) {
    switch (status) {
      case 'Pending':
        return 'Pending';
      case 'Request Info':
        return 'Request Info';
      case 'Approved':
        return 'Approved';
      case 'Declined':
        return 'Declined';
      default:
        return 'All';
    }
  }

  // Method to map Firestore status to action label and color
  String _mapStatusToActionLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Pending';
      case 'Request Info':
        return 'Request Info';
      case 'Approved':
        return 'Approved';
      case 'Declined':
        return 'Declined';
      default:
        return 'Unknown';
    }
  }

  Color _mapStatusToActionColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Request Info':
        return Colors.blue;
      case 'Approved':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to extract number from document ID
  String getNumberFromDocumentId(String documentId) {
    final parts = documentId.split('_');
    return parts.isNotEmpty ? parts.last : '';
  }

  Widget _createDrawerItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[900]),
      title: Text(text),
      onTap: onTap,
    );
  }
}
