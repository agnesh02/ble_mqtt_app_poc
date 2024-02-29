/// Class which represents the message format
/// Helps to identify he sender and receiver
class Message {
  Message({required this.messenger, required this.message});

  final String messenger;
  final String message;
}

// enum Messenger { local, anonymous }
