import 'package:ble_mqtt_app/models/message.dart';
import 'package:ble_mqtt_app/utils/mqtt_helper.dart';
import 'package:ble_mqtt_app/viewModels/mqtt_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';

class MessageWindow extends StatelessWidget {
  const MessageWindow({
    super.key,
    required this.messages,
    required this.mqttViewModel,
    required this.nickName,
  });

  final List<String> messages;
  final MqttViewModel mqttViewModel;
  final String nickName;
  static final _formKey = GlobalKey<FormState>();
  static String _enteredMessage = "";
  static String uid = MqttHelper().mqttClientId;

  void submitForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    FocusScope.of(context).unfocus();
    _formKey.currentState!.reset();

    final newMessage = Message(messenger: nickName, message: _enteredMessage);
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
                  : ListView.builder(
                      padding: const EdgeInsets.all(15.0),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (cntxt, i) {
                        bool isLocal = false;
                        bool isFirst = true;
                        int index = messages.length - i - 1;
                        var alignmentCondition =
                            messages[index].contains(nickName);

                        if (alignmentCondition) {
                          isLocal = true;
                        }
                        if (index > 0) {
                          var uiCondition =
                              messages[index - 1].contains(nickName);
                          if (isLocal) {
                            if (uiCondition) {
                              isFirst = false;
                            }
                          } else {
                            if (!uiCondition) {
                              isFirst = false;
                            }
                          }
                        }
                        return ChatBubble(
                          isFirstInSequence: isFirst,
                          message: messages[index],
                          isMe: isLocal,
                        );
                      },
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
