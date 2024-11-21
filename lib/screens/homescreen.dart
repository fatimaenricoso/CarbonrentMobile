import 'package:ambulantcollector/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // Set the background color of the screen to green
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(5, 58, 5, 1), // Set the background color of the button to white
          ),
          child: const Text(
            "Get Started",
            style: TextStyle(
              color: Color.fromARGB(255, 232, 228, 228), // Set the text color of the button to black
              
            ),
          ),
          onPressed: () {
            FirebaseAuth.instance.signOut().then((value) {
              print("Proceed to Sign In");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogInScreen()),
              );
            });
          },
        ),
      ),
    );
  }
}
