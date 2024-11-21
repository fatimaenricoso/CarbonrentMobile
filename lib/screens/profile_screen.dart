import 'dart:io';

import 'package:ambulantcollector/screens/dashboardvendor.dart';
import 'package:ambulantcollector/screens/settings_screen.dart'; // Correct path to SettingScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _email = '';
  String _firstName = '';
  String _lastName = '';
  String _middleName = '';
  String _contactNum = '';
  String _address = '';
  String _location = '';
  String _collector = '';
  String _status = '';
  String _profileImageUrl = ''; // URL for profile image

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
          .collection('ambulant_collector')
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
          _collector = userData?['collector'] ?? ''; 
          _status = userData?['status'] ?? ''; 
          _profileImageUrl = userData?['profileImage'] ?? ''; // Fetch profile image URL
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

Future<void> _uploadProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      User? user = FirebaseAuth.instance.currentUser; 
      if (user != null) {
        String documentId = user.uid;
        String storagePath = 'ambulant_collector/$documentId/profile_image.png'; // Path in Firebase Storage

        try {
          File file = File(image.path);
          
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
            
            // Update Firestore with the download URL under the current user's document
            await FirebaseFirestore.instance
                .collection('ambulant_collector')
                .doc(documentId)
                .set({'profileImage': downloadUrl}, SetOptions(merge: true)); // Use merge to avoid overwriting other fields

            setState(() {
              _profileImageUrl = downloadUrl;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile image uploaded successfully.')),
            );
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
      print("No image selected."); // Debug: No image selected
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back icon with white color
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) =>const  DashboardVendor()), // Navigate to Dashboard
            );
          },
        ),
        title: const Text(""), // Empty title to avoid spacing issues
        centerTitle: true, // Center the title content
        backgroundColor: Colors.green, // Set background color to green
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white), // Settings icon with white color
            onPressed: () {
              // Navigate to the existing SettingScreen when the settings icon is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        flexibleSpace: const Center( // Center the content
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the text and icon
            mainAxisSize: MainAxisSize.min, // Minimize the space taken by the Row
            children: [
              Icon(Icons.person, color: Colors.white), // Icon next to the text
              SizedBox(width: 8), // Space between icon and text
              Text(
                "Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20, // Set text color to white
                ),
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
                color: const Color.fromARGB(255, 42, 195, 47), // Green background
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              padding: const EdgeInsets.all(16.0), // Padding around the container
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300], // Set a background color
                        child: _profileImageUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  _profileImageUrl,
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
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploadProfileImage, // The function to pick/upload profile image
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Change text color to white for contrast
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Collector: $_collector',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white, // Change text color to white for contrast
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
            _buildInfoColumn(Icons.info, 'Status', _status),
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
                fontWeight: FontWeight.bold,
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
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 2), // Add a divider for separation
        ],
      ),
    );
  }
}
