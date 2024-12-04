import 'package:ambulantcollector/reusable_widgets/reusable_widgets.dart';
import 'package:ambulantcollector/screens/StallDashboard.dart';
import 'package:ambulantcollector/screens/appraisalDashboard.dart';
import 'package:ambulantcollector/screens/collectordashboard.dart';
import 'package:ambulantcollector/screens/reset_password.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({Key? key}) : super(key: key);

  @override
  _UnifiedLoginScreenState createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();

  bool _isPasswordVisible = false; // To track password visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "WELCOME TO\n",
                        style: TextStyle(
                          fontSize: 40,
                          color: Color.fromARGB(255, 16, 16, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "CARBONRENT\n\n",
                        style: TextStyle(
                          fontSize: 40,
                          color: Color.fromARGB(255, 60, 218, 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                reusableTextField("Enter Email", Icons.person_outline, false, _emailTextController),
                const SizedBox(height: 20),
                _passwordField(),
                const SizedBox(height: 5),
                forgetPassword(context),
                firebaseUIButton(context, "Sign In", () {
                  _loginUser();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom Password Field with Toggle Visibility Icon
  Widget _passwordField() {
    return TextField(
      controller: _passwordTextController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: "Enter Password",
        labelStyle: const TextStyle(color: Colors.black),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(
            width: 2,
            color: Color.fromARGB(255, 60, 218, 28),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }

  void _loginUser() async {
    final email = _emailTextController.text.trim();
    final password = _passwordTextController.text.trim();

    // Check for empty fields
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Email and password cannot be empty.");
      return;
    }

    try {
      // Sign in using Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Check if the user exists in the admin_users collection
        final QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
            .collection('admin_users')
            .where('email', isEqualTo: email)
            .get();

        if (adminSnapshot.docs.isNotEmpty) {
          // User found in admin_users
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StallDashboard()),
          );
          return;
        }

        // Check if the user exists in the appraisal_user collection
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('appraisal_user')
            .where('email', isEqualTo: email)
            .get();

        if (snapshot.docs.isNotEmpty) {
          // User found in appraisal_user
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AppraisalDashboard()),
          );
        } else {
          // Check if the user exists in the ambulant_collector collection
          final QuerySnapshot collectorSnapshot = await FirebaseFirestore.instance
              .collection('ambulant_collector')
              .where('email', isEqualTo: email)
              .get();

          if (collectorSnapshot.docs.isNotEmpty) {
            // User found in ambulant_collector
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          } else {
            _showErrorDialog("User is not registered.");
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors
      _handleAuthError(e, email);
    } catch (e) {
      // Handle any other errors
      _showErrorDialog("An error occurred: ${e.toString()}");
    }
  }

  void _handleAuthError(FirebaseAuthException error, String email) {
    switch (error.code) {
      case 'user-not-found':
        _showErrorDialog("No user found with this email. Please check your email or sign up.");
        break;
      case 'wrong-password':
        _showErrorDialog("Incorrect password. Please try again.");
        break;
      case 'too-many-requests':
        _showErrorDialog("The login credential is incorrect. Try resetting your password.");
        break;
      default:
        _showErrorDialog("${error.message}");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          width: 300,
          height: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 60, 218, 28),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: const Text(
                  "Login Error",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Color.fromARGB(255, 60, 218, 28),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
          );
        },
        child: const Text(
          "Forgot Password?",
          style: TextStyle(color: Colors.black, fontSize: 14),
        ),
      ),
    );
  }
}
