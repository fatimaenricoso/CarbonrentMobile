import 'package:ambulantcollector/firebase_option.dart';
import 'package:ambulantcollector/screens/dashboardvendor.dart';
import 'package:ambulantcollector/screens/unifiedloginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const bool USE_EMULATOR = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
/*   FirebaseAnalytics analytics = FirebaseAnalytics.instance;
 */

  // Load the .env file
  try {
    await dotenv.load(fileName: ".env"); // Load your .env file
  } catch (e) {
    print('Error loading .env file: $e');
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());

/* void main() async {
/*   await dotenv.load(fileName: ".env"); // Load your .env file
 */  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
 */
  // Connect to Firebase Emulator if USE_EMULATOR is true
  if (USE_EMULATOR) {
    await _connectToFirebaseEmulator();
  }

  runApp(const MyApp());
}

Future<void> _connectToFirebaseEmulator() async {
  const String localHostString = '10.0.2.2'; // Use this for Android Emulator
  FirebaseFirestore.instance.settings = const Settings(
    host: '$localHostString:8080',
    sslEnabled: false,
    persistenceEnabled: false,
  );

  FirebaseAuth.instance
      .useAuthEmulator(localHostString, 9099); // Updated method
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable the debug banner
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  UnifiedLoginScreen(),
      routes: {
        '/dashboardVendor': (_) => DashboardVendor(),
      },
    );
  }
}

class ResetPassword extends StatefulWidget {
  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _handleIncomingLink();
  }

  void _handleIncomingLink() async {
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    _processDynamicLink(data);

    FirebaseDynamicLinks.instance.onLink
        .listen((PendingDynamicLinkData dynamicLink) {
      _processDynamicLink(dynamicLink);
    }).onError((error) {
      print('onLink error: $error');
    });
  }

  void _processDynamicLink(PendingDynamicLinkData? data) async {
    final Uri? deepLink = data?.link;

    if (deepLink != null && _auth.isSignInWithEmailLink(deepLink.toString())) {
      // Get the email from SharedPreferences or other local storage
      final String email =
          'your_stored_email@example.com'; // Replace with your logic to retrieve the stored email

      // Complete sign-in
      try {
        await _auth.signInWithEmailLink(
            email: email, emailLink: deepLink.toString());
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully signed in!')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error signing in: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
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

  void _sendSignInLink() async {
    final String email = _emailController.text.trim();

    if (email.isNotEmpty) {
      // Construct ActionCodeSettings
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: 'https://www.example.com/finishSignUp',
        handleCodeInApp: true,
        androidPackageName: 'com.example.android',
        iOSBundleId: 'com.example.ios',
        dynamicLinkDomain: 'example.page.link',
      );

      // Send sign-in link
      try {
        await _auth.sendSignInLinkToEmail(
          email: email, // Provide the email as a named argument
          actionCodeSettings:
              actionCodeSettings, // Provide ActionCodeSettings as a named argument
        );

        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in link sent to $email.')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
