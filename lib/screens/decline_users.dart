import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeclinedPage extends StatelessWidget {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  DeclinedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Declined Users"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.where('status', isEqualTo: 'Declined').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final users = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('VENDORS')),
                DataColumn(label: Text('DECLINE MESSAGE')), // Add this column
              ],
              rows: users.map((user) {
                final date = (user['created_at'] as Timestamp).toDate().toString().substring(0, 10);
                final first = user['first_name'];
                final last = user['last_name'];
                final declineMessage = user['decline_message'] ?? 'No message'; // Fetch decline message

                return DataRow(cells: [
                  DataCell(Text(date)),
                  DataCell(Text('$last, $first')),
                  DataCell(Text(declineMessage)), // Display decline message
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
