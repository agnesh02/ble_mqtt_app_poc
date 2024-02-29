// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/providers/ble/ble_provider.dart';
import 'package:ble_mqtt_app/widgets/ble/ble_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BleHardwareManager {
  BleHardwareManager._();

  static final _instance = BleHardwareManager._();

  factory BleHardwareManager() {
    return _instance;
  }

  /// Listens to BLE hardware state (ON/OFF)
  void init(WidgetRef ref, BuildContext context) {
    print("Subscribing to BLE hardware state");
    FlutterBluePlus.adapterState.listen((event) {
      print("ADAPTER STATE: $event");
      if (event == BluetoothAdapterState.on) {
        ref.read(bleHardwareProvider.notifier).state = true;
        bleBanner(context, BluetoothAdapterState.on);
        // customSnackBar(context, "BLE turned on :)");
      } else if (event == BluetoothAdapterState.off) {
        ref.read(bleHardwareProvider.notifier).state = false;
        bleBanner(context, BluetoothAdapterState.off);
        // customSnackBar(context, "BLE turned is turned off :(");
      }
    });
  }
}
