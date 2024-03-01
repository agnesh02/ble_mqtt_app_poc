// ignore_for_file: avoid_print

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:ble_mqtt_app/models/ble/device_connection_state.dart';
import 'package:ble_mqtt_app/models/ble/edp_parameters.dart';
import 'package:ble_mqtt_app/providers/ble/ble_data_provider.dart';
import 'package:ble_mqtt_app/providers/ble/ble_provider.dart';
import 'package:ble_mqtt_app/providers/ble/time_provider.dart';
import 'package:ble_mqtt_app/utils/ble/ble_operations_helper.dart';
import 'package:ble_mqtt_app/utils/ble/edp_helper.dart';
import 'package:ble_mqtt_app/utils/ble/notification_helper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionStatus {
  PermissionStatus({
    required this.isAllGranted,
    required this.deniedPermissions,
  });

  final bool isAllGranted;
  final List<Permission> deniedPermissions;
}

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
  Future<PermissionStatus> checkForPermissions() async {
    bool permissionsGranted = false;
    List<Permission> deniedPermissions = [];
    final locationPermissionStatus =
        await Permission.locationWhenInUse.request();
    final bluetoothScanPermissionStatus =
        await Permission.bluetoothScan.request();
    final bluetoothConnectPermissionStatus =
        await Permission.bluetoothConnect.request();

    if (locationPermissionStatus.isGranted &&
        bluetoothScanPermissionStatus.isGranted &&
        bluetoothConnectPermissionStatus.isGranted) {
      permissionsGranted = true;
    } else {
      if (!locationPermissionStatus.isGranted) {
        deniedPermissions.add(Permission.locationWhenInUse);
      }
      if (!bluetoothScanPermissionStatus.isGranted) {
        deniedPermissions.add(Permission.bluetoothScan);
      }
      if (!bluetoothConnectPermissionStatus.isGranted) {
        deniedPermissions.add(Permission.bluetoothConnect);
      }
    }
    return PermissionStatus(
      isAllGranted: permissionsGranted,
      deniedPermissions: deniedPermissions,
    );
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
    // bool permissionsGranted = await checkForPermissions();
    // if (!permissionsGranted) {
    //   print("insufficient permissions");
    //   return;
    // }

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
          if (charac.characteristicUuid.toString() ==
              EdpHelper.uuidBatteryVoltage) {
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

    FlutterBluePlus.events.onMtuChanged.listen((event) {
      print("MTU changed................ ${event.mtu}");
      ref.read(bleStateProvider.notifier).updateConnectionState(
            device.remoteId,
            DeviceConnectionState.connecting,
          );
    });

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
      if (service.uuid.toString() == EdpHelper.uuidEdpService) {
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
      if (c.characteristicUuid.toString() == EdpHelper.uuidCommandAndResponse) {
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
    BluetoothDevice device,
    BluetoothService service,
    BuildContext context,
    WidgetRef ref,
  ) async {
    for (BluetoothCharacteristic c in service.characteristics) {
      // Listening to command and responses data
      if (c.characteristicUuid.toString() == EdpHelper.uuidCommandAndResponse) {
        final subscription = c.onValueReceived.listen((data) {
          print("NEW VALUE UNDER COMMAND AND RESPONSE !!");

          int indexOfResponseType = 2;
          int indexOfSlotNumber = 3;
          int responseType = data[indexOfResponseType];

          switch (responseType) {
            case EdpHelper.responseTypeUpdateDeviceTime:
              print("SUCCESSFULLY UPDATED DEVICE TIME");
              NotificationHelper().createNewNotification(
                title: '${Emojis.symbols_repeat_button} Synced !!',
                message: 'Synced time with EDP Device successfully.',
              );
              print(data);
              break;
            case EdpHelper.responseTypeScheduleTherapy:
              int slotNumber = data[indexOfSlotNumber];
              final startTime = ref.read(timingsProvider).startTime;
              final duration = ref.read(timingsProvider).duration;

              if (slotNumber != 0) {
                print("SUCCESSFULLY SCHEDULED THERAPY IN SLOT");
                print(data);
                NotificationHelper().createNewNotification(
                  title: '${Emojis.time_alarm_clock} Therapy Scheduled !!',
                  message:
                      'You have successfully scheduled a new therapy. Time: ${displayTiming(context, startTime)} | Duration: $duration minutes',
                );
              }
              break;
            case EdpHelper.responseTypeFetchDeviceTime:
              print("FETCHED DEVICE TIME");
              print(data);
              break;
            case EdpHelper.responseTypeFetchTherapiesScheduled:
              int slotNumber = data[indexOfSlotNumber];
              if (slotNumber >= 1 && slotNumber <= 4) {
                print("SHOWING SCHEDULED THERAPY IN SLOT $slotNumber");
                print(data);
                ref
                    .read(scheduledTherapiesProvider.notifier)
                    .updateSlot(slotNumber, data);
              }
              break;
            default:
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
      if (c.characteristicUuid.toString() == EdpHelper.uuidCommandAndResponse) {
        // Retrieving scheduled therapies
        await c.write(EdpHelper.commandGetTherapySchedules);
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
      if (c.characteristicUuid.toString() == EdpHelper.uuidCommandAndResponse) {
        // Updating device time
        var time = BleOperationsHelper().convertTimeToBytes(DateTime.now());
        await c.write([0xA5, 0x04, 0x19, ...time, 0x00]);
        // Get device time
        await c.write(EdpHelper.commandGetDeviceTime);
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
        case EdpHelper.uuidBatteryVoltage:
          List<int> data = await charac.read();
          edpParameters.battery = "${data[0] / 10}V";
          break;
        case EdpHelper.uuidTemperature:
          List<int> data = await charac.read();
          edpParameters.temperature = "${data[0]}°C";
          break;
        case EdpHelper.uuidAmplitude:
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
