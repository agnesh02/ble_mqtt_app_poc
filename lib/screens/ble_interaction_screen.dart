// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:ble_mqtt_app/providers/ble_provider.dart';
import 'package:ble_mqtt_app/viewModels/ble_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/ble_device_header.dart';
import 'package:ble_mqtt_app/widgets/custom_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final elevatedButtonStyle = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

class BleInteractionScreen extends ConsumerWidget {
  const BleInteractionScreen({
    super.key,
    required this.device,
    required this.index,
  });

  final BluetoothDevice device;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("EDP Device"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            BleDeviceHeader(
                deviceName: device.advName,
                connectionState:
                    bleState.availableBleDevices[index].connectionState,
                deviceAddress: device.remoteId.toString(),
                onReconnect: () async {
                  print("Attempting reconnection...");
                  ref.read(bleStateProvider.notifier).updateConnectionState(
                        device.remoteId,
                        DeviceConnectionState.connecting,
                      );
                  await BleViewModel()
                      .connectWithDevice(device, ref)
                      .then((isSuccess) {
                    if (isSuccess) {
                      customSnackBar(context,
                          "Reconnected with ${device.advName} successfully :)");
                    } else {
                      customSnackBar(context,
                          "Failed to reconnect with ${device.advName} :(");
                    }
                  });
                }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Device Parameters",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
                ElevatedButton(
                  style: elevatedButtonStyle,
                  onPressed: () {
                    BleViewModel().discoverServices(device);
                  },
                  child: const Text("Check"),
                )
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  ParameterRow(title: "Battery Voltage", data: "0"),
                  ParameterRow(title: "Temperature", data: "0"),
                  ParameterRow(
                    title: "Amplitude",
                    data: "0",
                    bottomBorder: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            CommandButton(
              title: "Update Current Time",
              onClick: () {
                print("Command 1");
              },
            ),
            CommandButton(
              title: "Set Therapy Schedules",
              onClick: () {
                print("Command 2");
              },
            ),
            CommandButton(
              title: "Show Therapy Schedules",
              onClick: () {
                print("Command 3");
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ParameterRow extends StatelessWidget {
  const ParameterRow({
    super.key,
    required this.title,
    required this.data,
    this.bottomBorder = true,
  });

  final String title;
  final String data;
  final bool bottomBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            style: bottomBorder ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$title: "),
            Text(data),
          ],
        ),
      ),
    );
  }
}

class CommandButton extends StatelessWidget {
  const CommandButton({
    super.key,
    required this.title,
    required this.onClick,
  });

  final String title;
  final void Function() onClick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        style: elevatedButtonStyle,
        onPressed: onClick,
        child: Text(title),
      ),
    );
  }
}
