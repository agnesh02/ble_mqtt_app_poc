// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason> bleBanner(
  BuildContext context,
  BluetoothAdapterState status,
) {
  String connectionStatusText = 'Unknown';
  Color connectionStatusColor = Colors.grey;
  IconData iconData = Icons.question_mark;

  switch (status) {
    case BluetoothAdapterState.on:
      connectionStatusText = 'Turned ON';
      connectionStatusColor = Colors.blue;
      iconData = Icons.bluetooth;
      break;
    case BluetoothAdapterState.off:
      connectionStatusText = 'Turned OFF';
      connectionStatusColor = Colors.red;
      iconData = Icons.bluetooth_disabled;
      break;
    default:
      connectionStatusText = 'Unknown';
      break;
  }

  ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.clearMaterialBanners();

  return scaffoldMessenger.showMaterialBanner(
    MaterialBanner(
      padding: const EdgeInsets.all(20),
      content: Text(
        'BLE Status:\n$connectionStatusText',
        style: const TextStyle(color: Colors.white),
      ),
      leading: Icon(iconData),
      backgroundColor: connectionStatusColor,
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            if (connectionStatusText == 'Turned OFF') {
              print("Attempting to turn on BLE");
              if (Platform.isAndroid) {
                await FlutterBluePlus.turnOn();
              }
            } else {
              scaffoldMessenger.clearMaterialBanners();
            }
          },
          child: connectionStatusText == 'Turned OFF'
              ? const Text(
                  "Turn ON Bluetooth",
                  style: TextStyle(color: Colors.white),
                )
              : const Text(
                  'DISMISS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    ),
  );
}
