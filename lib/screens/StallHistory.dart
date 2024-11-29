import 'package:flutter/material.dart';

class StallHistory extends StatelessWidget {
  const StallHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text("History Screen"),
      ),
    );
  }
}
