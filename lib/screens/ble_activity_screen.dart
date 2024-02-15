import 'package:flutter/material.dart';

class BleActivityScreen extends StatelessWidget {
  const BleActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE"),
      ),
      body: const Center(
        child: Text("BLE Screen"),
      ),
    );
  }
}
