// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:ble_mqtt_app/providers/ble_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class BleViewModel {
  BleViewModel._();

  static final _instance = BleViewModel._();

  factory BleViewModel() {
    return _instance;
  }

  void monitorHardware(WidgetRef ref) {
    FlutterBluePlus.adapterState.listen((event) {
      print("ADAPTER STATE: $event");
    });
  }

  Future<bool> checkForBleSupport() async {
    bool isSupported = await FlutterBluePlus.isSupported;
    print("is BLE supported: $isSupported");
    return isSupported;
  }

  Future<bool> checkForPermissions() async {
    bool permissionsGranted = false;
    if (await Permission.locationWhenInUse.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      permissionsGranted = true;
    }
    return permissionsGranted;
  }

  void startScanning(WidgetRef ref) async {
    bool isBleSupported = await checkForBleSupport();
    if (!isBleSupported) {
      print("error ble not supported");
      return;
    }
    print("Attempting BLE scan...");
    bool permissionsGranted = await checkForPermissions();
    if (!permissionsGranted) {
      print("insufficient permissions");
      return;
    }

    var subscription = FlutterBluePlus.onScanResults.listen(
      (scanResults) {
        if (scanResults.isNotEmpty) {
          ScanResult result = scanResults.last;
          ref.read(bleStateProvider.notifier).updateList(result);
          print(
            '${result.device.remoteId}: "${result.advertisementData.advName}" found!',
          );
        }
      },
      onError: (e) => print(e),
    );

    FlutterBluePlus.cancelWhenScanComplete(subscription);

    FlutterBluePlus.isScanning.listen((currentState) {
      print("SCAN STATE: $currentState");
      ref.read(bleStateProvider.notifier).updateScanningState(currentState);
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );
  }

  void connectWithDevice(BluetoothDevice device, WidgetRef ref) async {
    await FlutterBluePlus.stopScan();

    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.connected) {
        print("Device Connected");
        ref.read(bleStateProvider.notifier).updateConnectionState(
              device.remoteId,
              DeviceConnectionState.connected,
            );
      }
      if (state == BluetoothConnectionState.disconnected) {
        print(
          "${device.disconnectReason!.code} ${device.disconnectReason!.description}",
        );
        ref.read(bleStateProvider.notifier).updateConnectionState(
              device.remoteId,
              DeviceConnectionState.disconnected,
            );
      }
    });

    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

    await device.connect();

    // await device.disconnect();
    // subscription.cancel();
  }
}
