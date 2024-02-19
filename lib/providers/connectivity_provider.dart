import 'package:ble_mqtt_app/utils/mqtt_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(false);

  void updateConnectivityState(ConnectivityResult currentState) {
    if (currentState == ConnectivityResult.none) {
      state = false;
      MqttHelper().mqttClient.disconnect();
    } else {
      state = true;
    }
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>(
  (ref) => ConnectivityNotifier(),
);
