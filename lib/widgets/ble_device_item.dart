// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:flutter/material.dart';

class BleDeviceItem extends StatelessWidget {
  const BleDeviceItem({
    super.key,
    required this.deviceName,
    required this.connectionState,
    required this.deviceAddress,
    required this.onConnect,
    required this.onDisconnect,
    required this.onNavigate,
  });

  final String deviceName;
  final String deviceAddress;
  final void Function() onConnect;
  final void Function() onDisconnect;
  final void Function() onNavigate;
  final DeviceConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        border: Border.all(width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(
          connectionState == DeviceConnectionState.connecting
              ? Icons.bluetooth_searching
              : connectionState == DeviceConnectionState.connected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(deviceName),
            Text(
              deviceAddress,
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 5),
            Text(
              connectionState == DeviceConnectionState.connected
                  ? "Connected"
                  : "Disconnected",
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        trailing: connectionState == DeviceConnectionState.connected
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  print(deviceName);
                  onNavigate();
                },
                onLongPress: () {
                  print("Disconnecting device");
                  onDisconnect();
                },
                child: const Text("Navigate"),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  print(deviceName);
                  onConnect();
                },
                child: SizedBox(
                  width: 70,
                  height: 20,
                  child: connectionState == DeviceConnectionState.connecting
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.0),
                          child: CircularProgressIndicator(),
                        )
                      : const Text(
                          "Connect",
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
      ),
    );
  }
}
