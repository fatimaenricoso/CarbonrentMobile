import 'dart:io';

import 'package:ambulantcollector/screens/AppraisalSettings.dart';
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
  List<String> _profileImageUrls = [];

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
          _assignaddress = userData['Address_appraisal'];
          _contactNumber = userData['contact_number'].toString();
          _appraisalZone = userData['appraisal'] ?? '';
          _location = userData['appraisal_assign'] ?? '';
          _profileImageUrls = List<String>.from(userData['profileImages'] ?? []);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found.')),
        );
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('appraisal_user')
            .where('email', isEqualTo: _email)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final userData = snapshot.docs.first.data() as Map<String, dynamic>;
          final appraisalAssign = userData['appraisal_assign'] ?? '';
          final storagePath = 'appraiser/$appraisalAssign/profile_image_${DateTime.now().millisecondsSinceEpoch}.png';

          try {
            final file = File(image.path);
            if (await file.exists()) {
              final ref = FirebaseStorage.instance.ref(storagePath);
              final uploadTask = await ref.putFile(file);
              final downloadUrl = await uploadTask.ref.getDownloadURL();

              // Add the new image URL to the list
              _profileImageUrls.add(downloadUrl);

              // Update Firestore document with the new list of image URLs
              await FirebaseFirestore.instance
                  .collection('appraisal_user')
                  .doc(user.uid)
                  .set({'profileImages': _profileImageUrls}, SetOptions(merge: true));

              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile image uploaded successfully.')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /* leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back icon with white color
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const Dashboard()), // Navigate to Dashboard
            );
          },
        ), */
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /* Icon(Icons.person, color: Colors.white), */
            SizedBox(width: 8),
            Text("Profile", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white), // Settings icon with white color
            onPressed: () {
              // Navigate to the existing SettingScreen when the settings icon is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Appraisalsettings()),
              );
            },
          ),
        ],
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
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: _profileImageUrls.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  _profileImageUrls.last,
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
                          onTap: _uploadProfileImage,
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
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Appraiser #: $_appraisalZone',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color.fromARGB(255, 226, 220, 220),
                          ),
                        ),
                        Text(
                          'Assigned to: $_location',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color.fromARGB(255, 226, 220, 220),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoColumn(Icons.email, 'Email', _email),
            // const Divider(thickness: 1),
            _buildInfoColumn(Icons.phone, 'Contact Number', _contactNumber),
            // const Divider(thickness: 1),
            _buildInfoColumn(Icons.location_on_outlined, 'Assigned Location', _assignaddress),
            // const Divider(thickness: 1),
            _buildInfoColumn(Icons.home, 'Home Address', _address),
            // const Divider(thickness: 1),
            const SizedBox(height: 15), // Added spacing before the logout button
            Center(
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 130, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                // fontWeight: FontWeight.bold,
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
