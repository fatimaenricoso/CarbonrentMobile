import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class RegistrationPendingPage extends StatefulWidget {
  const RegistrationPendingPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPendingPage> createState() =>
      _RegistrationPendingPageState();
}

class _RegistrationPendingPageState extends State<RegistrationPendingPage> {
  List<Map<String, dynamic>> requests = [];
  bool isUploading = false;
  List<XFile?> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _fetchRequestsFromFirestore();
  }

  Future<void> _fetchRequestsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('Vendorusers')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final timeline = userData?['timeline'] ?? [];
          setState(() {
            requests = List<Map<String, dynamic>>.from(timeline);
          });
        }
      } catch (e) {
        print('Error fetching user requests: $e');
      }
    }
  }

  Future<void> _pickFiles() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        selectedFiles.addAll(pickedFiles);
      });
    } else {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        for (var file in result.files) {
          setState(() {
            selectedFiles.add(XFile(file.path!));
          });
        }
      }
    }
  }

  Widget _buildFilePreviews() {
    if (selectedFiles.isEmpty) {
      return const Text('No files selected.');
    }

    return Column(
      children: selectedFiles.map((file) {
        bool isImageFile = file != null &&
            (file.path.endsWith('.png') ||
                file.path.endsWith('.jpg') ||
                file.path.endsWith('.jpeg'));

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            children: [
              if (isImageFile) ...[
                kIsWeb
                    ? Image.network(
                        file.path,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(file.path),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                const SizedBox(width: 10),
              ] else ...[
                const Icon(Icons.description, color: Colors.grey),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  file?.name ?? 'Unknown File',
                  style: const TextStyle(color: Colors.blue),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUploadedFilePreviews(List<dynamic> uploadedFiles) {
    if (uploadedFiles.isEmpty) {
      return const Text('No files uploaded.');
    }

    return Column(
      children: uploadedFiles.map((fileUrl) {
        bool isImageFile = fileUrl.endsWith('.png') ||
            fileUrl.endsWith('.jpg') ||
            fileUrl.endsWith('.jpeg');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            children: [
              if (isImageFile) ...[
                Image.network(
                  fileUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 10),
              ] else ...[
                const Icon(Icons.description, color: Colors.grey),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: InkWell(
                  onTap: () async {
                    if (await canLaunch(fileUrl)) {
                      await launch(fileUrl);
                    }
                  },
                  child: Text(
                    fileUrl.split('/').last,
                    style: const TextStyle(color: Colors.blue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _uploadFiles(int requestIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isUploading = true;
      });

      try {
        List<String> downloadUrls = [];

        for (var file in selectedFiles) {
          if (file != null) {
            String fileName = file.name;
            Reference storageRef = FirebaseStorage.instance
                .ref('user_documents/${user.uid}/uploads/$fileName');

            if (kIsWeb) {
              final uploadTask = storageRef.putData(await file.readAsBytes());
              await uploadTask;
            } else {
              await storageRef.putFile(File(file.path));
            }

            String downloadUrl = await storageRef.getDownloadURL();
            downloadUrls.add(downloadUrl);
          }
        }

        String submissionKey = 'isSubmitted${requestIndex + 1}';

        // Update the specific request in the timeline
        requests[requestIndex][submissionKey] = true;
        requests[requestIndex]['status'] = 'requested sent';
        requests[requestIndex]['uploadFile'] = downloadUrls;

        await FirebaseFirestore.instance
            .collection('Vendorusers')
            .doc(user.uid)
            .update({
          'timeline': requests,
        });

        setState(() {
          isUploading = false;
          selectedFiles.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Files uploaded successfully')),
        );
      } catch (e) {
        setState(() {
          isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload files: $e')),
        );
      }
    }
  }

  Future<void> _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      // Navigate to the UnifiedLoginScreen
      Navigator.of(context).pushReplacementNamed('/unifiedLogin');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: AppBar(
          backgroundColor: Colors.green,
          title: const Text('Registration Status',
              style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logOut,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRegistrationStatus(),
              const SizedBox(height: 10),
              if (requests.isNotEmpty)
                for (int i = 0; i < requests.length; i++)
                  _buildRequestInfo(
                    'Request Info - ${i + 1}',
                    requests[i]['message'],
                    requests[i]['isSubmitted${i + 1}'] ?? false,
                    requests[i]['uploadFile'] ?? [],
                    i,
                  ),
              const SizedBox(height: 20),
              _buildTimelineRequest('Pending Approval', 2, 'approval'),
              _buildTimelineRequest('Approved', 3, 'approved'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Text(
              'Registration',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Text(
              'Pending Review',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineRequest(String title, int step, String status) {
    bool isCompleted = step == 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 30,
            ),
            Container(
              width: 2,
              height: 40,
              color: Colors.grey,
            ),
          ],
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRequestInfo(String title, String message, bool isSubmitted,
      List<dynamic> uploadedFiles, int requestIndex) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.roboto(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, style: GoogleFonts.roboto(fontSize: 16)),
            const SizedBox(height: 10),
            if (!isSubmitted)
              ElevatedButton(
                onPressed: _pickFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text('Upload Supporting Document',
                    style: TextStyle(color: Color.fromARGB(255, 123, 13, 13))),
              ),
            const SizedBox(height: 10),
            _buildFilePreviews(),
            if (uploadedFiles.isNotEmpty)
              _buildUploadedFilePreviews(uploadedFiles),
            const SizedBox(height: 10),
            if (selectedFiles.isNotEmpty)
              ElevatedButton(
                onPressed: () => _uploadFiles(requestIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Request',
                        style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
