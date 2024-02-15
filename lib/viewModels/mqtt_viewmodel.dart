// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:ble_mqtt_app/utils/mqtt_helper.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttViewModel {
  final MqttHelper mqttHelper = MqttHelper();
  MqttServerClient? mqttClient;

  Future<void> connectMqttClient(String username, String password) async {
    mqttClient ??= mqttHelper.initializeMqttClient();
    try {
      print('Connecting the client...');
      await mqttHelper.mqttClient.connect(username, password);
    } on Exception catch (e) {
      print('Client connection exception: $e');
      mqttHelper.mqttClient.disconnect();
    }

    if (mqttHelper.mqttClient.connectionStatus!.state ==
        MqttConnectionState.connected) {
      print('Client has been connected successfully!!');
      publishToBroker();
    } else {
      print(
        'Client failed to connect: Status: ${mqttHelper.mqttClient.connectionStatus}',
      );
      mqttHelper.mqttClient.disconnect();
    }
  }

  void publishToBroker() {
    String data = "Test message";
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(data);

    mqttClient!.publishMessage(
      "topic/sampleTopic",
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }
}
