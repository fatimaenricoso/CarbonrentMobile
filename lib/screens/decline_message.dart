import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeclineMessageScreen extends StatefulWidget {
  final String vendorId;
  final VoidCallback onMessageSent;

  const DeclineMessageScreen({Key? key, required this.vendorId, required this.onMessageSent}) : super(key: key);

  @override
  _DeclineMessageScreenState createState() => _DeclineMessageScreenState();
}

class _DeclineMessageScreenState extends State<DeclineMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  void sendDeclineMessage() async {
    String message = _messageController.text.trim();

    if (message.isNotEmpty) {
      try {
        // Update Firestore with the decline message and status
        await usersRef.doc(widget.vendorId).update({
          'decline_message': message,
          'status': 'Declined'
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Decline message sent')));
        widget.onMessageSent(); // Notify Vendor screen to refresh state
        Navigator.pop(context, true); // Return to the previous screen with success result
      } catch (e) {
        print('Error sending decline message: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending decline message')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Decline Message"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Decline Message",
                hintText: "Enter the reason for declining the vendor application",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendDeclineMessage,
              child: const Text("Send Message"),
            ),
          ],
        ),
      ),
    );
  }
}
