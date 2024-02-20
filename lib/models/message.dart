class Message {
  Message({required this.messenger, required this.message});

  final String messenger;
  final String message;
}

enum Messenger { local, anonymous }
