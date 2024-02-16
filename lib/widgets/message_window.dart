import 'package:ble_mqtt_app/models/message.dart';
import 'package:ble_mqtt_app/viewModels/mqtt_viewmodel.dart';
import 'package:flutter/material.dart';

class MessageWindow extends StatelessWidget {
  const MessageWindow({
    super.key,
    required this.messages,
    required this.mqttViewModel,
  });

  final List<String> messages;
  final MqttViewModel mqttViewModel;
  static final _formKey = GlobalKey<FormState>();
  static String _enteredMessage = "";

  void submitForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    FocusScope.of(context).unfocus();
    _formKey.currentState!.reset();

    final newMessage =
        Message(messenger: Messenger.local, message: _enteredMessage);
    mqttViewModel.publishToTopics(
      "${newMessage.messenger}: ${newMessage.message}",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 40),
            child: Container(
              height: 450,
              decoration: BoxDecoration(
                border: Border.all(width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: messages.isEmpty
                  ? const Center(
                      child: Text("Start chatting..."),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (cntxt, index) {
                          TextAlign alignment = TextAlign.left;
                          if (messages[index].contains("local")) {
                            alignment = TextAlign.right;
                          }
                          return Text(messages[index], textAlign: alignment);
                        },
                      ),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 35),
          child: Form(
            key: _formKey,
            child: TextFormField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                label: const Text("Message"),
                suffixIcon: IconButton(
                  onPressed: () => submitForm(context),
                  icon: const Icon(Icons.send),
                ),
              ),
              validator: (value) {
                if (value!.trim().isEmpty) {
                  return "Type something";
                }
                return null;
              },
              onSaved: (value) {
                _enteredMessage = value!.trim();
              },
            ),
          ),
        )
      ],
    );
  }
}
