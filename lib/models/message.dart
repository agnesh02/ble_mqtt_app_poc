class Message {
  Message({required this.messenger, required this.message});

  final Messenger messenger;
  final String message;
}

enum Messenger { local, anonymous }
