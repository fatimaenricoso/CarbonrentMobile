import 'dart:convert';

import 'package:http/http.dart' as http;

class PayMongoService {
  final String apiKey = 'sk_test_UWP3hXVRoBAk4GuH8Q85Dvrk'; // Replace with your PayMongo API key

Future<Map<String, dynamic>> createPaymentIntent(double amount) async {
  final String url = 'https://api.paymongo.com/v1/payment_intents';
  
  final response = await http.post(
    Uri.parse(url), // your API endpoint
    headers: {
      'accept': 'application/json',
      'authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:'))}', // Encode your API key
      'content-type': 'application/json',
    },
    body: json.encode({
      "data": {
        "attributes": {
          "amount": (amount * 100).toInt(), // Amount in cents (convert to cents)
          "payment_method_allowed": [
            "gcash" // Only GCash as the allowed payment method
          ],
          "payment_method_options": {
            "gcash": {
              // You can add GCash specific options here if needed
            }
          },
          "currency": "PHP",
          "capture_type": "automatic"
        }
      }
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body); // Parse the response
  } else {
    print('Failed to create payment intent: ${response.body}'); // Log error details
    throw Exception('Failed to create payment intent: ${response.body}');
  }
}
}