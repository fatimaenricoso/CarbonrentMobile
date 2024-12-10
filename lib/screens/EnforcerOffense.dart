import 'dart:async';
import 'dart:io';

import 'package:ambulantcollector/screens/EnforcerMade.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VendorOffense extends StatefulWidget {
  final String vendorName;
  final String location;
  final String stallNumber;
  final String vendorId; // Accept the vendorId
  final bool showBackButton; // Add a flag to show the back button

  VendorOffense({
    required this.vendorName,
    required this.location,
    required this.stallNumber,
    required this.vendorId, // Accept the vendorId
    this.showBackButton = false, // Default to false
  });

  @override
  _VendorOffenseState createState() => _VendorOffenseState();
}

class _VendorOffenseState extends State<VendorOffense> {
  final TextEditingController vendorNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController stallNumberController = TextEditingController();
  final TextEditingController violationTypeController = TextEditingController();
  List<String> suggestions = [];
  String? selectedVendorName;
  String? selectedOffense;
  bool isSearching = false;
  String? message;
  List<File> _images = [];
  List<String> _imageNames = [];
  String? userLocation;
  String? vendorId;
  double? dailyPayment;
  bool isFirstOffenseDisabled = false;
  bool isSecondOffenseDisabled = true;
  bool isFinalOffenseDisabled = true;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    vendorNameController.text = widget.vendorName;
    locationController.text = widget.location;
    stallNumberController.text = widget.stallNumber;
    vendorId = widget.vendorId; // Initialize the vendorId
    selectedVendorName = widget.vendorName; // Initialize the selectedVendorName
    _fetchUserLocation();
    _checkExistingOffenses();
    vendorNameController.addListener(_onVendorNameChanged);
  }

  Future<void> _fetchUserLocation() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userLocation = userDoc.data()?['location'];
        });
        print('User Location: $userLocation'); // Debugging statement
      } else {
        print('User document does not exist'); // Debugging statement
      }
    } else {
      print('User not authenticated'); // Debugging statement
    }
  }

  @override
  void dispose() {
    vendorNameController.dispose();
    locationController.dispose();
    stallNumberController.dispose();
    violationTypeController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onVendorNameChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      fetchVendorSuggestions(vendorNameController.text);
    });
  }

  Future<void> fetchVendorSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        suggestions.clear();
        message = null;
        selectedVendorName = null;
        locationController.clear();
        stallNumberController.clear();
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    if (userLocation == null) {
      setState(() {
        isSearching = false;
        suggestions.clear();
        message = 'User location not found.';
      });
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('approvedVendors')
        .where('stallInfo.location', isEqualTo: userLocation)
        .get();

    final lowerCaseInput = input.toLowerCase();
    final vendorNames = query.docs
        .where((doc) =>
            (doc['firstName'] as String).toLowerCase().contains(lowerCaseInput) ||
            (doc['lastName'] as String).toLowerCase().contains(lowerCaseInput))
        .map((doc) => '${doc['firstName']} ${doc['lastName']}')
        .toSet()
        .toList();

    setState(() {
      suggestions = vendorNames;
      message = vendorNames.isEmpty ? 'No vendors found' : null;
      isSearching = false;
    });

    print('Vendor Suggestions: $suggestions'); // Debugging statement
  }

  Future<void> fetchVendorDetails(String vendorName) async {
    final query = await FirebaseFirestore.instance
        .collection('approvedVendors')
        .where('firstName', isEqualTo: vendorName.split(' ')[0])
        .where('lastName', isEqualTo: vendorName.split(' ')[1])
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      setState(() {
        locationController.text = data['stallInfo']['location'];
        stallNumberController.text = data['stallInfo']['stallNumber'];
        vendorId = doc.id; // Store the vendor ID
      });
      await _checkExistingOffenses();
    } else {
      setState(() {
        locationController.clear();
        stallNumberController.clear();
        vendorId = null; // Clear the vendor ID
        isFirstOffenseDisabled = false;
        isSecondOffenseDisabled = true;
        isFinalOffenseDisabled = true;
      });
    }
  }

  Future<void> _checkExistingOffenses() async {
    if (vendorId != null) {
      final query = await FirebaseFirestore.instance
          .collection('Market_violations')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      bool hasFirstOffense = false;
      bool hasSecondOffense = false;
      bool hasFinalOffense = false;

      for (var doc in query.docs) {
        final data = doc.data();
        if (data['status'] != 'Declined') {
          if (data['warning'] == '1st Offense') {
            hasFirstOffense = true;
          } else if (data['warning'] == '2nd Offense') {
            hasSecondOffense = true;
          } else if (data['warning'] == 'Final Offense') {
            hasFinalOffense = true;
          }
        }
      }

      setState(() {
        isFirstOffenseDisabled = hasFirstOffense;
        isSecondOffenseDisabled = hasSecondOffense || !hasFirstOffense;
        isFinalOffenseDisabled = hasFinalOffense || !hasSecondOffense;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
        _imageNames.add(pickedFile.name);
      });
      print('Image picked: ${pickedFile.name}'); // Debugging statement
    }
  }

  Future<void> submitOffense() async {
    // Debugging statements
    print('selectedVendorName: $selectedVendorName');
    print('selectedOffense: $selectedOffense');
    print('violationTypeController.text: ${violationTypeController.text}');
    print('_images: ${_images.length}');

    if (selectedVendorName == null || selectedOffense == null || violationTypeController.text.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    // Show confirmation dialog
    bool shouldProceed = await showConfirmationDialog(context);

    if (shouldProceed) {
      // Prepare the data to store
      final offenseData = {
        'vendorName': selectedVendorName,
        'stallLocation': locationController.text,
        'stallNo': stallNumberController.text,
        'warning': selectedOffense,
        'violationType': violationTypeController.text,
        'status': 'To be Reviewed',
        'vendorId': vendorId,
        'date': FieldValue.serverTimestamp(),
      };

      // Store data in Firestore
      final docRef = await FirebaseFirestore.instance.collection('Market_violations').add(offenseData);

      // Upload the images to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('Enforcer/$userLocation/Photos/${docRef.id}');
      for (int i = 0; i < _images.length; i++) {
        final uploadTask = storageRef.child('photo_$i.jpg').putFile(_images[i]);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update the document with the image URLs
        await docRef.update({'image_$i': downloadUrl});
      }

      // Calculate the daily payment
      dailyPayment = await calculateDailyPayment(vendorId!);

      // Update the document with the daily payment
      await docRef.update({'dailyPayment': dailyPayment});

      // Clear form fields
      setState(() {
        vendorNameController.clear();
        locationController.clear();
        stallNumberController.clear();
        violationTypeController.clear();
        selectedVendorName = null;
        selectedOffense = null;
        _images.clear();
        _imageNames.clear();
        message = null;
        vendorId = null;
        isFirstOffenseDisabled = false;
        isSecondOffenseDisabled = true;
        isFinalOffenseDisabled = true;
      });

      // Show success dialog
      await showSuccessDialog(context, docRef.id);
    }
  }

  Future<double> calculateDailyPayment(String vendorId) async {
    // Query the billingconfig collection to find the document with the title field value "RateperMeter"
    final querySnapshot = await FirebaseFirestore.instance
        .collection('billingconfig')
        .where('title', isEqualTo: 'RateperMeter')
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final value1 = doc['value1'];

      // Fetch the vendor document to get the stall size
      final vendorDoc = await FirebaseFirestore.instance
          .collection('approvedVendors')
          .doc(vendorId)
          .get();

      if (vendorDoc.exists) {
        final stallSize = vendorDoc.data()?['stallInfo']['stallSize'];
        return value1 * stallSize;
      }
    }
    return 0.0;
  }

  Future<bool> showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                ),
                child: const Text(
                  'Confirm Submission',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please review all the information below before confirming.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Violation Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vendor Name', style: TextStyle(fontSize: 12)),
                        Text(selectedVendorName ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Location', style: TextStyle(fontSize: 12)),
                        Text(locationController.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Stall Number', style: TextStyle(fontSize: 12)),
                        Text(stallNumberController.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Violation', style: TextStyle(fontSize: 12)),
                        Text(selectedOffense ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Violation Type', style: TextStyle(fontSize: 12)),
                        Text(violationTypeController.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Violation Photos', style: TextStyle(fontSize: 12)),
                        _images.isNotEmpty
                            ? Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _images.map((image) {
                                    int index = _images.indexOf(image);
                                    return Row(
                                      children: [
                                        Image.file(image, height: 50, width: 50),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _imageNames[index],
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              )
                            : const Text('No photos selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Text(
                  'Do you want to confirm the offense?',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'No',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ) ?? false;
  }

  Future<void> showSuccessDialog(BuildContext context, String offenseId) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Offense submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OffenseMade(offenseId: offenseId),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 15),
            Text("Violation Form", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.showBackButton, // Show back button if the flag is true
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95, // Adjusted width
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Violation Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Dark green for headers
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please fill in the details below',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields
                // Vendor Name TextField
                TextFormField(
                  controller: vendorNameController,
                  decoration: InputDecoration(
                    labelText: 'Enter Vendor Name',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                if (suggestions.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return ListTile(
                        title: RichText(
                          text: TextSpan(
                            children: highlightMatches(suggestion, vendorNameController.text),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            vendorNameController.text = suggestion;
                            selectedVendorName = suggestion;
                            suggestions.clear();
                          });
                          fetchVendorDetails(suggestion);
                        },
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Location TextField
                TextFormField(
                  controller: locationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Stall Number TextField
                TextFormField(
                  controller: stallNumberController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Stall Number',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Offense Dropdown
                DropdownButtonFormField<String>(
                  value: selectedOffense,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Select Offense', style: TextStyle(color: isFirstOffenseDisabled ? Colors.grey : Colors.black)),
                      enabled: !isFirstOffenseDisabled,
                    ),
                    DropdownMenuItem(
                      value: '1st Offense',
                      child: Text('1st Offense', style: TextStyle(color: isFirstOffenseDisabled ? Colors.grey : Colors.black)),
                      enabled: !isFirstOffenseDisabled,
                    ),
                    DropdownMenuItem(
                      value: '2nd Offense',
                      child: Text('2nd Offense', style: TextStyle(color: isSecondOffenseDisabled ? Colors.grey : Colors.black)),
                      enabled: !isSecondOffenseDisabled,
                    ),
                    DropdownMenuItem(
                      value: 'Final Offense',
                      child: Text('Final Offense', style: TextStyle(color: isFinalOffenseDisabled ? Colors.grey : Colors.black)),
                      enabled: !isFinalOffenseDisabled,
                    ),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      selectedOffense = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Offense',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Violation Type TextField
                TextFormField(
                  controller: violationTypeController,
                  decoration: InputDecoration(
                    labelText: 'Enter Violation Type',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Violation Photo Upload
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _images.isNotEmpty
                            ? GridView.builder(
                                itemCount: _images.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 4.0,
                                  mainAxisSpacing: 4.0,
                                ),
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Image.file(
                                        _images[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            setState(() {
                                              _images.removeAt(index);
                                              _imageNames.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : const Center(
                                child: Text(
                                  'Tap to upload violation photo',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_images.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Uploaded Photos:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: List.generate(_images.length, (index) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _imageNames[index],
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        _images.removeAt(index);
                                        _imageNames.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // Send Offense Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: submitOffense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 50, 176, 56),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Send Offense',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<TextSpan> highlightMatches(String suggestion, String input) {
    List<TextSpan> spans = [];
    int start = 0;
    final lowerCaseInput = input.toLowerCase();
    int matchStartIndex = suggestion.toLowerCase().indexOf(lowerCaseInput);

    while (matchStartIndex != -1) {
      if (start < matchStartIndex) {
        spans.add(TextSpan(
          text: suggestion.substring(start, matchStartIndex),
          style: const TextStyle(color: Colors.black),
        ));
      }
      spans.add(TextSpan(
        text: suggestion.substring(matchStartIndex, matchStartIndex + input.length),
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ));
      start = matchStartIndex + input.length;
      matchStartIndex = suggestion.toLowerCase().indexOf(lowerCaseInput, start);
    }

    if (start < suggestion.length) {
      spans.add(TextSpan(
        text: suggestion.substring(start),
        style: const TextStyle(color: Colors.black),
      ));
    }

    return spans;
  }
}
