import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ambulantcollector/components/my_button.dart';
import 'package:ambulantcollector/components/my_textfield.dart';
import 'package:ambulantcollector/components/square_tile.dart';
import 'package:ambulantcollector/screens/pending_registration.dart';
import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  final String stallId;
  final Map<String, dynamic> stallData;

  const RegisterPage({
    Key? key,
    required this.stallId,
    required this.stallData,
  }) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final dateController = TextEditingController();
  final contactNumberController = TextEditingController();
  String? selectedBillingCycle;
  DateTime? selectedDate;

  List<File?> _profileImages = [];
  List<Uint8List?> webProfileImages = [];
  final ImagePicker _picker = ImagePicker();
  String selectedImageNames = '';

  String? selectedRegion;
  String? selectedProvince;
  String? selectedCity;
  String? selectedBarangay;

  List<dynamic> regions = [];
  List<dynamic> provinces = [];
  List<dynamic> cities = [];
  List<dynamic> barangays = [];

  @override
  void initState() {
    super.initState();
    fetchRegions();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    dateController.dispose();
    contactNumberController.dispose();
    super.dispose();
  }

  Future<void> fetchRegions() async {
    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/regions/'));
      if (response.statusCode == 200) {
        setState(() {
          regions = json.decode(response.body);
        });
        print('Fetched regions: $regions');
      } else {
        print('Failed to fetch regions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching regions: $e');
    }
  }

  Future<void> fetchProvinces(String regionCode) async {
    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/provinces/?regionCode=$regionCode'));
      if (response.statusCode == 200) {
        setState(() {
          provinces = json.decode(response.body);
        });
        print('Fetched provinces: $provinces');
      } else {
        print('Failed to fetch provinces: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching provinces: $e');
    }
  }

  Future<void> fetchCities(String provinceCode) async {
    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/cities/?provinceCode=$provinceCode'));
      if (response.statusCode == 200) {
        setState(() {
          cities = json.decode(response.body);
        });
        print('Fetched cities: $cities');
      } else {
        print('Failed to fetch cities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching cities: $e');
    }
  }

  Future<void> fetchBarangays(String cityCode) async {
    try {
      final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/barangays/?cityCode=$cityCode'));
      if (response.statusCode == 200) {
        setState(() {
          barangays = json.decode(response.body);
        });
        print('Fetched barangays: $barangays');
      } else {
        print('Failed to fetch barangays: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching barangays: $e');
    }
  }

  Future<void> signUpUser() async {
    if (firstNameController.text.trim().isEmpty ||
        middleNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty ||
        dateController.text.trim().isEmpty ||
        selectedBarangay == null ||
        selectedCity == null ||
        contactNumberController.text.trim().isEmpty ||
        selectedBillingCycle == null ||
        _profileImages.isEmpty && webProfileImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill in all fields and upload a profile picture')),
      );
      return;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        final List<String> profileImageUrls = [];

        if (kIsWeb) {
          for (var bytes in webProfileImages) {
            if (bytes != null) {
              final storageRef = FirebaseStorage.instance.ref().child(
                  'profile_images/${userCredential.user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
              await storageRef.putData(bytes);
              final downloadUrl = await storageRef.getDownloadURL();
              profileImageUrls.add(downloadUrl);
            }
          }
        } else {
          for (var file in _profileImages) {
            if (file != null) {
              final storageRef = FirebaseStorage.instance.ref().child(
                  'profile_images/${userCredential.user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
              await storageRef.putFile(file);
              final downloadUrl = await storageRef.getDownloadURL();
              profileImageUrls.add(downloadUrl);
            }
          }
        }

        await FirebaseFirestore.instance
            .collection('Vendorusers')
            .doc(userCredential.user!.uid)
            .set({
          'firstName': firstNameController.text.trim(),
          'middleName': middleNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'dateOfRegistration': selectedDate ?? DateTime.now(),
          'status': 'pending',
          'barangay': selectedBarangay,
          'city': selectedCity,
          'contactNumber': contactNumberController.text.trim(),
          'billingCycle': selectedBillingCycle,
          'stallId': widget.stallId,
          'stallInfo': widget.stallData,
          'profileImageUrls': profileImageUrls,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RegistrationPendingPage(),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'The email is already in use.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled.';
            break;
          case 'weak-password':
            errorMessage = 'The password is too weak.';
            break;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing up: $errorMessage')),
      );
    }
  }

  Future<void> _pickProfileImages() async {
    final pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null) {
      List<File?> tempProfileImages = [];
      List<Uint8List?> tempWebProfileImages = [];
      List<String> tempImageNames = [];

      if (kIsWeb) {
        for (var pickedFile in pickedFiles) {
          final bytes = await pickedFile.readAsBytes();
          tempWebProfileImages.add(bytes);
          tempProfileImages.add(null);
          tempImageNames.add(pickedFile.name);
        }
      } else {
        for (var pickedFile in pickedFiles) {
          tempProfileImages.add(File(pickedFile.path));
          tempImageNames.add(pickedFile.path.split('/').last);
        }
      }

      setState(() {
        _profileImages = tempProfileImages;
        webProfileImages = tempWebProfileImages;
        selectedImageNames = tempImageNames.join(', ');
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: AppBar(
          backgroundColor: Colors.green,
          flexibleSpace: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: SquareTile(imagePath: 'lib/images/logo.png'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Create an Account',
                        style: GoogleFonts.kanit(
                          fontSize:
                              26,
                          color: const Color.fromARGB(255, 129, 32, 32),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickProfileImages,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _profileImages.isNotEmpty
                                ? 'Selected Images: $selectedImageNames'
                                : 'Tap to select profile images',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.upload_file),
                          color: Colors.green,
                          onPressed: _pickProfileImages,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: MyTextfield(
                          controller: firstNameController,
                          hintText: 'First Name',
                          obscureText: false,
                          borderRadius: BorderRadius.circular(12.0),
                          fillColor: Colors.white,
                          readOnly: false,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: MyTextfield(
                          controller: middleNameController,
                          hintText: 'Middle Name',
                          obscureText: false,
                          borderRadius: BorderRadius.circular(12.0),
                          fillColor: Colors.white,
                          readOnly: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                MyTextfield(
                  controller: lastNameController,
                  hintText: 'Last Name',
                  obscureText: false,
                  borderRadius: BorderRadius.circular(12.0),
                  fillColor: Colors.white,
                  readOnly: false,
                ),
                const SizedBox(height: 20),

                MyTextfield(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                  borderRadius: BorderRadius.circular(12.0),
                  fillColor: Colors.white,
                  readOnly: false,
                ),
                const SizedBox(height: 20),

                MyTextfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  borderRadius: BorderRadius.circular(12.0),
                  fillColor: Colors.white,
                  readOnly: false,
                ),
                const SizedBox(height: 20),

                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                  borderRadius: BorderRadius.circular(12.0),
                  fillColor: Colors.white,
                  readOnly: false,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Region',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: selectedRegion,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRegion = newValue;
                      selectedProvince = null;
                      selectedCity = null;
                      selectedBarangay = null;
                      provinces = [];
                      cities = [];
                      barangays = [];
                    });
                    if (newValue != null) {
                      fetchProvinces(newValue);
                    }
                  },
                  items: regions.map<DropdownMenuItem<String>>((region) {
                    return DropdownMenuItem<String>(
                      value: region['code'],
                      child: Text(region['name']),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Province',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: selectedProvince,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedProvince = newValue;
                      selectedCity = null;
                      selectedBarangay = null;
                      cities = [];
                      barangays = [];
                    });
                    if (newValue != null) {
                      fetchCities(newValue);
                    }
                  },
                  items: provinces.map<DropdownMenuItem<String>>((province) {
                    return DropdownMenuItem<String>(
                      value: province['code'],
                      child: Text(province['name']),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'City/Municipality',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: selectedCity,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCity = newValue;
                      selectedBarangay = null;
                      barangays = [];
                    });
                    if (newValue != null) {
                      fetchBarangays(newValue);
                    }
                  },
                  items: cities.map<DropdownMenuItem<String>>((city) {
                    return DropdownMenuItem<String>(
                      value: city['code'],
                      child: Text(city['name']),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: selectedBarangay,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBarangay = newValue;
                    });
                  },
                  items: barangays.map<DropdownMenuItem<String>>((barangay) {
                    return DropdownMenuItem<String>(
                      value: barangay['code'],
                      child: Text(barangay['name']),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                MyTextfield(
                  controller: contactNumberController,
                  hintText: 'Contact Number',
                  obscureText: false,
                  borderRadius: BorderRadius.circular(12.0),
                  fillColor: Colors.white,
                  readOnly: false,
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.green),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBillingCycle,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Select Billing Cycle',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedBillingCycle = newValue;
                          });
                        },
                        items: ['Daily', 'Weekly', 'Monthly']
                            .map((value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Text(value),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: MyTextfield(
                      controller: dateController,
                      hintText: 'Date of Registration',
                      obscureText: false,
                      readOnly: true,
                      borderRadius: BorderRadius.circular(12.0),
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                MyButton(
                  buttonText: "Sign Up",
                  onTap: signUpUser,
                  borderRadius: BorderRadius.circular(12.0),
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),

                const SizedBox(height: 30),

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UnifiedLoginScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Text(
                      "Already registered? Login",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
