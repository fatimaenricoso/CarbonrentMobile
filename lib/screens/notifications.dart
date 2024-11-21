import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), // Back icon with white color
            onPressed: () {
              Navigator.of(context).pop(); // Navigate back to the previous screen
            },
          ),
          title: const Text(""), // Empty title to avoid spacing issues
          flexibleSpace: const Center( // Center the content
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the text and icon
              mainAxisSize: MainAxisSize.min, // Minimize the space taken by the Row
              children: [
                Icon(Icons.notifications, color: Colors.white), // Icon next to the text
                SizedBox(width: 8), // Space between icon and text
                Text(
                  "Notifications",
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
      body: const Center(
        child:  Text("Notifications Screen"),
      ),
    );
  }
}
