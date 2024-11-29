import 'package:flutter/material.dart';

class StallPending extends StatelessWidget {
  const StallPending({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending"),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text("Pending Screen"),
      ),
    );
  }
}

