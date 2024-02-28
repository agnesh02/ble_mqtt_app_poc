// ignore_for_file: avoid_print

// ignore: unused_import
import 'dart:math';

import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:ble_mqtt_app/models/edp_parameters.dart';
import 'package:ble_mqtt_app/providers/ble_data_provider.dart';
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
    bool? isConnectionSuccessful;
    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.connected) {
        print("Device Connected");

        print("Bonding with the device");
        final edpService = await discoverAndSetService(device);

        if (edpService == null) {
          print("Some unexpected error !!");
          return;
        }

        ref.read(edpServiceProvider.notifier).state = edpService;

        for (BluetoothCharacteristic charac in edpService.characteristics) {
          if (charac.characteristicUuid.toString() == uuidBatteryVoltage) {
            List<int> value = await charac.read(timeout: 40);
            print(value);
            isConnectionSuccessful = true;
            ref.read(bleStateProvider.notifier).updateConnectionState(
                  device.remoteId,
                  DeviceConnectionState.connected,
                );
          }
        }
      }
      if (state == BluetoothConnectionState.disconnected) {
        print(
          "${device.advName} has been disconnected!!! -> ${device.disconnectReason!.code} ${device.disconnectReason!.description} ${device.disconnectReason}",
        );
        isConnectionSuccessful = false;
        ref.read(bleStateProvider.notifier).updateConnectionState(
              device.remoteId,
              DeviceConnectionState.disconnected,
            );
      }
    });

    FlutterBluePlus.events.onMtuChanged.listen((event) {
      print("MTU changed................ ${event.mtu}");
      ref.read(bleStateProvider.notifier).updateConnectionState(
            device.remoteId,
            DeviceConnectionState.connecting,
          );
    });

    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

    await device
        .connect(timeout: const Duration(seconds: 10))
        .onError((error, stackTrace) {
      print("ERROR: $error");
    });

    // Wait until isConnectionSuccessful is not null
    while (isConnectionSuccessful == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return isConnectionSuccessful!;
  }

  Future<BluetoothService?> discoverAndSetService(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == uuidEdpService) {
        return service;
      }
    }
    return null;
  }

  Future<void> scheduleTherapy(
    BluetoothDevice device,
    BluetoothService service,
    DateTime startTime,
    int duration,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    for (BluetoothCharacteristic c in service.characteristics) {
      if (c.characteristicUuid.toString() == uuidCommandAndResponse) {
        // Setting a new therapy schedule
        List<int> therapyScheduleData =
            BleOperationsHelper().generateTherapySchedulePacketFrame(
          slotNumber: 1,
          durationInMinutes: duration,
          startTime: startTime,
        );
        await c.write(therapyScheduleData);
      }
    }
  }

  Future<void> subscribeToCommandsAndResponses(
      BluetoothDevice device, BluetoothService service, WidgetRef ref) async {
    for (BluetoothCharacteristic c in service.characteristics) {
      // Listening to command and responses data
      if (c.characteristicUuid.toString() == uuidCommandAndResponse) {
        final subscription = c.onValueReceived.listen((data) {
          print("NEW VALUE UNDER COMMAND AND RESPONSE !!");
          // print(data);

          int responseType = data[2];

          if (responseType == 37) {
            print("SUCCESSFULLY UPDATED DEVICE TIME");
            print(data);
          }

          if (responseType == 38) {
            int slotNumber = data[3];
            if (slotNumber != 0) {
              print("SUCCESSFULLY SCHEDULED THERAPY IN SLOT");
              print(data);
            }
          }

          if (responseType == 21) {
            print("FETCHED DEVICE TIME");
            print(data);
          }

          if (responseType == 22) {
            int slotNumber = data[3];
            switch (slotNumber) {
              case 1:
                print("SHOWING SCHEDULED THERAPY IN SLOT 1");
                print(data);
                ref
                    .read(scheduledTherapiesProvider.notifier)
                    .updateSlot(1, data);
                break;
              case 2:
                print("SHOWING SCHEDULED THERAPY IN SLOT 2");
                print(data);
                ref
                    .read(scheduledTherapiesProvider.notifier)
                    .updateSlot(2, data);
                break;
              case 3:
                print("SHOWING SCHEDULED THERAPY IN SLOT 3");
                print(data);
                ref
                    .read(scheduledTherapiesProvider.notifier)
                    .updateSlot(3, data);
                break;
              case 4:
                print("SHOWING SCHEDULED THERAPY IN SLOT 4");
                print(data);
                ref
                    .read(scheduledTherapiesProvider.notifier)
                    .updateSlot(4, data);
                break;
            }
          }
        });
        device.cancelWhenDisconnected(subscription);
        await c.setNotifyValue(true);
      }
    }
  }

  Future<void> getTherapySchedules(
    BluetoothDevice device,
    BluetoothService service,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    for (BluetoothCharacteristic c in service.characteristics) {
      if (c.characteristicUuid.toString() == uuidCommandAndResponse) {
        // Retrieving scheduled therapies
        await c.write([0xA5, 0x00, 0x24, 0x00, 0x00]);
      }
    }
  }

  Future<void> updateDeviceTime(
    BluetoothDevice device,
    BluetoothService service,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    for (BluetoothCharacteristic c in service.characteristics) {
      if (c.characteristicUuid.toString() == uuidCommandAndResponse) {
        // Updating device time
        var time = BleOperationsHelper().convertTimeToBytes(DateTime.now());
        await c.write([0xA5, 0x04, 0x19, ...time, 0x00]);
        // Get device time
        await c.write([0xA5, 0x00, 0x25, 0x00, 0x00]);
      }
    }
  }

  Future<EdpParameters> checkDeviceParameters(
      BluetoothDevice device, BluetoothService service) async {
    EdpParameters edpParameters = EdpParameters(
      battery: "0",
      temperature: "0",
      amplitude: "0",
    );
    for (BluetoothCharacteristic charac in service.characteristics) {
      String characUUID = charac.characteristicUuid.toString();
      switch (characUUID) {
        case uuidBatteryVoltage:
          List<int> data = await charac.read();
          edpParameters.battery = "${data[0] / 10}V";
          break;
        case uuidTemperature:
          List<int> data = await charac.read();
          edpParameters.temperature = "${data[0]}°C";
          break;
        case uuidAmplitude:
          List<int> data = await charac.read();
          edpParameters.amplitude = "${data[0]}mA";
          break;
        default:
          break;
      }
    }
    return edpParameters;
  }
}
