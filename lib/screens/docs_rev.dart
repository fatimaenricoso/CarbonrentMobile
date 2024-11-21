import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewDocsScreen extends StatefulWidget {
  final String vendorId;

  const ReviewDocsScreen({Key? key, required this.vendorId}) : super(key: key);

  @override
  _ReviewDocsScreenState createState() => _ReviewDocsScreenState();
}

class _ReviewDocsScreenState extends State<ReviewDocsScreen> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  // Method to update the status
  void updateStatus(String status) async {
    try {
      await usersRef.doc(widget.vendorId).update({'status': status});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      Navigator.pop(context, 'Status updated to $status');
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating status')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Vendor Application"),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: usersRef.doc(widget.vendorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Vendor not found"));
          }

          final vendor = snapshot.data!;
          final contactNumber = vendor['contact_number'] ?? 'N/A';
          final createdAt = vendor['created_at']?.toDate().toString() ?? 'N/A';
          final email = vendor['email'] ?? 'N/A';
          final firstName = vendor['first_name'] ?? 'N/A';
          final lastName = vendor['last_name'] ?? 'N/A';
          final username = vendor['username'] ?? 'N/A';
          final documents = vendor['documents'] ?? []; // Assume 'documents' is a list of document URLs or file names

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("First Name: $firstName", style: const TextStyle(fontSize: 18)),
                Text("Last Name: $lastName", style: const TextStyle(fontSize: 18)),
                Text("Username: $username", style: const TextStyle(fontSize: 18)),
                Text("Email: $email", style: const TextStyle(fontSize: 18)),
                Text("Contact Number: $contactNumber", style: const TextStyle(fontSize: 18)),
                Text("Created At: $createdAt", style: const TextStyle(fontSize: 18)),
                const Text("Documents:", style: TextStyle(fontSize: 18)),
                ...documents.map<Widget>((doc) => Text(doc, style: const TextStyle(fontSize: 16, color: Colors.blue))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => updateStatus('Added'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Approve'),
                    ),
                    ElevatedButton(
                      onPressed: () => updateStatus('Declined'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Decline'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
