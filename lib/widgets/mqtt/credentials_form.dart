import 'package:ble_mqtt_app/providers/mqtt/connectivity_provider.dart';
import 'package:ble_mqtt_app/viewModels/mqtt_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/common/custom_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: must_be_immutable
class CredentialsForm extends ConsumerWidget {
  CredentialsForm({
    super.key,
    required this.mqttViewModel,
    required this.onSubmitted,
  });

  final MqttViewModel mqttViewModel;
  final _formKey = GlobalKey<FormState>();
  String _username = "";
  String _password = "";
  final void Function(String username, String password) onSubmitted;

  void onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    onSubmitted(_username, _password);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectivityProvider);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(),
              label: Text("Username"),
            ),
            validator: (value) {
              if (value!.trim().isEmpty) {
                return "This field should not be empty";
              }
              return null;
            },
            onSaved: (newValue) => _username = newValue!,
          ),
          const SizedBox(height: 10),
          TextFormField(
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.password),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(),
              label: Text("Password"),
            ),
            validator: (value) {
              if (value!.trim().isEmpty) {
                return "This field should not be empty";
              }
              return null;
            },
            onSaved: (newValue) => _password = newValue!,
          ),
          const SizedBox(height: 25),
          Center(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Colors.purple,
                ), // Specify the border color here
              ),
              onPressed: () {
                if (!isConnected) {
                  customSnackBar(context, "Please connect to a network");
                  return;
                }
                onSubmit();
              },
              child: const Text("CONNECT"),
            ),
          ),
        ],
      ),
    );
  }
}
