import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttConnectionNotifier extends StateNotifier<MqttConnectionState> {
  MqttConnectionNotifier() : super(MqttConnectionState.disconnected);

  void updateConnectionState(MqttConnectionState currentConnectionState) {
    state = currentConnectionState;
  }
}

final mqttConnectionProvider =
    StateNotifierProvider<MqttConnectionNotifier, MqttConnectionState>(
  (ref) => MqttConnectionNotifier(),
);

class MqttMessageNotifier extends StateNotifier<List<String>> {
  MqttMessageNotifier() : super([]);

  void storeNewMessage(String newMessage) {
    state = [...state, newMessage];
  }
}

final mqttMessagesProvider =
    StateNotifierProvider<MqttMessageNotifier, List<String>>(
  (ref) => MqttMessageNotifier(),
);

final nickNameProvider = StateProvider((ref) => "");
