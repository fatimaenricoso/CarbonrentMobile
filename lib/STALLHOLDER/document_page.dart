import 'package:flutter/material.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Icon(Icons.folder, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Documents',
              style: TextStyle(
                  fontSize: 17,
                  color: const Color.fromARGB(255, 248, 221, 221)),
            ),
          ],
        ),
      ),
      body: Center(child: Text('Documents Page')),
    );
  }
}
