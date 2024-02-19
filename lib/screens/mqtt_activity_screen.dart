// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/providers/connectivity_provider.dart';
import 'package:ble_mqtt_app/providers/mqtt_providers.dart';
import 'package:ble_mqtt_app/viewModels/mqtt_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/credentials_form.dart';
import 'package:ble_mqtt_app/widgets/custom_snack.dart';
import 'package:ble_mqtt_app/widgets/message_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttActivityScreen extends ConsumerWidget {
  MqttActivityScreen({super.key});
  final MqttViewModel mqttViewModel = MqttViewModel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConnectionStatus = ref.watch(mqttConnectionProvider);
    final availableMessages = ref.watch(mqttMessagesProvider);
    final isConnected = ref.watch(connectivityProvider);

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
      body: !isConnected
          ? const Center(
              child: Text(
                "You are currently disconnected :(\nConnect to a network !!",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : currentConnectionStatus == MqttConnectionState.connected
              ? MessageWindow(
                  messages: availableMessages,
                  mqttViewModel: mqttViewModel,
                )
              : Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 250,
                    child: CredentialsForm(
                      mqttViewModel: mqttViewModel,
                      onSubmitted: (username, password) async {
                        showDialog(
                            context: context,
                            builder: (cntxt) {
                              return showConnectingDialog();
                            });
                        // mqttViewModel.connectMqttClient("admin", "admin123456");
                        await mqttViewModel
                            .connectMqttClient(ref, username, password)
                            .then((isSuccess) {
                          Navigator.of(context).pop();
                          customSnackBar(
                            context,
                            isSuccess
                                ? "Hey, you can start chatting now :)"
                                : "Connection failed. Please recheck the credentials... :(",
                          );
                        });
                      },
                    ),
                  ),
                ),
    );
  }

  AlertDialog showConnectingDialog() {
    return const AlertDialog(
      title: Text(
        'Connecting with the broker...',
      ),
      content: SizedBox(
        width: 150,
        height: 150,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 105, vertical: 48),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
