import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OffenseMade extends StatelessWidget {
  final String offenseId;

  OffenseMade({required this.offenseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.of(context).pop();
        }
        ),
        title: const Text(
          "Violation Details",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Market_violations').doc(offenseId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading offense details'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Offense not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vendor Name',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['vendorName'],
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const Divider(),
                  const SizedBox(height: 5),
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['stallLocation'],
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const Divider(),
                  const SizedBox(height: 5),
                  const Text(
                    'Stall Number',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['stallNo'],
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const Divider(),
                  const SizedBox(height: 5),
                  const Text(
                    'Warning',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['warning'],
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const Divider(),
                  const SizedBox(height: 5),
                  const Text(
                    'Violation Type',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['violationType'],
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    'Image Uploaded:',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 15),
                  ...List.generate(6, (index) {
                    final imageUrl = data['image_$index'];
                    if (imageUrl != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
