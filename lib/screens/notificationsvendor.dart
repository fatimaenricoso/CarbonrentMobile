import 'package:flutter/material.dart';

class NotificationsVendorScreen extends StatelessWidget {
  const NotificationsVendorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: const Center(child: Text("Notifications Screen")),
    );
  }
}
