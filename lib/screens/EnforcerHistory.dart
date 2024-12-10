import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnforcerHistory extends StatefulWidget {
  const EnforcerHistory({Key? key}) : super(key: key);

  @override
  _EnforcerHistoryState createState() => _EnforcerHistoryState();
}

class _EnforcerHistoryState extends State<EnforcerHistory> {
  final CollectionReference violationsRef = FirebaseFirestore.instance.collection('Market_violations');
  String _selectedFilter = 'All';
  String _searchQuery = '';
  Map<String, bool> tappedContainers = {};
  SharedPreferences? prefs;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      _loadTappedContainers();
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  void _loadTappedContainers() {
    if (!mounted || prefs == null) return;

    setState(() {
      final tappedKeys = prefs!.getKeys().where((key) => key.startsWith('tapped_'));
      tappedContainers.clear();
      for (var key in tappedKeys) {
        final documentId = key.replaceFirst('tapped_', '');
        tappedContainers[documentId] = prefs!.getBool(key) ?? false;
      }
    });
  }

  Future<void> _saveTappedContainer(String documentId) async {
    if (prefs == null) return;

    await prefs!.setBool('tapped_$documentId', true);
    if (mounted) {
      setState(() {
        tappedContainers[documentId] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Violations History",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0.0, left: 5.0, right: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Filter ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                _buildFilterButton('All'),
                const SizedBox(width: 10),
                _buildFilterButton('Today'),
                const SizedBox(width: 10),
                _buildFilterButton('This Week'),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Enter date or Vendor Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.green.shade700),
                ),
                suffixIcon: const Icon(Icons.search, color: Colors.green),
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buildViolationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _selectedFilter == filter ? Colors.green : const Color.fromARGB(255, 136, 136, 136)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.transparent,
        minimumSize: const Size(2, 25),
        padding: const EdgeInsets.symmetric(horizontal: 15),
      ),
      onPressed: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Text(
        filter,
        style: TextStyle(
          color: _selectedFilter == filter ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildViolationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: violationsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        final allViolations = snapshot.data!.docs;
        final filteredViolations = _filterViolations(allViolations);

        if (filteredViolations.isEmpty) {
          return const Center(child: Text('No matching results'));
        }

        filteredViolations.sort((a, b) {
          DateTime dateA = (a['date'] as Timestamp).toDate();
          DateTime dateB = (b['date'] as Timestamp).toDate();
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          itemCount: filteredViolations.length,
          itemBuilder: (context, index) {
            final violation = filteredViolations[index];
            final documentId = violation.id;
            DateTime violationDate = (violation['date'] as Timestamp).toDate();
            final DateFormat formatter = DateFormat('MM/dd/yyyy');
            final String violationDateFormatted = formatter.format(violationDate);

            final bool isTapped = tappedContainers[documentId] ?? false;

            return GestureDetector(
              onTap: () {
                _saveTappedContainer(documentId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViolationDetails(documentId: documentId),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTapped ? const Color.fromARGB(255, 252, 249, 249) : const Color.fromARGB(255, 238, 230, 230),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color.fromARGB(255, 226, 228, 226)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              children: _highlightMatches(violation['vendorName'], _searchQuery),
                            ),
                          ),
                          Text(
                            violationDateFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Status: ${violation['status']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Warning: ${violation['warning']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<InlineSpan> _highlightMatches(String text, String query) {
    final List<InlineSpan> spans = [];
    final RegExp regex = RegExp(query, caseSensitive: false);
    final matches = regex.allMatches(text);

    int lastEnd = 0;
    for (var match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans;
  }

  List<DocumentSnapshot> _filterViolations(List<DocumentSnapshot> allViolations) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final formattedSearchQuery = _searchQuery.toLowerCase();

    List<DocumentSnapshot> filtered;

    if (_selectedFilter == 'Today') {
      filtered = allViolations.where((doc) {
        DateTime violationDate = (doc['date'] as Timestamp).toDate();
        return DateFormat('MM/dd/yyyy').format(violationDate) ==
            DateFormat('MM/dd/yyyy').format(now);
      }).toList();
    } else if (_selectedFilter == 'This Week') {
      filtered = allViolations.where((doc) {
        DateTime violationDate = (doc['date'] as Timestamp).toDate();
        return violationDate.isAfter(weekStart) && violationDate.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    } else {
      filtered = allViolations;
    }

    return filtered.where((doc) {
      DateTime violationDate = (doc['date'] as Timestamp).toDate();
      String formattedDate = DateFormat('MM/dd/yyyy').format(violationDate);
      String vendorName = doc['vendorName'].toLowerCase();
      return vendorName.contains(formattedSearchQuery) ||
          formattedDate.contains(formattedSearchQuery);
    }).toList();
  }
}

class ViolationDetails extends StatefulWidget {
  final String documentId;

  const ViolationDetails({Key? key, required this.documentId}) : super(key: key);

  @override
  _ViolationDetailsState createState() => _ViolationDetailsState();
}

class _ViolationDetailsState extends State<ViolationDetails> {
  late Map<String, dynamic> data;
  bool isEditing = false;
  TextEditingController violationTypeController = TextEditingController();
  List<String> imageUrls = [];
  List<String> newImageUrls = [];
  List<String> removedImageUrls = [];

  @override
  Widget build(BuildContext context) {
    final CollectionReference violationsRef = FirebaseFirestore.instance.collection('Market_violations');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Violation Details",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: violationsRef.doc(widget.documentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No data available'));
          }

          data = snapshot.data!.data() as Map<String, dynamic>;
          DateTime violationDate = (data['date'] as Timestamp).toDate();
          final DateFormat formatter = DateFormat('MM/dd/yyyy');
          final String violationDateFormatted = formatter.format(violationDate);

          if (!isEditing) {
            violationTypeController.text = data['violationType'];
            imageUrls = _extractImageUrls(data);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isEditing)
                        ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: const Text('Save'),
                        )
                      else
                        ElevatedButton(
                          onPressed: _startEditing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: BorderSide(color: Colors.green, width: 1.0),
                            ),
                          ),
                          child: const Text('Edit'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Vendor Name', data['vendorName']),
                  _buildDivider(),
                  _buildDetailRow('Stall No', data['stallNo']),
                  _buildDivider(),
                  _buildEditableDetailRow('Violation Type', violationTypeController, isEditing),
                  _buildDivider(),
                  _buildDetailRow('Status', data['status']),
                  _buildDivider(),
                  _buildDetailRow('Warning', data['warning']),
                  _buildDivider(),
                  _buildImageGallery(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _startEditing() {
    setState(() {
      isEditing = true;
    });
  }

  void _saveChanges() async {
    final CollectionReference violationsRef = FirebaseFirestore.instance.collection('Market_violations');

    try {
      // Update violation type
      await violationsRef.doc(widget.documentId).update({
        'violationType': violationTypeController.text,
      });

      // Remove images
      for (var url in removedImageUrls) {
        await violationsRef.doc(widget.documentId).update({
          for (int i = 0; i <= 10; i++)
            if (data.containsKey('image_$i') && data['image_$i'] == url) 'image_$i': FieldValue.delete,
        });
      }

      // Add new images
      for (int i = 0; i < newImageUrls.length; i++) {
        await violationsRef.doc(widget.documentId).update({
          'image_$i': newImageUrls[i],
        });
      }

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailRow(String title, TextEditingController controller, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isEditing)
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            )
          else
            Row(
              children: [
                Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const Icon(Icons.edit, color: Colors.green, size: 18),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Colors.grey,
      thickness: 1,
      height: 1,
    );
  }

  Widget _buildImageGallery() {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'Images:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...imageUrls.map((url) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Stack(
                      children: [
                        Image.network(
                          url,
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _confirmRemoveImage(url),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 40),
                  onPressed: _addNewImage,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return _buildImageGalleryReadOnly();
    }
  }

  Widget _buildImageGalleryReadOnly() {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            'Images:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: imageUrls.map((url) {
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Image.network(
                  url,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _confirmRemoveImage(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Removal'),
          content: const Text('Are you sure you want to remove this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  imageUrls.remove(url);
                  removedImageUrls.add(url);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _addNewImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      final String imageUrl = await _uploadImageToFirebase(file);
      setState(() {
        newImageUrls.add(imageUrl);
      });
    }
  }

  Future<String> _uploadImageToFirebase(File imageFile) async {
    final Reference storageReference = FirebaseStorage.instance.ref().child('violations/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final UploadTask uploadTask = storageReference.putFile(imageFile);
    final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
    final String imageUrl = await taskSnapshot.ref.getDownloadURL();
    return imageUrl;
  }

  List<String> _extractImageUrls(Map<String, dynamic> data) {
    final imageUrls = <String>[];
    for (int i = 0; i <= 10; i++) {
      final imageKey = 'image_$i';
      if (data.containsKey(imageKey)) {
        imageUrls.add(data[imageKey]);
      }
    }
    return imageUrls;
  }
}
