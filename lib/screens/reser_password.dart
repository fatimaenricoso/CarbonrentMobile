import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPassword extends StatefulWidget {
  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendSignInLink() async {
    final String email = _emailController.text.trim();

    if (email.isNotEmpty) {
      // Construct ActionCodeSettings
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: 'https://www.example.com/finishSignUp',
        handleCodeInApp: true,
        androidPackageName: 'com.example.android',
        iOSBundleId: 'com.example.ios',
        dynamicLinkDomain: 'ambulantcollector.page.link',
      );

      // Send sign-in link
      try {
        await _auth.sendSignInLinkToEmail(
          email: email, // Provide the email as a named argument
          actionCodeSettings: actionCodeSettings, // Provide ActionCodeSettings as a named argument
        );

        // Save email locally (e.g., SharedPreferences)
        // For simplicity, we just show a message here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in link sent to $email.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Email Link')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendSignInLink,
              child: const Text('Send Sign-In Link'),
            ),
          ],
        ),
      ),
    );
  }
}
