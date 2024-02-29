// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/ble/device_connection_state.dart';
import 'package:ble_mqtt_app/models/ble/edp_parameters.dart';
import 'package:ble_mqtt_app/providers/ble/ble_data_provider.dart';
import 'package:ble_mqtt_app/providers/ble/ble_provider.dart';
import 'package:ble_mqtt_app/utils/ble/ble_operations_helper.dart';
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

  /// Function which checks if the device supports BLE or not
  Future<bool> checkForBleSupport() async {
    bool isSupported = await FlutterBluePlus.isSupported;
    print("is BLE supported: $isSupported");
    return isSupported;
  }

  /// Function which checks if all the necessary permissions are available or not
  Future<bool> checkForPermissions() async {
    bool permissionsGranted = false;
    if (await Permission.locationWhenInUse.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      permissionsGranted = true;
    }
    return permissionsGranted;
  }

  /// Function which checks if location hardware is turned on or not
  Future<bool> checkLocationHardwareStatus() async {
    var isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    return isServiceEnabled;
  }

  /// Function which starts the scanning process
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

    // Listening to the scan results to update the list
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

  /// Function which is used to create a connection with the device
  Future<bool> connectWithDevice(BluetoothDevice device, WidgetRef ref) async {
    // Adding some delay manually
    await Future.delayed(const Duration(seconds: 1));
    bool? isConnectionSuccessful;

    // Listening to the connection state changes for a device
    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.connected) {
        print("Device Connected");

        final edpService = await discoverAndSetService(device);

        if (edpService == null) {
          print("Some unexpected error !!");
          return;
        }

        ref.read(edpServiceProvider.notifier).state = edpService;

        print("Bonding attempt with the device");
        // Performing an initial read to request the bonding process
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
          "${device.advName} has been disconnected!!! -> ${device.disconnectReason}",
        );
        isConnectionSuccessful = false;
        ref.read(bleStateProvider.notifier).updateConnectionState(
              device.remoteId,
              DeviceConnectionState.disconnected,
            );
      }
    });

    // Helpful in updating UI while bonding
    FlutterBluePlus.events.onConnectionStateChanged.listen((event) {
      print(
        "Connection state changed................ ${event.connectionState}",
      );
      ref.read(bleStateProvider.notifier).updateConnectionState(
            device.remoteId,
            DeviceConnectionState.connecting,
          );
    });

    // FlutterBluePlus.events.onMtuChanged.listen((event) {
    //   print("MTU changed................ ${event.mtu}");
    //   ref.read(bleStateProvider.notifier).updateConnectionState(
    //         device.remoteId,
    //         DeviceConnectionState.connecting,
    //       );
    // });

    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

    // Actual connection
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

  /// Function which is used to discover and store the needed necessary service to use is later on
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

  /// Function which is used to write a new schedule therapy to the EDP device
  Future<void> scheduleTherapy(
    BluetoothDevice device,
    BluetoothService service,
    int slot,
    DateTime startTime,
    int duration,
  ) async {
    // Adding some delay manually
    await Future.delayed(const Duration(seconds: 1));

    for (BluetoothCharacteristic c in service.characteristics) {
      if (c.characteristicUuid.toString() == uuidCommandAndResponse) {
        // Setting a new therapy schedule
        List<int> therapyScheduleData =
            BleOperationsHelper().generateTherapySchedulePacketFrame(
          slotNumber: slot,
          durationInMinutes: duration,
          startTime: startTime,
        );
        await c.write(therapyScheduleData);
      }
    }
  }

  /// Function to subscribe to commands and responses characteristic.
  /// This characteristic notifies us with data based on the request/write we make to it.
  Future<void> subscribeToCommandsAndResponses(
      BluetoothDevice device, BluetoothService service, WidgetRef ref) async {
    for (BluetoothCharacteristic c in service.characteristics) {
      // Listening to command and responses data
      if (c.characteristicUuid.toString() == uuidCommandAndResponse) {
        final subscription = c.onValueReceived.listen((data) {
          print("NEW VALUE UNDER COMMAND AND RESPONSE !!");

          int responseType = data[2];

          switch (responseType) {
            case 37:
              print("SUCCESSFULLY UPDATED DEVICE TIME");
              print(data);
              break;
            case 38:
              int slotNumber = data[3];
              if (slotNumber != 0) {
                print("SUCCESSFULLY SCHEDULED THERAPY IN SLOT");
                print(data);
              }
              break;
            case 21:
              print("FETCHED DEVICE TIME");
              print(data);
              break;
            case 22:
              int slotNumber = data[3];
              if (slotNumber >= 1 && slotNumber <= 4) {
                print("SHOWING SCHEDULED THERAPY IN SLOT $slotNumber");
                print(data);
                ref
                    .read(scheduledTherapiesProvider.notifier)
                    .updateSlot(slotNumber, data);
              }
              break;
            default:
              // Handle other response types if needed
              break;
          }
        });
        device.cancelWhenDisconnected(subscription);
        await c.setNotifyValue(true);
      }
    }
  }

  /// Function which is used to retrieve the scheduled therapies from the Elira device
  Future<void> getTherapySchedules(
    BluetoothDevice device,
    BluetoothService service,
  ) async {
    // Adding some delay manually
    await Future.delayed(const Duration(seconds: 1));

    for (BluetoothCharacteristic c in service.characteristics) {
      if (c.characteristicUuid.toString() == uuidCommandAndResponse) {
        // Retrieving scheduled therapies
        await c.write([0xA5, 0x00, 0x24, 0x00, 0x00]);
      }
    }
  }

  /// Function which is used to update the EDP device with the current time
  Future<void> updateDeviceTime(
    BluetoothDevice device,
    BluetoothService service,
  ) async {
    // Adding some delay manually
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

  /// Function which is used to update the EDP device basic parameters
  /// To get battery voltage, device temperature and amplitude
  Future<EdpParameters> checkDeviceParameters(
    BluetoothDevice device,
    BluetoothService service,
  ) async {
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
