import 'dart:io';

import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

/// Class which helps us in setting up the Mqtt client initially
/// Also helps us to access the [mqttClient] for our operations
class MqttHelper {
  MqttHelper._();

  static final _instance = MqttHelper._();
  late MqttServerClient mqttClient;

  factory MqttHelper() {
    return _instance;
  }

  static const mqttBrokerHost =
      '17f160d3af614356880479943d8449dd.s1.eu.hivemq.cloud';

  static const mqttPort = 8883;
  String mqttClientId = uuid.v4();
  String sampleTopic = "topic/sampleTopic";

  /// Function which is used to set up and mqtt client with predefined properties
  MqttServerClient initializeMqttClient() {
    mqttClient = MqttServerClient.withPort(
      mqttBrokerHost,
      mqttClientId,
      mqttPort,
    );
    mqttClient.secure = true;
    mqttClient.securityContext = SecurityContext.defaultContext;
    mqttClient.keepAlivePeriod = 20;
    return mqttClient;
  }
}
