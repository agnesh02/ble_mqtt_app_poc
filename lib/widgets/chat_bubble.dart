import 'package:ble_mqtt_app/models/message.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isFirstInSequence,
  });

  final String message;
  final bool isMe;
  final bool isFirstInSequence;

  @override
  Widget build(BuildContext context) {
    late List<String> formattedMsg;
    if (message.contains("local")) {
      formattedMsg = message.split(":");
    } else {
      formattedMsg = ["${Messenger.anonymous}", message];
    }

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        !isMe && isFirstInSequence
            ? ChatAvatar(isLocal: isMe)
            : const SizedBox(width: 40),
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(!isMe && isFirstInSequence ? 0 : 20),
                topRight: Radius.circular(isMe && isFirstInSequence ? 0 : 20),
                bottomLeft: const Radius.circular(20),
                bottomRight: const Radius.circular(20),
              ),
            ),
            child: Text(
              formattedMsg[1],
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
        isMe && isFirstInSequence
            ? ChatAvatar(isLocal: isMe)
            : const SizedBox(width: 40),
      ],
    );
  }
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.isLocal});

  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: CircleAvatar(
        backgroundColor: isLocal ? Colors.amber : Colors.indigo,
        child: Icon(
          Icons.person,
          color: isLocal ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
