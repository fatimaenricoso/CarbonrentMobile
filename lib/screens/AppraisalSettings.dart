import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Appraisalsettings extends StatelessWidget {
  const Appraisalsettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
/*       appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
/*             Icon(Icons.settings, color: Colors.white),
 */            SizedBox(width: 0),
            Text("Settings", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
/*         centerTitle: true,
 */      ), */
 /* appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Row(
          children: [
            SizedBox(width: 8), // Add some space between the back button and the text
            Text(
              "Settings",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
      ), */
      appBar: AppBar(
        leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.of(context).pop();
        }
        ),
        title: const Text(
          "Settings ",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text("Security"),
              subtitle: const Text("Change password"),
              onTap: () {
                _showChangePasswordDialog(context);
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              titlePadding: const EdgeInsets.all(0),
              title: Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                width: double.maxFinite,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(13.0),
                  ),
                ),
                child: const Text(
                  "CHANGE PASSWORD",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureCurrentPassword = !obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: obscureCurrentPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: newPasswordController,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: obscureNewPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: "Confirm New Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: obscureConfirmPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                SizedBox(
                  width: 85,
                  height: 33,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _changePassword(
                        context,
                        currentPasswordController.text,
                        newPasswordController.text,
                        confirmPasswordController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text("Save"),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changePassword(
    BuildContext context,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog(context, "No user is logged in.");
      return;
    }

    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);

      if (newPassword != confirmPassword) {
        _showErrorDialog(context, "New passwords do not match.");
        return;
      }

      await user.updatePassword(newPassword);
      Navigator.of(context).pop();
      _showSuccessDialog(context, "Password changed successfully.");
    } catch (error) {
      _showErrorDialog(context, "Failed to change password. Please check the current password or try again.");
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
