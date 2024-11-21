import 'package:ambulantcollector/STALLHOLDER/marketrules_page.dart';
import 'package:ambulantcollector/STALLHOLDER/notification_page.dart';
import 'package:ambulantcollector/STALLHOLDER/privacy_page.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Navigation method
  void navigateToPage(BuildContext context, String page) {
    Widget nextPage;
    switch (page) {
      case 'PrivacyPage':
        nextPage = PrivacyPage();
        break;
      case 'NotificationPage':
        nextPage = NotificationPage();
        break;
      case 'MarketRulesPage':
        nextPage = MarketRulesPage();
        break;
      default:
        nextPage = SettingsPage();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Icon(Icons.settings,
                color: const Color.fromARGB(255, 212, 119, 119)),
            SizedBox(width: 8),
            Text(
              'Settings',
              style: TextStyle(fontSize: 17, color: Colors.white),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          buildSettingsItem(
              context, Icons.privacy_tip, 'Privacy', 'PrivacyPage'),
          buildDivider(),
          buildSettingsItem(
              context, Icons.notifications, 'Notification', 'NotificationPage'),
          buildDivider(),
          buildSettingsItem(context, Icons.rule, 'Market Rules and Regulation',
              'MarketRulesPage'),
        ],
      ),
    );
  }

  // Build list tile item with navigation
  Widget buildSettingsItem(
      BuildContext context, IconData icon, String title, String page) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      onTap: () {
        navigateToPage(context, page); // Call the navigation method
      },
    );
  }

  // Build divider between items
  Widget buildDivider() {
    return Divider(
      color: Colors.black,
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
