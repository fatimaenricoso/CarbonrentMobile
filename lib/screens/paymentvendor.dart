import 'dart:convert';

import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentInfoScreen extends StatefulWidget {
  @override
  _PaymentInfoScreenState createState() => _PaymentInfoScreenState();
}

class _PaymentInfoScreenState extends State<PaymentInfoScreen> {
  User? currentUser;
  Map<String, dynamic>? paymentInfo;
  bool isLoading = true;
  String? documentIDasReferenceID;

  @override
  void initState() {
    super.initState();
    getUserPaymentInfo();
  }

  Future<void> getUserPaymentInfo() async {
    try {
      // Get the current user
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Use the current user's UID as the vendor ID (document ID in approved_vendors)
        String vendorId = currentUser!.uid;
        print('Vendor ID (document ID): $vendorId');

        // Fetch payment information from the 'payments' collection using the vendor ID (which is the document ID in approved_vendors)
        QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
            .collection('payments')
            .where('vendor_id', isEqualTo: vendorId)
            .get();

        if (paymentSnapshot.docs.isNotEmpty) {
          print('Payment found for vendor ID: $vendorId');
          DocumentSnapshot paymentDocument = paymentSnapshot.docs.first;
          documentIDasReferenceID = paymentDocument.id; // Get the document ID
          print('Document ID as reference ID: $documentIDasReferenceID');

          setState(() {
            paymentInfo =
                paymentSnapshot.docs.first.data() as Map<String, dynamic>?;
            isLoading = false;
          });
        } else {
          print('No payment information found for vendor ID: $vendorId');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('No user logged in');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching payment info: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> processPayment(String clientKey) async {
    try {
      // Construct the PayMongo payment URL for GCash
      final url = Uri.parse('https://api.paymongo.com/v1/payment_methods');
      const String apiKey =
          'sk_test_UWP3hXVRoBAk4GuH8Q85Dvrk'; // Replace with your actual PayMongo API key

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'attributes': {
              'type': 'gcash',
              'details': {
                'amount': paymentInfo!['total_amount'],
                'currency': 'PHP',
              },
              'client_key':
                  clientKey, // Use the client_key from the payment intent
            },
          },
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Redirect to GCash payment page
        final paymentUrl =
            responseData['data']['attributes']['redirect']['checkout_url'];
        if (paymentUrl != null) {
          // Open the GCash payment page in a browser
          await launch(paymentUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Payment processing error: No redirect URL.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Payment failed: ${responseData['errors'][0]['detail']}')),
        );
      }
    } catch (e) {
      print('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment processing failed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Information'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const UnifiedLoginScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : paymentInfo != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payor: ${paymentInfo!['payor']}'),
                      SizedBox(height: 10),
                      Text(
                          'Garbage Fee: ${paymentInfo!['fee_summary']['Garbage Fee']}'),
                      SizedBox(height: 10),
                      Text(
                          'Ticket Rate: ${paymentInfo!['fee_summary']['Ticket Rate']}'),
                      SizedBox(height: 10),
                      Text(
                          'Number of Tickets: ${paymentInfo!['number_of_tickets']}'),
                      SizedBox(height: 10),
                      Text('Total Fees: ${paymentInfo!['total_fees']}'),
                      SizedBox(height: 10),
                      Text('Total Amount: ${paymentInfo!['total_amount']}'),
                      SizedBox(height: 10),
                      Text('Payment Date: ${paymentInfo!['payment_date']}'),
                      SizedBox(height: 10),
                      Text('Payment Status: ${paymentInfo!['status']}'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: paymentInfo!['status'] == 'Pending'
                            ? () {
                                paymentCheckout();
                                // processPayment(
                                //     paymentInfo!['payment_intent_client_key']);
                              }
                            : null, // Disable if the status is not 'Pending'
                        child: Text('Pay Now'),
                      ),
                    ],
                  ),
                )
              : Center(child: Text('No payment information found.')),
    );
  }

  void paymentCheckout() async {
    // _violationFinesList.violationFines.forEach((item) {
    //   violationList.add({
    //     'name': item.name,
    //     'quantity': item.quantity,
    //     'amount': int.parse(item.amountInCentavos + '00'),
    //     'currency': item.currency,
    //     'description': item.description,
    //   });
    // });
    final url = Uri.parse('https://api.paymongo.com/v1/checkout_sessions');
    const credentials =
        'Basic c2tfdGVzdF9VV1AzaFhWUm9CQWs0R3VIOFE4NUR2cms6YzJ0ZmRHVnpkRjlWVjFBemFGaFdVbTlDUVdzMFIzVklPRkU0TlVSMmNtczY='; // Replace with actual credentials
    final body = {
      'data': {
        'type': 'checkout_session',
        'attributes': {
          'success_url':
              'https://redirecting-flutter-checkout-paymongo.netlify.app/',
          'cancel_url':
              'https://redirecting-flutter-checkout-paymongo.netlify.app/',
          'payment_method_allowed': ['card', 'gcash', 'grab_pay', 'paymaya'],
          'payment_method_options': {
            'card': {'request_three_d_secure': 'any'}
          },
          'payment_method_types': [
            // 'card',
            'gcash',
            // 'grab_pay',
            // 'paymaya',
          ],
          'description': 'Traffic Vioations',
          'line_items': [
            {
              'name': 'Test Item',
              'quantity': 1,
              'amount': (double.parse(paymentInfo!['total_fees']
                          .replaceAll(RegExp(r'[^\d.]'), '')) *
                      100)
                  .toInt(),
              'currency': 'PHP',
              // 'description': 'J-walking',
            },
            // {
            //   'name': 'No Stopping',
            //   'quantity': 1,
            //   'amount':
            //       3000, // Amount in centavos (2000 centavo = 20 pesos) CANNOT RBE LESS THAN 2000
            //   'currency': 'PHP',
            //   'description': 'No Stopping',
            // }
          ],
          'billing': {
            'name': paymentInfo!['payor'],
            // 'email': 'edilbertjagimit02@gmail.com',
            // 'phone': '9703583334',
            // 'address': {
            //   'line1': 'Tungkil',
            //   'line2': 'Deca Homes',
            //   'city': 'Minglanilla',
            //   'state': 'Cebu',
            //   'postal_code': '6046',
            //   'country': 'PH',
            // },
          },
          "reference_number": documentIDasReferenceID,
          'statement_descriptor':
              'string', // Replace with your desired statement descriptor
        }
      }
    };

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': credentials,
    };

    final response =
        await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      print(response.body);
      var responseBody = jsonDecode(response.body);
      print(responseBody);
      print('Checkout Session ID: ${responseBody['data']['id']}');
      var checkoutURL =
          Uri.parse(responseBody['data']['attributes']['checkout_url']);
      // Using the checkout_session.payment.paid webhooks = ['data']['attributes']['data']['attributes']['payments']['attributes']['status']
      print(checkoutURL);
      if (await canLaunchUrl(checkoutURL)) {
        await launchUrl(
          checkoutURL,
          mode: LaunchMode.externalApplication,
          // mode: LaunchMode.inAppWebView,
        );
      } else {
        throw 'Could not launch $checkoutURL';
      }
    } else {
      print('Error: ${response.body}');
    }
  }
}
