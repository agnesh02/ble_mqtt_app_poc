// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/providers/mqtt/connectivity_provider.dart';
import 'package:ble_mqtt_app/providers/mqtt/mqtt_providers.dart';
import 'package:ble_mqtt_app/utils/mqtt/network_manager.dart';
import 'package:ble_mqtt_app/viewModels/mqtt_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/common/custom_snack.dart';
import 'package:ble_mqtt_app/widgets/mqtt/credentials_form.dart';
import 'package:ble_mqtt_app/widgets/mqtt/message_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttActivityScreen extends ConsumerStatefulWidget {
  const MqttActivityScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MqttActivityScreen> createState() => _MqttActivityScreenState();
}

class _MqttActivityScreenState extends ConsumerState<MqttActivityScreen> {
  final MqttViewModel mqttViewModel = MqttViewModel();

  @override
  void initState() {
    super.initState();
    NetworkManager().init(ref, context);
  }

  @override
  Widget build(BuildContext context) {
    final currentConnectionStatus = ref.watch(mqttConnectionProvider);
    final availableMessages = ref.watch(mqttMessagesProvider);
    final isConnected = ref.watch(connectivityProvider);
    final nickName = ref.watch(nickNameProvider);

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
          : currentConnectionStatus == MqttConnectionState.connected &&
                  nickName != ""
              ? MessageWindow(
                  messages: availableMessages,
                  mqttViewModel: mqttViewModel,
                  nickName: ref.read(nickNameProvider),
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
                          builder: (cntxt) => connectingDialog(),
                        );
                        await mqttViewModel
                            .connectMqttClient(ref, username, password)
                            .then((isSuccess) {
                          Navigator.of(context).pop();
                          if (isSuccess) {
                            showDialog(
                              context: context,
                              builder: (cntxt) =>
                                  addUserInfoDialog(context, ref),
                            );
                          } else {
                            customSnackBar(
                              context,
                              "Connection failed. Please recheck the credentials... :(",
                            );
                          }
                        });
                      },
                    ),
                  ),
                ),
    );
  }

  /// Function which returns an alert dialog and let the user wait while a connection attempt is made to the broker
  AlertDialog connectingDialog() {
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

  /// Function which returns an alert dialog which is shown to the user to enter a nickname and proceed to chatting
  AlertDialog addUserInfoDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    String nickName = "";

    void onSubmit() {
      if (!formKey.currentState!.validate()) {
        return;
      }
      formKey.currentState!.save();
      ref.read(nickNameProvider.notifier).state = nickName;
      Navigator.of(context).pop();
      customSnackBar(context, "Hey, you can start chatting now :)");
    }

    return AlertDialog(
      title: const Text(
        'What do you want to be called ?',
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Form(
          key: formKey,
          child: TextFormField(
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(10),
              border: OutlineInputBorder(),
              label: Text("Nickname"),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field cannot be empty';
              } else if (value.length > 5) {
                return 'You cannot have more than 5 characters';
              }
              return null;
            },
            onSaved: (newValue) => nickName = newValue!.trim(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => onSubmit(),
          child: const Text("Enter chat room"),
        ),
      ],
    );
  }
}
