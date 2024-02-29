// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/providers/mqtt/mqtt_providers.dart';
import 'package:ble_mqtt_app/utils/mqtt/mqtt_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttViewModel {
  final MqttHelper mqttHelper = MqttHelper();
  MqttServerClient? mqttClient;

  /// Initializes the mqttclient if it is null
  MqttViewModel() {
    mqttClient ??= mqttHelper.initializeMqttClient();
  }

  /// Function which is used to connect with the mqtt broker and update the UI state
  Future<bool> connectMqttClient(
    WidgetRef ref,
    username,
    String password,
  ) async {
    bool isConnectionSuccess = false;

    try {
      print('Connecting the client...');
      ref
          .read(mqttConnectionProvider.notifier)
          .updateConnectionState(MqttConnectionState.connecting);
      await mqttHelper.mqttClient.connect(username, password);
    } on Exception catch (e) {
      print('Client connection exception: $e');
      mqttHelper.mqttClient.disconnect();
    }

    if (mqttHelper.mqttClient.connectionStatus!.state ==
        MqttConnectionState.connected) {
      print('Client has been connected successfully!!');
      ref
          .read(mqttConnectionProvider.notifier)
          .updateConnectionState(MqttConnectionState.connected);

      setUpListeners(ref);
      subscribeToTopics();
      isConnectionSuccess = true;
    } else {
      print(
        'Client failed to connect: Status: ${mqttHelper.mqttClient.connectionStatus}',
      );
      mqttHelper.mqttClient.disconnect();
      ref
          .read(mqttConnectionProvider.notifier)
          .updateConnectionState(MqttConnectionState.disconnected);
    }
    return isConnectionSuccess;
  }

  /// Function which is used to listen for data incoming from the subscribed topic,
  /// for disconnection and for failure while subscribing
  void setUpListeners(WidgetRef ref) {
    mqttClient!.onDisconnected = () {
      print("Client has been disconnected !!");
      ref
          .read(mqttConnectionProvider.notifier)
          .updateConnectionState(MqttConnectionState.disconnected);
    };

    mqttClient!.onSubscribeFail = (reason) {
      print("Subscription failed $reason");
    };

    mqttClient!.updates!.listen((event) {
      final MqttPublishMessage recMess = event[0].payload as MqttPublishMessage;
      var message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('RECEIVED A NEW MESSAGE:');
      print(message);
      ref.read(mqttMessagesProvider.notifier).storeNewMessage(message);
    });
  }

  /// Function which is used to publish a new message to the broker
  void publishToTopics(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    mqttClient!.publishMessage(
      mqttHelper.sampleTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
  }

  /// Function which is used to subscribe to a topic
  void subscribeToTopics() {
    print('Subscribing to TOPIC: ${mqttHelper.sampleTopic}');
    mqttClient!.subscribe(mqttHelper.sampleTopic, MqttQos.atLeastOnce);
  }
}
