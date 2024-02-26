// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:flutter/material.dart';

class BleDeviceHeader extends StatelessWidget {
  const BleDeviceHeader({
    super.key,
    required this.deviceName,
    required this.connectionState,
    required this.deviceAddress,
    required this.onReconnect,
  });

  final String deviceName;
  final String deviceAddress;
  final void Function() onReconnect;
  final DeviceConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
      decoration: BoxDecoration(
        color: connectionState == DeviceConnectionState.connected
            ? const Color.fromARGB(255, 14, 189, 20)
            : const Color.fromARGB(255, 255, 75, 75),
        border: Border.all(width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Icon(
          color: Colors.black,
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
              style: const TextStyle(fontSize: 10, color: Colors.black),
            ),
            const SizedBox(height: 5),
            Text(
              connectionState == DeviceConnectionState.connected
                  ? "Connected"
                  : "Disconnected",
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),
          ],
        ),
        trailing: connectionState == DeviceConnectionState.connected
            ? const SizedBox()
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  print(deviceName);
                  onReconnect();
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
                          "Reconnect",
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
      ),
    );
  }
}
