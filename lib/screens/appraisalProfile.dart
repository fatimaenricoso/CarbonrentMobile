import 'dart:io';

import 'package:ambulantcollector/screens/AppraisalSettings.dart';
import 'package:ambulantcollector/screens/appraisalGallry.dart';
import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AppraisalProfile extends StatefulWidget {
  const AppraisalProfile({Key? key}) : super(key: key);

  @override
  _AppraisalProfileState createState() => _AppraisalProfileState();
}

class _AppraisalProfileState extends State<AppraisalProfile> {
  String _email = '';
  String _firstName = '';
  String _lastName = '';
  String _address = '';
  String _contactNumber = '';
  String _assignaddress = '';
  String _appraisalZone = '';
  String _location = '';
  List<Map<String, dynamic>> _profileImages = []; // List of profile image URLs with timestamps
  File? _selectedImage; // Selected image file

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email ?? '';
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('appraisal_user')
          .where('email', isEqualTo: _email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _firstName = userData['firstname'] ?? '';
          _lastName = userData['lastname'] ?? '';
          _address = userData['Address'] ?? '';
          _assignaddress = userData['Address_appraisal'] ?? '';
          _contactNumber = userData['contact_number'] ?? '';
          _appraisalZone = userData['appraisal'] ?? '';
          _location = userData['appraisal_assign'] ?? '';
          _profileImages = List<Map<String, dynamic>>.from(userData['profileImages'] ?? []); // Fetch profile image URLs with timestamps
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found.')),
        );
      }
    }
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
        String appraisalValue = _appraisalZone; // Get the appraisal value
        String fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.png'; // Unique file name
        String storagePath = 'appraisal_user/$appraisalValue/$fileName'; // Path in Firebase Storage

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
                .collection('appraisal_user')
                .where('email', isEqualTo: _email)
                .get();

            if (userQuery.docs.isNotEmpty) {
              var userDoc = userQuery.docs.first; // Get the first document
              String documentId = userDoc.id;

              // Add the new URL and timestamp to the array of profile images
              List<Map<String, dynamic>> updatedProfileImages = List<Map<String, dynamic>>.from(_profileImages)
                ..add({'url': downloadUrl, 'timestamp': DateTime.now().toIso8601String()});

              await FirebaseFirestore.instance
                  .collection('appraisal_user')
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
                height: 60, // Increased height
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
            // Icon(Icons.person, color: Colors.white),
            SizedBox(width: 8),
            Text("Appraiser Profile", style: TextStyle(color: Colors.white, fontSize: 16)),
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
                    MaterialPageRoute(builder: (context) => const AppraisalSettings()),
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
                  // Navigate to the profile gallery screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AppraisalGallery()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(16.0),
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
                          backgroundColor: Colors.grey[300],
                          child: _profileImages.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _profileImages.last['url'],
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_firstName $_lastName',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Appraiser #: $_appraisalZone',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 226, 220, 220),
                          ),
                        ),
                        Text(
                          'Assigned to: $_location',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 226, 220, 220),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoColumn(Icons.email, 'Email', _email),
            _buildInfoColumn(Icons.phone, 'Contact Number', _contactNumber),
            _buildInfoColumn(Icons.location_on, 'Assigned Location', _assignaddress),
            _buildInfoColumn(Icons.home, 'Home Address', _address),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: const Color.fromARGB(255, 152, 151, 151)),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
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
          const Divider(thickness: 1),
        ],
      ),
    );
  }
}
