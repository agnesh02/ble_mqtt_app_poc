import 'package:ble_mqtt_app/screens/ble_activity_screen.dart';
import 'package:ble_mqtt_app/screens/mqtt_activity_screen.dart';
import 'package:ble_mqtt_app/utils/connection_mode.dart';
import 'package:ble_mqtt_app/utils/network_manager.dart';
import 'package:ble_mqtt_app/widgets/functionality_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    NetworkManager().init(ref, context);

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
                preferredScreen = MqttActivityScreen();
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
