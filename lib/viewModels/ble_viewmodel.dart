// ignore_for_file: avoid_print

// ignore: unused_import
import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:ble_mqtt_app/providers/ble_provider.dart';
import 'package:ble_mqtt_app/utils/ble_operations_helper.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<bool> checkLocationHardwareStatus() async {
    var isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    return isServiceEnabled;
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

  Future<bool> connectWithDevice(BluetoothDevice device, WidgetRef ref) async {
    await Future.delayed(const Duration(seconds: 1));
    bool isConnectionSuccessful = false;
    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.connected) {
        print("Device Connected");
        isConnectionSuccessful = true;
        ref.read(bleStateProvider.notifier).updateConnectionState(
              device.remoteId,
              DeviceConnectionState.connected,
            );
      }
      if (state == BluetoothConnectionState.disconnected) {
        print(
          "${device.advName} has been disconnected!!! -> ${device.disconnectReason!.code} ${device.disconnectReason!.description}",
        );
        isConnectionSuccessful = false;
        ref.read(bleStateProvider.notifier).updateConnectionState(
              device.remoteId,
              DeviceConnectionState.disconnected,
            );
      }
    });

    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

    await device
        .connect(timeout: const Duration(seconds: 5))
        .onError((error, stackTrace) {
      print("ERROR: $error");
      // Future.delayed(const Duration(seconds: 1), () => subscription.cancel());
    });

    return isConnectionSuccessful;
    // await device.disconnect();
    // subscription.cancel();
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    // Note: You must call discoverServices after every re-connection!
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == "f000ee00-0451-4000-b000-000000000000") {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.characteristicUuid.toString() ==
              "f000ee03-0451-4000-b000-000000000000") {
            device.createBond();
            List<int> value = await c.read();
            print(value);
          }
          if (c.characteristicUuid.toString() ==
              "f000ee07-0451-4000-b000-000000000000") {
            final subscription = c.onValueReceived.listen((value) {
              print(value);
            });

            device.cancelWhenDisconnected(subscription);
            await c.setNotifyValue(true);

            List<int> therapyScheduleData =
                BleOperationsHelper().generateTherapySchedulePacketFrame(
              slotNumber: 1,
              durationInMinutes: 20,
            );

            await c.write(therapyScheduleData);

            Future.delayed(Duration(seconds: 2), () async {
              await c.write([0xA5, 0x00, 0x24, 0x00, 0x00]);
            });
          }
        }
      }
    }
  }
}
