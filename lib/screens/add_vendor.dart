import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AddVendorScreen extends StatefulWidget {
  const AddVendorScreen({Key? key}) : super(key: key);

  @override
  _AddVendorScreenState createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends State<AddVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _status = ''; // Default status
  List<PlatformFile> _selectedFiles = [];
  List<String> _fileNames = [];

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
                Icon(Icons.add_box_rounded, color: Colors.white), // Icon next to the text
                SizedBox(width: 8), // Space between icon and text
                Text(
                  "Add Vendor",
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person,
                ),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person,
                ),
                _buildTextField(
                  controller: _userNameController,
                  label: 'Username',
                  icon: Icons.person,
                ),
                _buildTextField(
                  controller: _contactNumberController,
                  label: 'Contact Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email,
                ),
                _buildStatusDropdown(),
                const SizedBox(height: 20),
                _buildFileUploadSection(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _selectedFiles.isNotEmpty && _formKey.currentState!.validate()
                      ? _submitForm
                      : null,
                  child: const Text('Add Vendor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        border: const UnderlineInputBorder(),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    controller.clear();
                  });
                },
              )
            : null,
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a Status',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        DropdownButtonFormField<String>(
          value: _status.isEmpty ? null : _status,
          hint: const Text('Select a Status'),
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            prefixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
          items: <String>['Pending', 'Approved', 'Declined', 'Request Info']
              .map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _status = newValue!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a vendor status';
            }
            return null;
          },
        ),
        if (_status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selected Status: $_status',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload vendor Valid ID',
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _selectFiles,
          child: const Text(
            'Upload Files',
            style: TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedFiles.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_selectedFiles.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fileNames[index],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedFiles.removeAt(index);
                          _fileNames.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          )
        else
          const Text(
            'No files selected',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
      ],
    );
  }

  Future<void> _selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
          _fileNames = result.files.map((file) => file.name).toList();
        });
      }
    } catch (e) {
      print("Error selecting files: $e");
    }
  }

  Future<String> _getNextAvailableId() async {
    try {
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersCollection.get();

      // Parse all document IDs as integers, then find the max ID
      int maxId = 0;
      for (var doc in querySnapshot.docs) {
        int id = int.tryParse(doc.id) ?? 0;
        if (id > maxId) {
          maxId = id;
        }
      }

      // Increment the max ID to get the next available ID
      int nextId = maxId + 1;

      // Format the ID to be 2 digits, e.g., 01, 02, etc.
      return nextId.toString().padLeft(2, '0');
    } catch (e) {
      print("Error getting next available ID: $e");
      return "01"; // Default ID in case of error
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final firestore = FirebaseFirestore.instance;
        final storage = FirebaseStorage.instance;

        // Get the next available ID
        final newId = await _getNextAvailableId();
        final vendorDoc = firestore.collection('users').doc(newId);

        // Upload files to Firebase Storage and get their URLs
        List<String> fileUrls = [];
        for (final file in _selectedFiles) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final storageRef = storage.ref().child('uploads/$newId/$fileName');
          final uploadTask = storageRef.putData(file.bytes!); // Use putData instead of putFile
          final snapshot = await uploadTask.whenComplete(() {});
          final downloadUrl = await snapshot.ref.getDownloadURL();
          fileUrls.add(downloadUrl);
        }

        // Store vendor data in Firestore
        await vendorDoc.set({
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'user_name': _userNameController.text,
          'contact_number': _contactNumberController.text,
          'email': _emailController.text,
          'status': _status,
          'files': fileUrls,
          'created_at': Timestamp.fromDate(DateTime.now()), // Add timestamp here
        });

        // Navigate back to the previous screen
        Navigator.of(context).pop();
      } catch (e) {
        print("Error adding vendor: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add vendor.')),
        );
      }
    }
  }
}
