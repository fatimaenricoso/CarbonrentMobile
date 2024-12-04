import 'dart:async';

import 'package:ambulantcollector/screens/appraisalReceipt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppraisalCollect extends StatefulWidget {
  @override
  _AppraisalCollectState createState() => _AppraisalCollectState();
}

class _AppraisalCollectState extends State<AppraisalCollect> {
  final TextEditingController goodsNameController = TextEditingController();
  final TextEditingController appRateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  List<String> suggestions = [];
  String? selectedGoodsName;
  List<String> appSizes = [];
  String? selectedAppSize;
  String? unitMeasure;
  bool isSearching = false;
  String? message;

  Timer? _debounce;

  @override
  void dispose() {
    goodsNameController.dispose();
    appRateController.dispose();
    quantityController.dispose();
    companyNameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchUniqueGoodsNameSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        suggestions.clear();
        message = null;
        appRateController.clear();
        quantityController.clear();
        selectedGoodsName = null;
        selectedAppSize = null;
        appSizes.clear();
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    final lowerCaseInput = input.toLowerCase();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isSearching = false;
        suggestions.clear();
        message = 'User not authenticated.';
      });
      return;
    }

    final appraiserDoc = await FirebaseFirestore.instance
        .collection('appraisal_user')
        .where('email', isEqualTo: user.email)
        .get();

    if (appraiserDoc.docs.isEmpty) {
      setState(() {
        isSearching = false;
        suggestions.clear();
        message = 'Appraiser not found.';
      });
      return;
    }

    final appraiserData = appraiserDoc.docs.first.data();
    final appraisalAssign = appraiserData['appraisal_assign'];

    final query = await FirebaseFirestore.instance
        .collection('appraisal_rate')
        .where('location', isEqualTo: appraisalAssign)
        .get();

    final uniqueGoodsNames = query.docs
        .map((doc) => doc['goods_name'] as String)
        .where((goodsName) =>
            goodsName.toLowerCase().contains(lowerCaseInput))
        .toSet()
        .toList();

    setState(() {
      suggestions = uniqueGoodsNames;
      message = uniqueGoodsNames.isEmpty ? 'No products or goods that match' : null;
      isSearching = false;
    });
  }

  Future<void> fetchAppRateAndUnitMeasure(String goodsName) async {
    final query = await FirebaseFirestore.instance
        .collection('appraisal_rate')
        .where('goods_name', isEqualTo: goodsName)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        unitMeasure = data['unit_measure'];
        appSizes = [];
        final rateSizePairs = data['rate_size_pairs'] as List<dynamic>;
        for (var pair in rateSizePairs) {
          final sizeKey = pair.keys.firstWhere((key) => key.toString().startsWith('size_'), orElse: () => '');
          if (sizeKey.isNotEmpty) {
            appSizes.add(pair[sizeKey]);
          }
        }
        selectedAppSize = null; // No pre-selection
        appRateController.clear();
        message = 'Please select a size to view appraisal rate of the product';
      });
    } else {
      setState(() {
        unitMeasure = null;
        appSizes = [];
        appRateController.clear();
        message = null;
      });
    }
  }

  Future<void> updateAppRate(String goodsName, String appSize) async {
    final query = await FirebaseFirestore.instance
        .collection('appraisal_rate')
        .where('goods_name', isEqualTo: goodsName)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final rateSizePairs = data['rate_size_pairs'] as List<dynamic>;
      for (var pair in rateSizePairs) {
        final sizeKey = pair.keys.firstWhere((key) => key.toString().startsWith('size_'), orElse: () => '');
        final rateKey = pair.keys.firstWhere((key) => key.toString().startsWith('rate_'), orElse: () => '');
        if (sizeKey.isNotEmpty && rateKey.isNotEmpty && pair[sizeKey] == appSize) {
          setState(() {
            appRateController.text = '₱${pair[rateKey].toStringAsFixed(2)}';
            message = null;
          });
          calculateTotalAmount(); // Recalculate total when app rate is updated
          return;
        }
      }
      setState(() {
        appRateController.clear();
        message = 'No appraisal rate found for the selected size.';
      });
    } else {
      setState(() {
        appRateController.clear();
        message = 'No appraisal rate found for the selected size.';
      });
    }
  }

  double calculateTotalAmount() {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final appRate = double.tryParse(appRateController.text.replaceAll(RegExp(r'[₱, ]'), '')) ?? 0.0;
    return quantity * appRate;
  }

  void _incrementQuantity() {
    setState(() {
      final currentValue = int.tryParse(quantityController.text) ?? 0;
      quantityController.text = (currentValue + 1).toString();
    });
  }

  void _decrementQuantity() {
    setState(() {
      final currentValue = int.tryParse(quantityController.text) ?? 0;
      if (currentValue > 0) {
        quantityController.text = (currentValue - 1).toString();
      }
    });
  }

  void _updateTotalAmount() {
    setState(() {
      // This will trigger a rebuild and update the total amount display
    });
  }

  Future<void> submitAppraisal() async {
    if (selectedGoodsName == null || selectedAppSize == null || quantityController.text.isEmpty || companyNameController.text.isEmpty) {
      // Show a message to complete the form if necessary
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    // Show confirmation dialog
    bool shouldProceed = await showConfirmationDialog(context);

    if (shouldProceed) {
      // Calculate total amount
      final totalAmount = calculateTotalAmount();
      double appRate = double.tryParse(appRateController.text.replaceAll(RegExp(r'[₱, ]'), '')) ?? 0.0;

      // Fetch current appraiser details
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated.')),
        );
        return;
      }

      final appraiserDoc = await FirebaseFirestore.instance.collection('appraisal_user').where('email', isEqualTo: user.email).get();
      if (appraiserDoc.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appraiser not found.')),
        );
        return;
      }

      final appraiserData = appraiserDoc.docs.first.data();
      final appraiserAppraisal = appraiserData['appraisal'];
      final appraiserEmail = appraiserData['email'];
      final addressAppraisal = appraiserData['Address_appraisal'];
      final contactAppraisal = appraiserData['contact_appraisal'];
      final appraisalAssign = appraiserData['appraisal_assign']; // Fetch appraisal_assign
      final vendorId = appraiserDoc.docs.first.id; // Get the document ID of the current user

      // Prepare the data to store
      final appraisalData = {
        'goods_name': selectedGoodsName,
        'app_size': selectedAppSize,
        'app_rate': appRate,
        'quantity': int.tryParse(quantityController.text),
        'unit_measure': unitMeasure,
        'total_amount': totalAmount, // Add total amount here
        'created_date': FieldValue.serverTimestamp(),
        'appraisal': appraiserAppraisal,
        'appraiser_email': appraiserEmail,
        'Address_appraisal': addressAppraisal,
        'contact_appraisal': contactAppraisal,
        'appraisee_name': companyNameController.text, // Add company name here
        'appraisal_assign': appraisalAssign, // Add appraisal_assign here
        'vendorId': vendorId, // Add vendorId here
      };

      // Store data in Firestore
      final docRef = await FirebaseFirestore.instance.collection('appraisals').add(appraisalData);

      // Navigate to the AppraisalDetailsPage with the document ID and await the result
      final shouldClearForm = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppraisalDetailsPage(documentId: docRef.id),
        ),
      );

      // Clear form fields if the result indicates so
      if (shouldClearForm == true) {
        setState(() {
          goodsNameController.clear();
          appRateController.clear();
          quantityController.clear();
          companyNameController.clear(); // Clear company name field
          selectedGoodsName = null;
          selectedAppSize = null;
          appSizes.clear();
          unitMeasure = null;
          message = null;
        });
      }
    }
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
                      'Please review all the information below before confirming. As you cannot edit or undo once confirmed.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Appraisal Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Appraisee Name', style: TextStyle(fontSize: 12)),
                        Text(companyNameController.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Product Name', style: TextStyle(fontSize: 12)),
                        Text(selectedGoodsName ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Size', style: TextStyle(fontSize: 12)),
                        Text(selectedAppSize ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Appraisal Rate', style: TextStyle(fontSize: 12)),
                        Text(appRateController.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity', style: TextStyle(fontSize: 12)),
                        Text(quantityController.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Unit Measure', style: TextStyle(fontSize: 12)),
                        Text(unitMeasure ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(color:Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('₱${calculateTotalAmount().toStringAsFixed(2)}', style: const TextStyle(color:Colors.black,fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: Text(
                  'Do you want to confirm appraisal?',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
/*             Icon(Icons.receipt_rounded, color: Colors.white),
 */            SizedBox(width: 15),
            Text("Appraisal Form", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove the back button
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
                        'Product Details',
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
                // Company Name TextField
                TextFormField(
                  controller: companyNameController,
                  decoration: InputDecoration(
                    labelText: 'Enter Appraisee Name',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder:  OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Goods Name TextField
                TextFormField(
                  controller: goodsNameController,
                  decoration: InputDecoration(
                    labelText: 'Enter Product Name',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    suffixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                    enabledBorder: OutlineInputBorder(
                      borderSide:const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder:  OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      fetchUniqueGoodsNameSuggestions(value);
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Suggestions List
                if (isSearching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                      ),
                    ),
                  ),

                if (!isSearching && suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return InkWell(
                          onTap: () async {
                            setState(() {
                              selectedGoodsName = suggestion;
                              goodsNameController.text = suggestion;
                              suggestions.clear();
                            });
                            await fetchAppRateAndUnitMeasure(suggestion);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: highlightMatches(suggestion, goodsNameController.text),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // App Size Dropdown
                DropdownButtonFormField<String>(
                  value: selectedAppSize,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select Size',),
                    ),
                    ...appSizes.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(size),
                      );
                    }).toList(),
                  ],
                  onChanged: (newValue) async {
                    setState(() {
                      selectedAppSize = newValue;
                    });
                    if (newValue != null && selectedGoodsName != null) {
                      await updateAppRate(selectedGoodsName!, newValue);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Size',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder:  OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 10, // Set width of TextField
                  child: TextFormField(
                    controller: appRateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Appraisal Rate',
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      focusedBorder:  OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                     /*  suffixText: unitMeasure != null ? ' $unitMeasure' : null, // Append unit measure here
                      suffixStyle: const TextStyle(color: Colors.black), // Style for the unit measure */
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quantity Input
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _updateTotalAmount();
                        },
                        decoration: InputDecoration(
                          labelText: 'Enter a Quantity',
                          labelStyle: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:const BorderSide(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.05),
                          contentPadding: const EdgeInsets.fromLTRB(16, 16, 50, 16),
                          suffixText: unitMeasure != null ? ' $unitMeasure' : null, // Add unit measure here
                          suffixStyle: const TextStyle(color: Colors.black), // Style for the unit measure
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _incrementQuantity,
                              child: const Icon(
                                Icons.arrow_drop_up,
                                color: Color(0xFF2E7D32),
                                size: 24,
                              ),
                            ),
                            InkWell(
                              onTap: _decrementQuantity,
                              child: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF2E7D32),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Total Amount Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₱${calculateTotalAmount().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: submitAppraisal, // Call the new submit method
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
                      'Confirm Appraisal',
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
