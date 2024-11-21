import 'package:ambulantcollector/reusable_widgets/reusable_widgets.dart';
import 'package:ambulantcollector/screens/appraisalDashboard.dart';
import 'package:ambulantcollector/screens/collectordashboard.dart';
import 'package:ambulantcollector/screens/reset_password.dart';
import 'package:ambulantcollector/STALLHOLDER/pending_registration.dart';
import 'package:ambulantcollector/STALLHOLDER/stallpage.dart';
import 'package:ambulantcollector/STALLHOLDER/v_dashboard.dart';
import 'package:ambulantcollector/screens/dashboardvendor.dart';
import 'package:ambulantcollector/screens/timeline_screen.dart';
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
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
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
                reusableTextField("Enter Email", Icons.person_outline, false,
                    _emailTextController),
                const SizedBox(height: 20),
                _passwordField(),
                const SizedBox(height: 5),
                forgetPassword(context),
                firebaseUIButton(context, "Sign In", () {
                  _loginUser();
                }),
                TextButton(
                  onPressed: () {
                    // Navigate to vendor registration screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StallPage()),
                    );
                  },
                  child: const Text(
                    "Register as Vendor",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      decoration: TextDecoration
                          .underline, // Add underline for link effect
                      fontSize: 14,
                    ),
                  ),
                ),
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
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Check if the user exists in the appraisal_user collection
        final QuerySnapshot appraisalSnapshot = await FirebaseFirestore.instance
            .collection('appraisal_user')
            .where('email', isEqualTo: email)
            .get();

        if (appraisalSnapshot.docs.isNotEmpty) {
          // User found in appraisal_user
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AppraisalDashboard()),
          );
        } else {
          // Check if the user exists in the ambulant_collector collection
          final QuerySnapshot collectorSnapshot = await FirebaseFirestore
              .instance
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
            // Check if user is in Vendorusers collection (for stallholder login)
            final QuerySnapshot vendorSnapshot = await FirebaseFirestore
                .instance
                .collection('Vendorusers')
                .where('email', isEqualTo: email)
                .get();

            if (vendorSnapshot.docs.isNotEmpty) {
              DocumentSnapshot vendorDoc = vendorSnapshot.docs.first;
              String status = vendorDoc.get('status');

              if (status == 'pending') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegistrationPendingPage()),
                );
              } else {
                // Check approved vendors (for stallholder login)
                final QuerySnapshot approvedVendorSnapshot =
                    await FirebaseFirestore.instance
                        .collection('approvedVendors')
                        .where('email', isEqualTo: email)
                        .get();

                if (approvedVendorSnapshot.docs.isNotEmpty) {
                  // User is an approved vendor, redirect to HomePage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TimelineScreen(userId: vendorDoc.id)),
                  );
                }
              }
            } else {
              // General user logic
              final QuerySnapshot userSnapshot = await FirebaseFirestore
                  .instance
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .get();

              if (userSnapshot.docs.isNotEmpty) {
                final QuerySnapshot approvedVendorSnapshot =
                    await FirebaseFirestore.instance
                        .collection('approved_vendors')
                        .where('email', isEqualTo: email)
                        .get();

                if (approvedVendorSnapshot.docs.isNotEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DashboardVendor()),
                  );
                } else {
                  DocumentSnapshot userDoc = userSnapshot.docs.first;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TimelineScreen(userId: userDoc.id)),
                  );
                }
              } else {
                _showErrorDialog(
                    "User not found in either collectors or vendors.");
              }
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e, email);
    } catch (e) {
      _showErrorDialog("An error occurred: ${e.toString()}");
    }
  }

  void _handleAuthError(FirebaseAuthException error, String email) {
    switch (error.code) {
      case 'user-not-found':
        _showErrorDialog(
            "No user found with this email. Please check your email or sign up.");
        break;
      case 'wrong-password':
        _showErrorDialog("Incorrect password. Please try again.");
        break;
      case 'too-many-requests':
        _showErrorDialog(
            "The login credential is incorrect. Try resetting your password.");
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
                  color: Colors.green,
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
                        color: Colors.green,
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
            MaterialPageRoute(builder: (context) => const ResetPassword()),
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
