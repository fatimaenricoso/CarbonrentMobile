import 'package:flutter/material.dart';

class MarketRulesPage extends StatelessWidget {
  const MarketRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Icon(Icons.payment, color: const Color.fromARGB(255, 224, 53, 53)),
            SizedBox(width: 8),
            Text(
              'Market Rules',
              style: TextStyle(fontSize: 17, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
