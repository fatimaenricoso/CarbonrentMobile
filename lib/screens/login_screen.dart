import 'package:ambulantcollector/reusable_widgets/reusable_widgets.dart';
import 'package:ambulantcollector/screens/dashboardvendor.dart';
import 'package:ambulantcollector/screens/reser_password.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LogInScreen extends StatefulWidget {


  const LogInScreen({Key? key, }) : super(key: key); // Constructor

  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
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
                        text: "WELCOME TO\n", // First part
                        style: TextStyle(
                          fontSize: 40,
                          color: Color.fromARGB(255, 16, 16, 16), // Color for "WELCOME TO"
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "CARBONRENT\n\n", // Second part
                        style: TextStyle(
                          fontSize: 40,
                          color: Color.fromARGB(255, 60, 218, 28), // Color for "CARBONRENT" (change to desired color)
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                reusableTextField("Enter Email", Icons.person_outline, false,
                    _emailTextController),
                const SizedBox(
                  height: 20,
                ),
                _passwordField(),
                const SizedBox(
                  height: 5,
                ),
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
      obscureText: !_isPasswordVisible, // Toggle obscure text
      decoration: InputDecoration(
        labelText: "Enter Password",
        labelStyle: const TextStyle(
          color: Colors.black, // Change label text color to black
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible; // Toggle the visibility
            });
          },
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(
            width: 2,
            color: Color.fromARGB(255, 60, 218, 28), // Green border color when focused
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 0, 0, 0), // Lighter green border color when not focused
          ),
        ),
      ),
      style: const TextStyle(
        color: Colors.black, // Change the text color to black
      ),
    );
  }

/*  void _loginUser() async {
  final email = _emailTextController.text.trim();
  final password = _passwordTextController.text.trim();

  // Check for empty fields
  if (email.isEmpty || password.isEmpty) {
    _showErrorDialog("Email and password cannot be empty.");
    return;
  }

  // Fetch profile from 'ambulant_collector' to check email and password
  final QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('ambulant_collector')
      .where('email', isEqualTo: email)
      .where('password', isEqualTo: password) // Check if the password matches
      .get();

  if (snapshot.docs.isNotEmpty) {
    // If a matching profile is found, navigate to Dashboard
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Dashboard()),
    );
  } else {
    _showErrorDialog("Invalid email or password.");
  }
}
 */

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

    // If login is successful, check in the ambulant_collector collection
    if (userCredential.user != null) {
      // Check if the user exists in the ambulant_collector collection
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ambulant_collector')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // User found in ambulant_collector
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardVendor()),
        );
      } else {
        // User not found in ambulant_collector
        _showErrorDialog("User is not registered as an ambulant collector.");
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
          borderRadius: BorderRadius.circular(20.0), // Curved edges for the dialog
        ),
        child: Container(
          width: 300, // Set a fixed width for the dialog
          height: 200, // Increased height for more space
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use minimum size for content
            children: [
              Container(
                width: double.infinity, // Header fills the width of the dialog
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 60, 218, 28), // Green background for the header
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0), // Match the dialog's top left
                    topRight: Radius.circular(20.0), // Match the dialog's top right
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0), // Adjusted padding for header
                child: const Text(
                  "Login Error",
                  textAlign: TextAlign.center, // Center text for a professional look
                  style: TextStyle(
                    color: Colors.white, // White text for contrast
                    fontSize: 20,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0), // Uniform padding for content
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center, // Center align message for a balanced look
                ),
              ),
              const SizedBox(height: 20), // Add space before the button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Side padding for button
                child: Align(
                  alignment: Alignment.bottomRight, // Align the button to the bottom right
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Color.fromARGB(255, 60, 218, 28), // Green text for the button
                        fontWeight: FontWeight.bold,
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
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Forgot Password?",
              style: const TextStyle(
                color: Color.fromARGB(255, 60, 218, 28),
                decoration: TextDecoration.underline, // Optional: underline to indicate link
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  ResetPassword()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}
