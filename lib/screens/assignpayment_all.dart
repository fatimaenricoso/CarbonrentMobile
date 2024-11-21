import 'package:ambulantcollector/screens/dashboardvendor.dart';
import 'package:ambulantcollector/screens/vendor_payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date


class AssignPaymentAllScreen extends StatefulWidget {

  const AssignPaymentAllScreen({Key? key}) : super(key: key);

  @override
  _AssignPaymentScreenState createState() => _AssignPaymentScreenState();
}

class _AssignPaymentScreenState extends State<AssignPaymentAllScreen> {
  TextEditingController payorController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController ticketController = TextEditingController();
  TextEditingController numberOfTicketsController = TextEditingController();
  TextEditingController totalAmountController = TextEditingController();
  Map<String, TextEditingController> feeControllers = {};
  Map<String, String> feeLabels = {};
  Map<String, double> feeRates = {};  // Map to store fee rates from Firestore
  Map<String, String> feeSummary = {};

  
  double ticketRate = 5.0; // Set ticket rate to 5 (as per your example)
  int numberOfTickets = 4; // Default number of tickets

  
  @override
  void initState() {
    super.initState();
    _loadPayorData();
    _initializeDate();
    ticketController.text = ticketRate.toStringAsFixed(2);
    numberOfTicketsController.text = numberOfTickets.toString();
    _calculateTotalAmount(); // Calculate the total amount when initializing
    _loadFees();  }
    
Future<void> _loadPayorData() async {
  // Get the currently logged-in user's email
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    String email = currentUser.email!; // Assuming email will never be null

    // Query the Firestore collection 'ambulant_collector' to find the collector with this email
    QuerySnapshot collectorSnapshot = await FirebaseFirestore.instance
        .collection('ambulant_collector')
        .where('email', isEqualTo: email)
        .limit(1) // Limit the query to only get one result
        .get();

    if (collectorSnapshot.docs.isNotEmpty) {
      // Get the first document from the query results
      DocumentSnapshot collectorDoc = collectorSnapshot.docs.first;

      // Retrieve and display the first name and last name
      setState(() {
        var firstName = collectorDoc.get('firstName');
        var lastName = collectorDoc.get('lastName');
        payorController.text = '$firstName $lastName';
      });
    }
  } else {
    print('No user is logged in.');
  }
}

  void _initializeDate() {
    setState(() {
      dateController.text = DateFormat('MM/dd/yyyy').format(DateTime.now());
    });
  }

  void _onNumberOfTicketsChanged(String value) {
    setState(() {
      numberOfTickets = int.tryParse(value) ?? 0; // If input is invalid, default to 0
      _calculateTotalAmount(); // Ensure the total amount is recalculated whenever tickets are changed
    });
  }

  void _incrementNumberOfTickets() {
    setState(() {
      numberOfTickets += 1;
      numberOfTicketsController.text = numberOfTickets.toString();
      _calculateTotalAmount();
    });
  }

  void _decrementNumberOfTickets() {
    if (numberOfTickets > 0) {
      setState(() {
        numberOfTickets -= 1;
        numberOfTicketsController.text = numberOfTickets.toString();
        _calculateTotalAmount();
      });
    }
  }

// Function to calculate the total amount
void _calculateTotalAmount() {
  setState(() {
    // Parse the current values from the controllers
    double ticketRate = feeRates['Ticket Rate'] ?? 0.0; // Now using double directly
    int numberOfTickets = int.tryParse(numberOfTicketsController.text) ?? 0;

    // Calculate total amount
    double totalAmount = ticketRate * numberOfTickets; 
    totalAmountController.text = '₱ ${totalAmount.toStringAsFixed(2)}'; // Display the result
  });
}


String _calculateTotalFees() {
  double totalFees = 0.0;

  // Calculate fees excluding the ticket rate
  feeControllers.forEach((key, controller) {
    if (key != 'Ticket Rate') {
      String value = controller.text.replaceAll('₱ ', '').replaceAll(',', '');
      totalFees += double.tryParse(value) ?? 0.0;
    }
  });

  // Include the total amount in the fees
  double totalAmountValue = double.tryParse(totalAmountController.text.replaceAll('₱ ', '').replaceAll(',', '')) ?? 0.0;
  totalFees += totalAmountValue; // Include total amount in fees

  // Format the total fees with peso sign and two decimal places
  final _calculateTotalFees = NumberFormat.currency(
    locale: 'en_PH', // Locale for Philippines (if needed)
    symbol: '₱',    // Peso sign
    decimalDigits: 2, // Number of decimal places
  ).format(totalFees);

  return _calculateTotalFees;
}

Future<void> _loadFees() async {
  QuerySnapshot rateSnapshot = await FirebaseFirestore.instance.collection('rate').get();
  List<QueryDocumentSnapshot> rateDocuments = rateSnapshot.docs;

  Map<String, String> tempFees = {};

  setState(() {
    for (var doc in rateDocuments) {
      String feeName = doc.get('name');
      
      // Ensure the rate is cast to double regardless of its Firestore type (int or double)
      double feeRate = (doc.get('rate') as num).toDouble(); 

      // Directly use the feeRate from Firestore without parsing multiple times
      tempFees[feeName] = feeRate.toString();

      if (feeName == 'Ticket Rate') {
        ticketRate = feeRate;
        ticketController.text = '₱ ${ticketRate.toStringAsFixed(2)}'; // Set the ticket controller text
      }

      // Only create a new controller if it doesn't exist
      if (!feeControllers.containsKey(feeName) && (feeName == 'Ticket Rate' || feeName == 'Garbage Fee')) {
        feeControllers[feeName] = TextEditingController(text: '₱ ${feeRate.toStringAsFixed(2)}');
        feeLabels[feeName] = feeName;
      }

      feeRates[feeName] = feeRate; // Store the fee rate as double
    }
  });

  _calculateTotalAmount(); // Recalculate total amount after loading fees
}


 void _showAddFeeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        titlePadding: EdgeInsets.zero, // Remove default padding around the title
        title: Container(
          width: double.infinity, // Make the container full-width
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 38, 203, 44), // Header background color
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)), // Rounded top corners
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: const Text(
            'Select a Fee',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white, // Header text color
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounds the dialog itself
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Adjust content padding
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: feeRates.entries
                .where((entry) => !feeControllers.containsKey(entry.key))
                .map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  tileColor: Colors.grey[200], // Light grey background for each item
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '₱ ${entry.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  onTap: () {
                    _addSelectedFee(entry.key, entry.key);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actionsPadding: const EdgeInsets.all(8.0), // Padding for the actions
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 17,
                color: Color.fromARGB(255, 67, 216, 26),
              ),
            ),
          ),
        ],
      );
    },
  );
}


  void _addSelectedFee(String feeName, String feeLabel) {
    setState(() {
      if (!feeControllers.containsKey(feeName)) {
        feeControllers[feeName] = TextEditingController(text: '₱ ${feeRates[feeName]}');
        feeLabels[feeName] = feeLabel;
      }
      _calculateTotalAmount();

    });
  }

  void _removeFee(String feeName) {
    setState(() {
      if (feeControllers.containsKey(feeName)) {
        feeControllers[feeName]?.dispose();
        feeControllers.remove(feeName);

        if (feeName == 'Ticket Rate') {
        ticketController.text = ticketRate.toStringAsFixed(2);

        numberOfTickets = 4;
        numberOfTicketsController.text = numberOfTickets.toString();
        }
      }
      _calculateTotalAmount();

    });
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
          flexibleSpace: const Center( // Center the content
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the text and icon
              mainAxisSize: MainAxisSize.min, // Minimize the space taken by the Row
              children: [
                Icon(Icons.payment_outlined, color: Colors.white), // Icon next to the text
                SizedBox(width: 8), // Space between icon and text
                Text(
                  "Payment Form",
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 4, spreadRadius: 2)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collector Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    color: Color.fromARGB(255, 52, 180, 35),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: payorController,
                  decoration: const InputDecoration(
                    labelText: 'Collector',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date Issued',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 4, spreadRadius: 2)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fee Information',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Roboto',
                        color: Color.fromARGB(255, 52, 180, 35),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showAddFeeDialog(context);
                      },
                      icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                      label: const Text('Add Fee'),
                      style: TextButton.styleFrom(
                      foregroundColor: Colors.white, // Set the text color to white
                      textStyle: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                      backgroundColor: const Color.fromARGB(255, 34, 216, 40), // Button background color
                       ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: feeControllers.entries.map((entry) {
                    String feeName = entry.key;
                    TextEditingController feeController = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: feeController,
                              decoration: InputDecoration(
                                labelText: feeLabels[feeName],
                                border: const OutlineInputBorder(),
                              ),
                              readOnly: true,
                            ),
                          ),
                          if (feeName == 'Ticket Rate') ...[
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3, // Adjust flex to make the field bigger
                            child: Stack(
                              children: [
                                TextField(
                                  controller: numberOfTicketsController,
                                  keyboardType: TextInputType.number,
                                  onChanged: _onNumberOfTicketsChanged,
                                  decoration: const InputDecoration(
                                    labelText: 'Number of Tickets',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 40.0), // Ensure there is enough padding on each side
                                  ),
                                  textAlign: TextAlign.center, // Center the text in the field
                                ),
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 40, // Adjust width to fit the button
                                      child: IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: _decrementNumberOfTickets,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      width: 40, // Adjust width to fit the button
                                      child: IconButton(
                                        icon: const Icon(Icons.add, color: Color.fromARGB(255, 18, 167, 28)),
                                        onPressed: _incrementNumberOfTickets,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3, // Adjust flex to make the field bigger
                            child: TextField(
                              controller: totalAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Total Ticket Amount',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 10,),
                        ],
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeFee(feeName);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary of Payment
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary of Payment',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Roboto',
                  color: Color.fromARGB(255, 52, 180, 35),
                ),
              ),
              const SizedBox(height: 14), // Space below the Summary of Payment text
              ...feeControllers.entries.map((entry) {
                String feeName = entry.key;
                String feeValue = entry.value.text;
                if (feeName == 'Ticket Rate') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ticket Rate:'),
                          Text(feeValue, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Number of Tickets:'),
                          Text(numberOfTicketsController.text, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Ticket Amount:'/* , style: TextStyle(fontWeight: FontWeight.w600) */),
                          Text(totalAmountController.text, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8), // Add spacing between this block and next fee
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(feeLabels[feeName] ?? feeName),
                        Text(feeValue, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8), // Add spacing between each dynamically added fee row
                  ],
                );
              }), 
                const Divider(color: Colors.grey),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Fees:', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15)),
                    Text(_calculateTotalFees().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                String payor = payorController.text;
                String paymentDate = dateController.text;
                String totalFees = _calculateTotalFees();
                Map<String, String> feeSummary = feeControllers.map((key, controller) => MapEntry(key, controller.text)); // Pass the dynamic fee summary

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectVendorsScreen(
                      payor: payor,
                      paymentDate: paymentDate,
                      totalFees: totalFees, 
                      feeSummary: feeSummary,
                      numberOfTickets: numberOfTickets, // Pass number of tickets
                      totalAmount: totalAmountController.text, // Pass total amount
                    ),
                  ),
                );
              },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 34, 216, 40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('Assign Payment'),
                ),
              ),
            ],
          ),
        ),

    );
  }
}

