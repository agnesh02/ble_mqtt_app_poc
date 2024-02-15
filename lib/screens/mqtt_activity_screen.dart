// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/viewModels/mqtt_viewmodel.dart';
import 'package:flutter/material.dart';

class MqttActivityScreen extends StatelessWidget {
  MqttActivityScreen({super.key});
  final MqttViewModel mqttViewModel = MqttViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MQTT"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            mqttViewModel.connectMqttClient("admin", "admin123456");
          },
          child: const Text("Connect with the broker"),
        ),
      ),
    );
  }
}
