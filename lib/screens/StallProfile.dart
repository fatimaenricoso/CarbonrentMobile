import 'dart:io';

import 'package:ambulantcollector/screens/StallChangePass.dart';
import 'package:ambulantcollector/screens/collectorGallery.dart';
import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StallProfile extends StatefulWidget {
  const StallProfile({Key? key}) : super(key: key);

  @override
  _StallProfileState createState() => _StallProfileState();
}

class _StallProfileState extends State<StallProfile> {
  String _email = '';
  String _firstName = '';
  String _lastName = '';
  String _middleName = '';
  String _contactNum = '';
  String _address = '';
  String _location = '';
  String _position = '';
  String _status = '';
  String _createdAt = '';
  List<Map<String, dynamic>> _profileImages = []; // List of profile image URLs with timestamps
  File? _selectedImage; // Selected image file

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      setState(() {
        _email = user.email ?? ''; // Retrieve email
      });

      // Fetch user details from Firestore
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('admin_users')
          .where('email', isEqualTo: _email)
          .get();

      // Check if we have any documents
      if (userQuery.docs.isNotEmpty) {
        var userDoc = userQuery.docs.first; // Get the first document

        setState(() {
          // Retrieve user details safely with null checks
          var userData = userDoc.data() as Map<String, dynamic>?; // Cast data to Map

          _firstName = userData?['firstName'] ?? ''; // Safe access with default value
          _lastName = userData?['lastName'] ?? '';
          _middleName = userData?['middleName'] ?? '';
          _contactNum = userData?['contactNum'] ?? '';
          _address = userData?['address'] ?? '';
          _location = userData?['location'] ?? '';
          _position = userData?['position'] ?? '';
          _status = userData?['status'] ?? '';
          _createdAt = userData?['createdAt'] != null
              ? (userData?['createdAt'] as Timestamp).toDate().toString()
              : '';
          _profileImages = List<Map<String, dynamic>>.from(userData?['profileImages'] ?? []); // Fetch profile image URLs with timestamps
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is logged in.')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
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
                child: const Center(
                  child: Text(
                    'Confirm Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Are you sure you want to logout?'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('No', style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Yes', style: TextStyle(color: Colors.green)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logout();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      _showImagePreviewDialog();
    } else {
      print("No image selected."); // Debug: No image selected
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.png'; // Unique file name
        String storagePath = 'admin_users/$fileName'; // Path in Firebase Storage

        try {
          File file = _selectedImage!;

          // Check if the file exists
          if (await file.exists()) {
            print("File exists at: ${file.path}"); // Debug: File exists

            // Create a reference to the storage location
            Reference ref = FirebaseStorage.instance.ref(storagePath);

            // Upload the file to Firebase Storage
            TaskSnapshot uploadTask = await ref.putFile(file);

            // Get the download URL
            String downloadUrl = await uploadTask.ref.getDownloadURL();
            print("Download URL: $downloadUrl"); // Debug: Print the download URL

            // Update Firestore with the download URL and timestamp under the current user's document
            QuerySnapshot userQuery = await FirebaseFirestore.instance
                .collection('admin_users')
                .where('email', isEqualTo: _email)
                .get();

            if (userQuery.docs.isNotEmpty) {
              var userDoc = userQuery.docs.first; // Get the first document
              String documentId = userDoc.id;

              // Add the new URL and timestamp to the array of profile images
              List<Map<String, dynamic>> updatedProfileImages = List<Map<String, dynamic>>.from(_profileImages)
                ..add({'url': downloadUrl, 'timestamp': DateTime.now().toIso8601String()});

              await FirebaseFirestore.instance
                  .collection('admin_users')
                  .doc(documentId)
                  .set({'profileImages': updatedProfileImages}, SetOptions(merge: true)); // Use merge to avoid overwriting other fields

              setState(() {
                _profileImages = updatedProfileImages;
                _selectedImage = null; // Clear the selected image after upload
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile image uploaded successfully.')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User document not found.')),
              );
            }
          } else {
            print("File does not exist."); // Debug: File does not exist
          }
        } catch (e) {
          print("Error uploading image: $e"); // Debug: Print any errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
        }
      } else {
        print("No user is logged in."); // Debug: No user logged in
      }
    } else {
      print("No image selected for upload."); // Debug: No image selected for upload
    }
  }

  void _showImagePreviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(_selectedImage!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _uploadProfileImage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Upload Image',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangeProfileDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
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
                height: 60, // Decreased height
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                ),
                child: const Center(
                  child: Text(
                    'Change Profile Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Do you want to change your profile picture?'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('No', style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Yes', style: TextStyle(color: Colors.green)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickImage();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white), // Menu icon with white color
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 5),
            Text("Stall Profile", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), // Logout icon with white color
            onPressed: _confirmLogout,
          ),
        ],
      ),
      drawer: Container(
        width: 250, // Set the desired width for the drawer
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 100.0, // Set the desired height
                child: const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)), // Add border radius to the top
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.0), // Minimize the vertical padding
                    child: Align(
                      alignment: Alignment.center, // Center the text
                      child: Text(
                        'CarbonRent',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 14), // Set the desired font size
                ),
                onTap: () {
                  // Navigate to the change password screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StallCollectorPasswordChange()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text(
                  'View Uploaded Photos',
                  style: TextStyle(fontSize: 14), // Set the desired font size
                ),
                onTap: () {
                  // Navigate to the change password screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileGalleryScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView( // Wrap the body with SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green, // Green background
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              padding: const EdgeInsets.all(16.0), // Padding around the container
              child: Row(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_profileImages.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: Image.network(_profileImages.last['url']),
                                );
                              },
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300], // Set a background color
                          child: _profileImages.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _profileImages.last['url'], // Display the latest uploaded image
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showChangeProfileDialog,
                          child: const CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.black,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded( // Allow full name to expand
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ensure full name is displayed correctly
                        Text(
                          '$_firstName $_middleName $_lastName',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white, // Change text color to white for contrast
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Position: $_position',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 226, 220, 220), // Change text color to white for contrast
                          ),
                        ),
                        Text(
                          'Status: $_status',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 226, 220, 220), // Change text color to white for contrast
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Personal information displayed in vertical format
            _buildInfoColumn(Icons.email, 'Email', _email),
            _buildInfoColumn(Icons.phone, 'Contact Number', _contactNum),
            _buildInfoColumn(Icons.home, 'Address', _address),
            _buildInfoColumn(Icons.location_on, 'Location', _location),
            _buildInfoColumn(Icons.calendar_today, 'Created At', _createdAt),
            const SizedBox(height: 15), // Added spacing before the logout button
          ],
        ),
      ),
    );
  }

  // Helper method to build label-value rows with underline
  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Space between rows
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10), // Space before label
          Padding(
            padding: const EdgeInsets.only(left: 40.0), // Increased left padding for the label
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 4), // Space between label and value
          Row(
            children: [
              Icon(icon, color: const Color.fromARGB(255, 152, 151, 151)), // Add icon for each label
              const SizedBox(width: 8), // Space between icon and value
              Expanded( // Allow value to occupy remaining space
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0), // Space to align with underline
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1), // Add a divider for separation
        ],
      ),
    );
  }
}
