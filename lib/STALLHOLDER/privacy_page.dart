import 'package:flutter/material.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  _PrivacyPageState createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool isTwoFactorEnabled = false; // Initial state for 2FA

  void toggleTwoFactorAuthentication(bool value) {
    setState(() {
      isTwoFactorEnabled = value;
    });

    // Logic to handle enabling/disabling 2FA can be added here
    if (value) {
      // Implement 2FA enablement logic
      print('Two-Factor Authentication enabled');
    } else {
      // Implement 2FA disablement logic
      print('Two-Factor Authentication disabled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Privacy',
              style: TextStyle(
                  fontSize: 17, color: const Color.fromARGB(255, 234, 91, 91)),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: Text('Enable Two-Factor Authentication'),
            subtitle: Text(
                'Increase the security of your account by requiring a second form of authentication.'),
            value: isTwoFactorEnabled,
            onChanged: toggleTwoFactorAuthentication,
          ),
          Divider(color: Colors.grey),
          // Add more privacy-related settings here
        ],
      ),
    );
  }
}
