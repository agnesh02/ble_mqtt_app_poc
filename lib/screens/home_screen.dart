import 'package:ble_mqtt_app/screens/ble/ble_activity_screen.dart';
import 'package:ble_mqtt_app/screens/mqtt/mqtt_activity_screen.dart';
import 'package:ble_mqtt_app/utils/mqtt/connection_mode.dart';
import 'package:ble_mqtt_app/widgets/common/functionality_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose your option"),
      ),
      body: Center(
        child: SizedBox(
          height: 120,
          width: double.infinity,
          child: FunctionalitySelection(
            onFunctionalitySelected: (mode) {
              Widget preferredScreen = const BleActivityScreen();
              if (mode == ConnectionMode.mqtt) {
                preferredScreen = const MqttActivityScreen();
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (cntxt) => preferredScreen,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
