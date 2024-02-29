import 'package:ble_mqtt_app/utils/mqtt/mqtt_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(false);

  /// Function which updates if we are connected to the internet or not
  void updateConnectivityState(ConnectivityResult currentState) {
    if (currentState == ConnectivityResult.none) {
      state = false;
      MqttHelper().mqttClient.disconnect();
    } else {
      state = true;
    }
  }
}

/// Provider which holds the info whether we are connected to the internet or not
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>(
  (ref) => ConnectivityNotifier(),
);
