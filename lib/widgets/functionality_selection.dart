import 'package:ble_mqtt_app/utils/connection_mode.dart';
import 'package:flutter/material.dart';

class FunctionalitySelection extends StatelessWidget {
  const FunctionalitySelection({
    super.key,
    required this.onFunctionalitySelected,
  });

  final void Function(ConnectionMode mode) onFunctionalitySelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FunctionalityCard(
          icon: Icons.bluetooth,
          title: "BLE",
          color: Colors.blue[300],
          onSelected: () => onFunctionalitySelected(ConnectionMode.ble),
        ),
        FunctionalityCard(
          icon: Icons.wifi,
          title: "MQTT",
          color: Colors.green[300],
          onSelected: () => onFunctionalitySelected(ConnectionMode.mqtt),
        ),
      ],
    );
  }
}

class FunctionalityCard extends StatelessWidget {
  const FunctionalityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final Color? color;
  final void Function() onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.fromARGB(255, 244, 235, 255),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onSelected,
        splashColor: color,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
