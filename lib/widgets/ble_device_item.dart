// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:flutter/material.dart';

class BleDeviceItem extends StatelessWidget {
  const BleDeviceItem({
    super.key,
    required this.deviceName,
    required this.onClick,
    required this.connectionState,
  });

  final String deviceName;
  final void Function() onClick;
  final DeviceConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        connectionState == DeviceConnectionState.connecting
            ? Icons.bluetooth_searching
            : connectionState == DeviceConnectionState.connected
                ? Icons.bluetooth_connected
                : Icons.bluetooth_disabled,
      ),
      title: Text(deviceName),
      trailing: ElevatedButton(
        onPressed: () {
          print(deviceName);
          onClick();
        },
        child: SizedBox(
          width: 70,
          height: 20,
          child: connectionState == DeviceConnectionState.connecting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.0),
                  child: CircularProgressIndicator(),
                )
              : Text(
                  connectionState == DeviceConnectionState.connected
                      ? "Connected"
                      : "Connect",
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
