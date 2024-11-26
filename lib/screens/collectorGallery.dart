import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProfileGalleryScreen extends StatefulWidget {
  const ProfileGalleryScreen({Key? key}) : super(key: key);

  @override
  _ProfileGalleryScreenState createState() => _ProfileGalleryScreenState();
}

class _ProfileGalleryScreenState extends State<ProfileGalleryScreen> {
  List<Map<String, dynamic>> _profileImages = [];

  @override
  void initState() {
    super.initState();
    _getProfileImages();
  }

  Future<void> _getProfileImages() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email!;

      // Fetch user details from Firestore
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('ambulant_collector')
          .where('email', isEqualTo: email)
          .get();

      // Check if we have any documents
      if (userQuery.docs.isNotEmpty) {
        var userDoc = userQuery.docs.first; // Get the first document
        var userData = userDoc.data() as Map<String, dynamic>?; // Cast data to Map

        setState(() {
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

  Future<void> _deleteImage(int index) async {
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
                height: 50, // Decreased height
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                ),
                child: const Center(
                  child: Text(
                    'Delete Image',
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
                child: Text('Are you sure you want to delete this image?'),
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
                      _confirmDeleteImage(index);
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

  Future<void> _confirmDeleteImage(int index) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email!;

      // Fetch user details from Firestore
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('ambulant_collector')
          .where('email', isEqualTo: email)
          .get();

      // Check if we have any documents
      if (userQuery.docs.isNotEmpty) {
        var userDoc = userQuery.docs.first; // Get the first document
        String documentId = userDoc.id;

        // Remove the image from the profileImages array
        List<Map<String, dynamic>> updatedProfileImages = List<Map<String, dynamic>>.from(_profileImages)
          ..removeAt(index);

        // Update Firestore with the updated profileImages array
        await FirebaseFirestore.instance
            .collection('ambulant_collector')
            .doc(documentId)
            .set({'profileImages': updatedProfileImages}, SetOptions(merge: true)); // Use merge to avoid overwriting other fields

        setState(() {
          _profileImages = updatedProfileImages;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully.')),
        );
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

  void _showImagePreview(String imageUrl, String formattedDate, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: AspectRatio(
                        aspectRatio: 1, // Maintain a square aspect ratio
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$formattedDate',
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                onPressed: () => _deleteImage(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Reduced curve
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Profile Pictures",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: _profileImages.isEmpty
          ? const Center(child: Text('No images found.'))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                  childAspectRatio: 1.0, // Maintain a square aspect ratio
                ),
                itemCount: _profileImages.length,
                itemBuilder: (context, index) {
                  String imageUrl = _profileImages[index]['url'];
                  String timestamp = _profileImages[index]['timestamp'];
                  DateTime uploadDate = DateTime.parse(timestamp);
                  String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(uploadDate);

                  return GestureDetector(
                    onTap: () => _showImagePreview(imageUrl, formattedDate, index),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.error));
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '$formattedDate',
                            style: const TextStyle(color: Colors.black, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
