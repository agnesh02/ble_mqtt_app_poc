import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttConnectionNotifier extends StateNotifier<MqttConnectionState> {
  MqttConnectionNotifier() : super(MqttConnectionState.disconnected);

  /// Function which updates our current connection state with the mqtt broker
  void updateConnectionState(MqttConnectionState currentConnectionState) {
    state = currentConnectionState;
  }
}

/// Provider which holds the info about our current connection state with the mqtt broker
final mqttConnectionProvider =
    StateNotifierProvider<MqttConnectionNotifier, MqttConnectionState>(
  (ref) => MqttConnectionNotifier(),
);

class MqttMessageNotifier extends StateNotifier<List<String>> {
  MqttMessageNotifier() : super([]);

  /// Function which adds the newly received message to the existing list of messages
  void storeNewMessage(String newMessage) {
    state = [...state, newMessage];
  }
}

/// Provider which holds the list of message send and received
final mqttMessagesProvider =
    StateNotifierProvider<MqttMessageNotifier, List<String>>(
  (ref) => MqttMessageNotifier(),
);

/// Provider which holds the nickname entered by the user
final nickNameProvider = StateProvider((ref) => "");
