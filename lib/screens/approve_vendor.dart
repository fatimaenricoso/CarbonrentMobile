import 'package:ambulantcollector/screens/dashboardvendor.dart';
import 'package:ambulantcollector/screens/profile_screen.dart'; // Import ProfileScreen
import 'package:ambulantcollector/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:ambulantcollector/screens/vendor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ApproveVendor extends StatefulWidget {
  const ApproveVendor({Key? key}) : super(key: key);

  @override
  _ApproveVendorState createState() => _ApproveVendorState();
}

class _ApproveVendorState extends State<ApproveVendor> {
  final CollectionReference approvedCollectorsRef = FirebaseFirestore.instance.collection('approved_vendors');
  String _searchQuery = '';
  String _dialogSearchQuery = ''; // Separate search query for the dialog
  int _selectedIndex = 2; // Default to the current screen's index
  String? _selectedSchedule; // For the dropdown selection
  bool _selectAllVendors = false; // For selecting/unselecting all vendors
  List<bool> _selectedVendors = []; // For tracking selected vendors individually

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      switch (index) {
        case 0:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Vendor(),
            ),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ApproveVendor(),
            ),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
          break;
      }
    }
  }

void _showEditDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter dialogSetState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded top corners
            child: SizedBox(
              height: 550, // Adjust the height as needed
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 37, 218, 43),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20), // Curved corners for the top
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and icon
                        children: [
                          const Text(
                            'ASSIGN SCHEDULE',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2, // Two parts for the search
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              dialogSetState(() {
                                _dialogSearchQuery = value.toLowerCase(); // Updates only the dialog search query
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Checkbox for Select All/Unselect All
                        Row(
                          children: [
                            Checkbox(
                              value: _selectAllVendors,
                              activeColor: Colors.green, // Change the check color to green
                              onChanged: (bool? value) {
                                dialogSetState(() {
                                  _selectAllVendors = value ?? false;
                                  _selectedVendors = List.filled(_selectedVendors.length, _selectAllVendors);
                                });
                              },
                            ),
                            const Text('Select All'),
                          ],
                        ),
                        // Dropdown positioned next to the checkbox with a green underline
                        SizedBox(
                          width: 150, // Adjust this width based on your preference
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Assigned Schedule',
                              labelStyle: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold), // Keep label text color black
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.green), // Green underline
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.green), // Green underline when enabled
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.green), // Green underline when focused
                              ),
                            ),
                            dropdownColor: Colors.white, // Set the dropdown background color if needed
                            value: _selectedSchedule,
                            items: const [
                              DropdownMenuItem(
                                value: 'Daily',
                                child: Text('Daily'),
                              ),
                              DropdownMenuItem(
                                value: 'Monday',
                                child: Text('Monday'),
                              ),
                              DropdownMenuItem(
                                value: 'Tuesday',
                                child: Text('Tuesday'),
                              ),
                              DropdownMenuItem(
                                value: 'Wednesday',
                                child: Text('Wednesday'),
                              ),
                              DropdownMenuItem(
                                value: 'Thursday',
                                child: Text('Thursday'),
                              ),
                              DropdownMenuItem(
                                value: 'Friday',
                                child: Text('Friday'),
                              ),
                              DropdownMenuItem(
                                value: 'Saturday',
                                child: Text('Saturday'),
                              ),
                              DropdownMenuItem(
                                value: 'Sunday',
                                child: Text('Sunday'),
                              ),
                            ],
                            onChanged: (value) {
                              dialogSetState(() {
                                _selectedSchedule = value; // Update the selected schedule
                              });
                            },
                            style: const TextStyle(color: Colors.black), // Set selected text color to black
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Vendor List with Checkboxes
Expanded(
  child: _buildDialogUserList(dialogSetState),
),
Padding(
  padding: const EdgeInsets.all(10.0),
  child: ElevatedButton(
    onPressed: () async {
      if (_selectedSchedule != null) {
        // Get approved vendors currently displayed (filtered)
        final approvedUsersSnapshot = await approvedCollectorsRef
            .where('status', isEqualTo: 'Approved')
            .get();
        
        // List to hold selected vendor IDs
        List<String> selectedVendorIds = [];

        // Collect IDs of selected vendors
        for (int index = 0; index < _selectedVendors.length; index++) {
          if (_selectedVendors[index]) {
            String vendorId = approvedUsersSnapshot.docs[index].id; // Get the vendor ID of the selected user
            selectedVendorIds.add(vendorId); // Add to the list of selected IDs
          }
        }

        bool hasUpdatedVendors = false; // Flag to track if any vendors were updated
        bool dialogShown = false; // Flag to prevent multiple dialogs

        // Loop through selected vendor IDs and perform the assignment
        for (String vendorId in selectedVendorIds) {
          // Fetch existing assignments
          DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
              .collection('approved_vendors')
              .doc(vendorId)
              .get();
          int assignmentCount = 0;

          if (vendorDoc.exists) {
            Map<String, dynamic>? data = vendorDoc.data() as Map<String, dynamic>?;
            data?.forEach((key, value) {
              if (key.startsWith('day_assign_')) {
                // Extract the number from the key and find the maximum assignment count
                int count = int.tryParse(key.split('_').last) ?? 0;
                if (count > assignmentCount) {
                  assignmentCount = count;
                }
              }
            });
          }

          // Increment assignment count for new key
          assignmentCount += 1;
          String newAssignmentKey = 'day_assign_$assignmentCount';

          // Update Firestore with the new assignment
          await FirebaseFirestore.instance.collection('approved_vendors').doc(vendorId).set({
            newAssignmentKey: _selectedSchedule,
          }, SetOptions(merge: true)); // Merge to avoid overwriting existing assignments

          hasUpdatedVendors = true; // Set the flag to true as at least one vendor is updated
        }

        if (hasUpdatedVendors && !dialogShown) {
          dialogShown = true; // Prevent additional dialogs
                              // Show success message as a dialog only if vendors were updated
                              showDialog(
                                context: context,
                                barrierDismissible: false, // Disable dialog dismiss when clicking outside
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    contentPadding: const EdgeInsets.all(0), // No padding around the content
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15), // Curved corners for the dialog
                                    ),
                                    // Use Column to include the green header and content
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min, // Use minimum size for the dialog
                                      children: [
                                        // Topmost green padding container
                                        Container(
                                          height: 60, // Height of the green padding
                                          decoration: const BoxDecoration(
                                            color: Color.fromARGB(255, 36, 204, 42), // Green background for the topmost padding
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(15), // Curve the top left
                                              topRight: Radius.circular(15), // Curve the top right
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'ASSIGNED SUCCESSFULLY!',
                                              style: TextStyle(color: Colors.white, fontSize: 18), // Change title text color to white
                                            ),
                                          ),
                                        ),
                                        // Content of the dialog
                                        Container(
                                          width: double.infinity, // Fill the width of the dialog
                                          padding: const EdgeInsets.all(20), // Add padding around the content
                                          child: const Center(
                                            child: Text(
                                              'Schedule Assigned Successfully!',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center, // Center the content text
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text(
                                          'OK',
                                          style: TextStyle(color: Colors.green), // Change 'OK' text color to green
                                        ),
                                        onPressed: () {
                                          dialogShown = false; // Reset the flag when the dialog is dismissed
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a day to assign.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 222, 251, 223), // Save button color
                        minimumSize: const Size(double.infinity, 50), // Expands button width to fill the parent
                        textStyle: const TextStyle(color: Color.fromARGB(255, 37, 161, 51)), // Changes text color to white
                      ),
                      child: const Text('Save'),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Icon(Icons.people_alt_outlined, color: Colors.white), // Icon next to the text
              SizedBox(width: 8),
              Text(
                "Approved Vendors",
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
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Search TextField for main screen
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase(); // Updates only the main screen search query
                });
              },
            ),
            const SizedBox(height: 10),
            // Edit button
            Align(
              alignment: Alignment.centerRight, // Aligns the button to the right
              child: ElevatedButton(
                onPressed: _showEditDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 37, 201, 42), // Set button color
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min, // Minimize the row size to fit the content
                  children: [
                    Icon(Icons.edit, color: Colors.white), // Add an edit icon with white color
                    SizedBox(width: 8), // Add spacing between the icon and text
                    Text(
                      'Schedule Vendor',
                      style: TextStyle(color: Colors.white), // Change text color to white
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: _buildApprovedUserList(),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildApprovedUserList() {
  final currentUser = FirebaseAuth.instance.currentUser; // Get the logged-in user

  if (currentUser == null) {
    return const Center(child: Text('No collector logged in.'));
  }

  // Assuming you are using the email as the document ID for ambulant_collector
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance.collection('ambulant_collector')
        .where('email', isEqualTo: currentUser.email) // Query by email if that's used as document ID
        .limit(1) // Limiting to a single result as only one collector should match the email
        .get(),
    builder: (context, collectorSnapshot) {
      if (collectorSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (collectorSnapshot.hasError) {
        return Center(child: Text('Error: ${collectorSnapshot.error}'));
      }

      if (!collectorSnapshot.hasData || collectorSnapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Collector data not found.'));
      }

      // Get the collector's assigned collection value (e.g., '01', '02', etc.)
      final collectorDoc = collectorSnapshot.data!.docs.first;
      final collectorData = collectorDoc.data() as Map<String, dynamic>;
      final String assignedCollection = collectorData['collector'] ?? '';

      if (assignedCollection.isEmpty) {
        return const Center(child: Text('Collector has no assigned collection.'));
      }

      // Now query the approved_vendors collection based on the collector's assigned collection
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('approved_vendors')
            .where('status', isEqualTo: 'Approved')
            .where('collector', isEqualTo: assignedCollection) // Filter by the collector's assignment
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vendors available.'));
          }

          final approvedUsers = snapshot.data!.docs;
          final filteredUsers = approvedUsers.where((user) {
            final matchesQuery = user['last_name'].toString().toLowerCase().contains(_searchQuery) ||
                getNumberFromDocumentId(user.id).contains(_searchQuery);
            return matchesQuery;
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(child: Text('No matching results'));
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final first = user['first_name'];
              final last = user['last_name'];

              // Initialize a list to hold day assignments
              List<String> dayAssignments = [];
              List<String> dayFields = []; // To hold the field names for deletion

              // Check for fields starting with 'day_assign'
              for (int i = 1; i <= 7; i++) { // Adjust number if needed
                String fieldName = 'day_assign_$i';
                final data = user.data() as Map<String, dynamic>; // Get the document data as a map
                if (data.containsKey(fieldName)) {
                  dayAssignments.add(data[fieldName]);
                  dayFields.add(fieldName); // Store the field name for deletion
                }
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Added for spacing
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$last, ${first[0]}.",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 21, 21, 21),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Approved',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      // Display day assignments on the right
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end, // Align the text to the right
                        children: dayAssignments.map((day) {
                          return Text(
                            day,
                            style: const TextStyle(fontSize: 14, color: Colors.black), // Style the day text
                          );
                        }).toList(),
                      ),
                      // Add Edit Icon
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color.fromARGB(255, 27, 27, 27)),
                        onPressed: () {
                          // Open a dialog to confirm deletion
                          _showEditDialogs(context, dayAssignments, dayFields, user.id);
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
    },
  );
}



// Method to show edit dialog
void _showEditDialogs(BuildContext context, List<String> dayAssignments, List<String> dayFields, String userId) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        titlePadding: EdgeInsets.zero, // Remove default title padding
        contentPadding: EdgeInsets.zero, // Remove default content padding
        shape: RoundedRectangleBorder( // Add shape for the dialog
          borderRadius: BorderRadius.circular(12), // Curve the dialog corners
        ),
        title: ClipRRect(
          borderRadius: const BorderRadius.only( // Curve only the top corners
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Container(
            color: const Color.fromARGB(255, 37, 207, 43),
            padding: const EdgeInsets.all(16.0),
            child: const Center( // Center the text horizontally and vertically
              child: Text(
                'Delete Schedule',
                style: TextStyle(color: Colors.white), // Change text color to white
              ),
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: dayAssignments.asMap().entries.map((entry) {
              int idx = entry.key;
              String day = entry.value;
              return ListTile(
                title: Text(
                  day,
                  style: const TextStyle(color: Colors.black), // Maintain black text for days
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Color.fromARGB(255, 137, 136, 136)),
                  onPressed: () {
                    // Confirm deletion
                    _confirmDeletion(context, dayFields[idx], userId, day);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color.fromARGB(255, 59, 187, 36)), // Change cancel text color to white
            ),
          ),
        ],
      );
    },
  );
}


// Method to confirm deletion
void _confirmDeletion(BuildContext context, String fieldName, String userId, String day) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete $day?'),
        actions: [ 
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.green), // Change cancel text color to white
            ),
          ),
          TextButton(
            onPressed: () {
              // Perform deletion from Firestore
              approvedCollectorsRef.doc(userId).update({fieldName: FieldValue.delete()});
              Navigator.of(context).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close edit dialog
            },
            child: const Text('Delete',
            style: TextStyle(color: Colors.green),),
          ),   
        ],
      );
    },
  );
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void _showSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 36, 204, 42),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: const Center(
                child: Text(
                  'ASSIGNED SUCCESSFULLY!',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.green),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}



Widget _buildDialogUserList(StateSetter dialogSetState) {
  final currentUser = FirebaseAuth.instance.currentUser; // Get the logged-in user

  if (currentUser == null) {
    return const Center(child: Text('No collector logged in.'));
  }

  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('ambulant_collector')
        .where('email', isEqualTo: currentUser.email) // Query by logged-in collector's email
        .limit(1) // Only one collector should match the email
        .get(),
    builder: (context, collectorSnapshot) {
      if (collectorSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (collectorSnapshot.hasError) {
        return Center(child: Text('Error: ${collectorSnapshot.error}'));
      }

      if (!collectorSnapshot.hasData || collectorSnapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Collector data not found.'));
      }

      // Get the collector's assigned collection value (e.g., '01', '02', etc.)
      final collectorDoc = collectorSnapshot.data!.docs.first;
      final collectorData = collectorDoc.data() as Map<String, dynamic>;
      final String assignedCollection = collectorData['collector'] ?? ''; // Ensure 'collector' field exists

      if (assignedCollection.isEmpty) {
        return const Center(child: Text('Collector has no assigned collection.'));
      }

      // Now query the approved_vendors collection based on the collector's assigned collection
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('approved_vendors')
            .where('status', isEqualTo: 'Approved')
            .where('collector', isEqualTo: assignedCollection) // Filter by the collector's assigned collection
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vendors available.'));
          }

          final approvedUsers = snapshot.data!.docs;

          // Filter out vendors who are already assigned to the selected schedule (_selectedSchedule)
          final filteredUsers = approvedUsers.where((user) {
            final matchesQuery = user['last_name'].toString().toLowerCase().contains(_dialogSearchQuery) ||
                getNumberFromDocumentId(user.id).contains(_dialogSearchQuery);

            // Check if the vendor is already assigned to the selected day
            final userAssignments = user.data() as Map<String, dynamic>;
            final bool isAssignedToSelectedDay = userAssignments.values.contains(_selectedSchedule);

            return matchesQuery && !isAssignedToSelectedDay; // Only include vendors not assigned to the selected day
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(child: Text('No matching results'));
          }

          // Initialize the selected vendors list with the size of the filtered list
          if (_selectedVendors.length != filteredUsers.length) {
            _selectedVendors = List.filled(filteredUsers.length, false);
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final first = user['first_name'];
              final last = user['last_name'];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      // Checkbox for selecting the vendor
                      Checkbox(
                        value: _selectedVendors[index],
                        activeColor: Colors.green,
                        onChanged: (bool? value) {
                          dialogSetState(() {
                            _selectedVendors[index] = value ?? false;
                          });
                        },
                      ),
                      // Profile Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$last, ${first[0]}.",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 21, 21, 21),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Approved',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                     // Inside the ListView.builder
// Save Button
Container(
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 218, 250, 220),
    borderRadius: BorderRadius.circular(5),
  ),
  child: TextButton(
    onPressed: () async {
      if (_selectedSchedule == null) {
        // Show an error dialog if no schedule is selected
        _showErrorDialog(context, 'Please select a schedule before saving.');
        return;
      }

      // Get the current vendor's ID
      final vendorId = user.id; // Use the current vendor's ID from the user object

      // Fetch existing assignments
      DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
          .collection('approved_vendors')
          .doc(vendorId)
          .get();

      // Determine the next available assignment key
      int assignmentCount = 0;
      if (vendorDoc.exists) {
        Map<String, dynamic>? data = vendorDoc.data() as Map<String, dynamic>?;

        data?.forEach((key, value) {
          if (key.startsWith('day_assign_')) {
            int count = int.tryParse(key.split('_').last) ?? 0;
            if (count > assignmentCount) {
              assignmentCount = count;
            }
          }
        });
      }

      // Increment for the new assignment
      assignmentCount += 1;
      String newAssignmentKey = 'day_assign_$assignmentCount';

      // Update Firestore with the new assignment
      await FirebaseFirestore.instance
          .collection('approved_vendors')
          .doc(vendorId)
          .set({newAssignmentKey: _selectedSchedule}, SetOptions(merge: true));

      // Show success dialog
      _showSuccessDialog(context, 'Schedule Assigned Successfully!');
    },
    child: const Text('Save', style: TextStyle(color: Color.fromARGB(255, 72, 151, 39))),
  ),
),

                      // Save Button
/*                       Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 218, 250, 220),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            if (_selectedSchedule == null) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Error'),
                                    content: const Text('Please select a schedule before saving.'),
                                    actions: [
                                      TextButton(
                                        child: const Text('OK'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                              return; // Exit early if no schedule is selected
                            }
  
                            List<String> vendorIds = [];

                            for (int i = 0; i < filteredUsers.length; i++) {
                              if (_selectedVendors[i]) {
                                vendorIds.add(filteredUsers[i].id);
                              }
                            }

                            if (vendorIds.isNotEmpty) {
                              for (String vendorId in vendorIds) {
                                DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
                                    .collection('approved_vendors')
                                    .doc(vendorId)
                                    .get();

                                if (vendorDoc.exists) {
                                  Map<String, dynamic>? data = vendorDoc.data() as Map<String, dynamic>?;

                                  int assignmentCount = 0;
                                  data?.forEach((key, value) {
                                    if (key.startsWith('day_assign_')) {
                                      int count = int.tryParse(key.split('_').last) ?? 0;
                                      if (count > assignmentCount) {
                                        assignmentCount = count;
                                      }
                                    }
                                  });

                                  assignmentCount += 1;
                                  String newAssignmentKey = 'day_assign_$assignmentCount';

                                  await FirebaseFirestore.instance
                                      .collection('approved_vendors')
                                      .doc(vendorId)
                                      .set({
                                    newAssignmentKey: _selectedSchedule,
                                  }, SetOptions(merge: true));

                                  // Show success dialog
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        contentPadding: const EdgeInsets.all(0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              height: 60,
                                              decoration: const BoxDecoration(
                                                color: Color.fromARGB(255, 36, 204, 42),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(15),
                                                  topRight: Radius.circular(15),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'ASSIGNED SUCCESSFULLY!',
                                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(20),
                                              child: const Center(
                                                child: Text(
                                                  'Schedule Assigned Successfully!',
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text(
                                              'OK',
                                              style: TextStyle(color: Colors.green),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            }
                          },
                          child: const Text('Save', style: TextStyle(color: Color.fromARGB(255, 72, 151, 39))),
                        ),
                      ), */
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

String getNumberFromDocumentId(String docId) {
  return docId.padLeft(2, '0'); // Ensures the number is at least 2 digits long
}
}