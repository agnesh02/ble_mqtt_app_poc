// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/providers/mqtt_providers.dart';
import 'package:ble_mqtt_app/viewModels/mqtt_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/message_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttActivityScreen extends ConsumerWidget {
  MqttActivityScreen({super.key});
  final MqttViewModel mqttViewModel = MqttViewModel();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConnectionStatus = ref.watch(mqttConnectionProvider);
    final availableMessages = ref.watch(mqttMessagesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            mqttViewModel.mqttClient!.disconnect();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text("MQTT"),
      ),
      body: currentConnectionStatus == MqttConnectionState.connecting
          ? connectingWindow()
          : currentConnectionStatus == MqttConnectionState.connected
              ? MessageWindow(
                  messages: availableMessages,
                  mqttViewModel: mqttViewModel,
                )
              : credentialsWidget(ref),
    );
  }

  Widget connectingWindow() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget credentialsWidget(WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(),
              label: Text("Username"),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.password),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(),
              label: Text("Password"),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Center(
          child: ElevatedButton(
            onPressed: () {
              // mqttViewModel.connectMqttClient("admin", "admin123456");
              mqttViewModel.connectMqttClient(
                ref,
                _usernameController.text.trim(),
                _passwordController.text.trim(),
              );
            },
            child: const Text("Connect with the broker"),
          ),
        ),
      ],
    );
  }
}
