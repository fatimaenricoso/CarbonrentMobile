import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'approve_vendor.dart'; // Make sure to replace with actual path
import 'profile_screen.dart'; // Make sure to replace with actual path
import 'settings_screen.dart'; // Make sure to replace with actual path
import 'vendor.dart'; // Make sure to replace with actual path

class StatusScreen extends StatefulWidget {
  final String vendorId;

  const StatusScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

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
                Icon(Icons.approval_sharp, color: Colors.white), // Icon next to the text
                SizedBox(width: 8), // Space between icon and text
                Text(
                  "Application Detail",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Set text color to white
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 31, 232, 37), // Set background color to green
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
                          builder: (context) => const ProfileScreen(),
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
                          builder: (context) => SettingsScreen(),
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
      body: FutureBuilder<DocumentSnapshot>(
        future: usersRef.doc(widget.vendorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error fetching document: ${snapshot.error}');
            return const Center(child: Text('Error fetching document'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            print('Document not found with ID: ${widget.vendorId}');
            return const Center(child: Text("Application not found"));
          }

          final application = snapshot.data!;
          final applicationData = application.data() as Map<String, dynamic>;
          final contactNumber = applicationData['contact_number'] ?? 'N/A';
          final createdAt = applicationData['created_at']?.toDate().toString() ?? 'N/A';
          final email = applicationData['email'] ?? 'N/A';
          final firstName = applicationData['first_name'] ?? 'N/A';
          final lastName = applicationData['last_name'] ?? 'N/A';
          final status = applicationData['status'] ?? 'N/A';
          final username = applicationData['username'] ?? 'N/A';
          final documents = applicationData.containsKey('documents') ? applicationData['documents'] as List<dynamic> : [];
/*           final adminMessage = applicationData['admin_message'] ?? '';
 */       final timeline = applicationData.containsKey('timeline') ? applicationData['timeline'] as List<dynamic> : [];

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header card
                Card(
                  color: Colors.green,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Icon(Icons.person, color: Colors.grey[800]),
                          ),
                          title: Text(
                            "$lastName, $firstName",
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          subtitle: Text(
                            username,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        Text(
                          "Status: $status",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Approve and Decline buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: (status == 'Pending' || status == 'Request Info')
                          ? () => _showApproveDialog(context, widget.vendorId)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (status == 'Pending' || status == 'Request Info')
                            ? Colors.green
                            :Colors.grey, //grey for disable button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('APPROVE', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),

                    //Decline Button
                    ElevatedButton(
                      onPressed: (status == 'Pending' || status == 'Request Info')
                          ? () => _showDeclineDialog(context, widget.vendorId)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (status == 'Pending' || status == 'Request Info')
                            ? Colors.green
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('DECLINE', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),

                const Divider(thickness: 1.5, height: 40),

                // Personal Information
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.grey[700]),
                  title: const Text("Lastname", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(lastName, style: const TextStyle(fontSize: 16)),
                ),
                ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.grey[700]),
                  title: const Text("Firstname", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(firstName, style: const TextStyle(fontSize: 16)),
                ),
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.grey[700]),
                  title: const Text("Contact Number", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(contactNumber, style: const TextStyle(fontSize: 16)),
                ),
                ListTile(
                  leading: Icon(Icons.email_outlined, color: Colors.grey[700]),
                  title: const Text("Email", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(email, style: const TextStyle(fontSize: 16)),
                ),
                ListTile(
                  leading: Icon(Icons.calendar_today_outlined, color: Colors.grey[700]),
                  title: const Text("Created At", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(createdAt, style: const TextStyle(fontSize: 16)),
                ),

                const Divider(thickness: 1.5, height: 40),

              Column(
              children: [
                if (timeline.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text(
                      "Timeline",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  ...timeline.asMap().entries.map((entry) {
                    final index = entry.key + 1; // Start from 1
                    final timelineEntry = entry.value as Map<String, dynamic>;
                    final requestMessage = timelineEntry['message'] ?? 'N/A';
                    final requestDate = timelineEntry['timestamp']?.toDate().toString() ?? 'N/A';
                    final uploadedFiles = timelineEntry['uploadedFiles'] as List<dynamic>? ?? [];
                    final isFilesCompleted = uploadedFiles.isNotEmpty; // Check if files are uploaded

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline line and icons
                        Column(
                          children: [
                            // First icon (always check)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            // Vertical line connecting the icons
                            Container(
                              width: 2, // Line width
                              height: 40, // Adjust height for spacing
                              decoration: BoxDecoration(
                                color: Colors.grey, // Line color
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            // Second icon (clock or check based on file upload status)
                            Icon(
                              isFilesCompleted ? Icons.check_circle : Icons.access_time,
                              color: isFilesCompleted ? Colors.green : Colors.grey,
                            ),
                            if (entry.key != timeline.length - 1) // Add line if not the last entry
                              Container(
                                width: 2, // Line width
                                height: 40, // Adjust height for spacing between requests
                                color: Colors.grey, // Line color
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        
                        // Timeline content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Request and Date
                              ListTile(
                                title: Text(
                                  'Request $index',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Request Message: $requestMessage', style: const TextStyle(fontSize: 14)),
                                    Text('Date Requested: $requestDate', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              if (uploadedFiles.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(left: 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: uploadedFiles.map((file) {
                                      final fileUrl = file.toString();
                                      final isImage = fileUrl.endsWith('.jpg') || fileUrl.endsWith('.png');
                                      return isImage
                                        ? Image.network(
                                            fileUrl,
                                            height: 100, // Adjust height as needed
                                            width: 100, // Adjust width as needed
                                            fit: BoxFit.cover, // Ensure image fits within the box
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Text("Error loading image");
                                            },
                                          )
                                        : Text(
                                            fileUrl, // Display the file URL for non-image files
                                            style: const TextStyle(fontSize: 14),
                                          );
                                  }).toList(),
                                ),
                              ),
                            ],
                                      const Divider(thickness: 1.5, height: 40),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ] else ...[
                          // If no timeline entries, show nothing
                        ],
          
                        // Documents Section
                        documents.isNotEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Documents",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    ...documents.map((document) {
                                      return ListTile(
                                        title: Text(document['filename']),
                                        subtitle: document['url'] != null
                                            ? Text(document['url'])
                                            : null,
                                      );
                                    }),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),

                            //Request Info Button
                          Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: ElevatedButton(
                            onPressed: status == 'Pending' || status == 'Request Info'
                                ? () => showRequestAdditionalInfoDialog(context, widget.vendorId) 
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (status == 'Pending' || status == 'Request Info')
                                  ? Colors.green
                                  : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Request Info', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      ],
                    ),
                  );
                  },
                ),
              );
            }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
              setState(() {});
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
                        setState(() {});
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

Future<String?> _uploadFileToFirebaseStorage(Uint8List fileBytes, String fileName) async {
  try {
    // Create a reference to the Firebase Storage folder "request_sample"
    final storageRef = FirebaseStorage.instance.ref().child('request_sample/$fileName');
    
    // Upload the file
    final uploadTask = storageRef.putData(fileBytes);
    
    // Wait for the upload to complete
    final snapshot = await uploadTask.whenComplete(() {});
    
    // Get the download URL
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
  } catch (e) {
    print('Error uploading file: $e');
    return null; // Return null if the upload fails
  }
}


Future<void> _updateVendorTimeline(
  String vendorId, 
  String message, 
  Uint8List? fileBytes, 
  String? fileName,
  String requestedBy, // Add this parameter
  DateTime dateRequested, // Add this parameter
) async {
  try {
    String? downloadUrl;

    if (fileBytes != null && fileName != null) {
      // Define the path in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('request_sample')
          .child(vendorId)
          .child(fileName);

      // Upload the file to Firebase Storage
      final uploadTask = storageRef.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded file
      downloadUrl = await snapshot.ref.getDownloadURL();
    }

    // Fetch the current document to get the timeline field
    DocumentSnapshot vendorDoc = await FirebaseFirestore.instance.collection('users').doc(vendorId).get();
    Map<String, dynamic>? data = vendorDoc.data() as Map<String, dynamic>?;

    // Initialize timeline if it does not exist
    List<dynamic>? timeline = data?['timeline'] as List<dynamic>?;
    timeline ??= [];

    // Determine the next 'issubmitted' index
    int nextIssubmittedIndex = 1;

    for (var entry in timeline) {
      if (entry is Map<String, dynamic>) {
        // Increment the index if the current key exists
        if (entry.containsKey('issubmitted$nextIssubmittedIndex')) {
          nextIssubmittedIndex++;
        }
      }
    }

    // Prepare the timeline entry with the next 'issubmitted' index
    Map<String, dynamic> timelineEntry = {
      'issubmitted$nextIssubmittedIndex': false,
      'message': message,
      'status': 'Request Info',
      'timestamp': Timestamp.now(),
      'requested_by': requestedBy, // Include the requester
      'date_requested': dateRequested.toIso8601String(), // Include the date
    };

    if (downloadUrl != null) {
      timelineEntry['sample_image'] = downloadUrl; // Add the file URL to the timeline entry
    }

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(vendorId).update({
      'timeline': FieldValue.arrayUnion([timelineEntry]),
      'status': 'Request Info',
    });

    print('Vendor timeline updated successfully');
  } catch (e) {
    print('Error updating vendor timeline: $e');
  }
}



void showRequestAdditionalInfoDialog(BuildContext context, String vendorId) {
  final TextEditingController reasonController = TextEditingController();
  String selectedReason = '';
  List<String> suggestedReasons = [
    'Upload your valid ID',
    'Upload ID for verification',

  ];
  Uint8List? selectedFileBytes;
  String? fileName;
  String? fileExtension;

  // Method to set the reason
  void setReason(String reason) {
    reasonController.text = reason;
    selectedReason = reason;
  }

  // Method to clear the reason
  void clearReason() {
    reasonController.clear();
    selectedReason = '';
  }

  // Method to remove a suggested reason
  void removeSuggestedReason(String reason) {
    setState(() {
      suggestedReasons.remove(reason);
      if (selectedReason == reason) {
        clearReason();
      }
    });
  }

  // Method to remove the selected file
  void removeSelectedFile() {
    setState(() {
      fileName = null;
      fileExtension = null;
      selectedFileBytes = null;
    });
  }

  // Method to pick a file
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Allow any type of file
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        fileName = result.files.single.name;
        fileExtension = result.files.single.extension;
        selectedFileBytes = result.files.single.bytes;
      });
    }
  }

  // Method to handle request for additional info
void handleRequestInfo() async {
  if (selectedReason.isNotEmpty || fileName != null) {
    print('Request Info button clicked');

    // Get the current user's ID (assuming you have a way to get the logged-in user's ID)
    String requestedBy = FirebaseAuth.instance.currentUser?.uid ?? 'Unknown'; // Example way to get user ID
    DateTime dateRequested = DateTime.now(); // Current date
    
    // Call Firestore update function
    await _updateVendorTimeline(
      vendorId,             // Pass the vendor ID
      selectedReason,      // Pass the reason for requesting additional info
      selectedFileBytes,   // Pass the selected file bytes
      fileName,            // Pass the selected file name
      requestedBy, // Pass the requester
      dateRequested, // Pass the date requested
    );
    setState(() {});
    Navigator.of(context).pop();
  }
}

  showDialog(
    context: context,
    builder: (BuildContext context) {
       String requestedBy = FirebaseAuth.instance.currentUser?.email ?? 'Unknown'; // Example way to get user ID
       DateTime dateRequested = DateTime.now(); // Current date

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            titlePadding: const EdgeInsets.all(0),
            title: Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(15.0),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: const Text(
                'Request Additional Info',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: suggestedReasons.map((reason) {
                      return _buildReasonButton(
                        reason,
                        (reason) {
                          setState(() {
                            setReason(reason);
                          });
                        },
                        () {
                          setState(() {
                            removeSuggestedReason(reason);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter a reason for requesting additional info',
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
                    maxLines: null,
                    maxLength: 150,
                  ),
                  const SizedBox(height: 10),
                  // Select file link
                  GestureDetector(
                    onTap: () async {
                      await pickFile();
                      setState(() {});
                    },
                    child: const Text(
                      'Select a sample file',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // File preview
                  const SizedBox(height: 10),
                  if (fileName != null) ...[
                    Stack(
                      children: [
                        fileExtension == 'jpg' || fileExtension == 'png' || fileExtension == 'jpeg'
                            ? selectedFileBytes != null
                                ? Image.memory(
                                    selectedFileBytes!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : const Text('Preview not available', style: TextStyle(fontSize: 14))
                            : Text('Preview not available for $fileExtension files', style: const TextStyle(fontSize: 14)),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              removeSelectedFile();
                              setState(() {}); // Refresh the UI
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without doing anything
              },
              child: const Text('Cancel'),
            ),
              TextButton(
                onPressed: selectedReason.isNotEmpty || fileName != null
                    ? () {
                        Navigator.of(context).pop();
                        _updateVendorTimeline(
                          vendorId,
                          selectedReason,
                          selectedFileBytes,
                          fileName,
                          requestedBy, // Pass the requester
                          dateRequested,
                        );
                      }
                    : null,
                child: const Text('Request Info'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildReasonButtonRequest(String reason, void Function(String) onTap, void Function() onClear) {
  return Container(
    margin: const EdgeInsets.only(bottom: 5),
    child: SizedBox(
      width: 200,
      height: 30,
      child: ElevatedButton(
        onPressed: () => onTap(reason),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(0),
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
              onPressed: onClear,
            ),
          ],
        ),
      ),
    ),
  );
}

  // Method for handling decline
  void _showRequestAdditionalInfoDialog(String vendorId, String reason) {
  // Logic for declining a vendor
  usersRef.doc(vendorId).update({
    'status': 'Declined',
    'decline_reason': reason,
  });
}

  ListTile _createDrawerItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[800]),
      title: Text(text, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}
