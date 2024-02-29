// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/ble/device_connection_state.dart';
import 'package:ble_mqtt_app/providers/ble/ble_provider.dart';
import 'package:ble_mqtt_app/screens/ble/ble_interaction_screen.dart';
import 'package:ble_mqtt_app/utils/ble/ble_hardware_manager.dart';
import 'package:ble_mqtt_app/viewModels/ble_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/ble/ble_device_item.dart';
import 'package:ble_mqtt_app/widgets/common/custom_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class BleActivityScreen extends ConsumerStatefulWidget {
  const BleActivityScreen({super.key});

  static final bleViewModel = BleViewModel();

  @override
  ConsumerState<BleActivityScreen> createState() => _BleActivityScreenState();
}

class _BleActivityScreenState extends ConsumerState<BleActivityScreen> {
  @override
  void initState() {
    super.initState();
    BleHardwareManager().init(ref, context);
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleStateProvider);
    final isBleActive = ref.watch(bleHardwareProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton(
              onPressed: () async {
                if (!isBleActive) {
                  return;
                }
                _startScanning();
              },
              child: SizedBox(
                width: 95,
                height: 20,
                child: bleState.isScanning
                    ? const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 38.0, vertical: 1),
                        child: CircularProgressIndicator(),
                      )
                    : const Text("Start scanning"),
              ),
            ),
          )
        ],
      ),
      body: bleState.availableBleDevices.isEmpty
          ? const Center(
              child: Text(
                "No devices found\n:(",
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: bleState.availableBleDevices.length,
              itemBuilder: (cntxt, index) {
                return _buildDeviceItem(index);
              },
            ),
    );
  }

  /// Function which starts the scanning process
  void _startScanning() async {
    await BleActivityScreen.bleViewModel
        .checkLocationHardwareStatus()
        .then((isAvailable) async {
      if (!isAvailable) {
        customSnackBar(context, "Please turn on your location.");
      } else {
        requestForPermissionsAndStartScanning();
      }
    });
  }

  // Function which handles the permission state
  // and proceed with the scan operation if all permissions are found
  void requestForPermissionsAndStartScanning() async {
    await BleViewModel().checkForPermissions().then((result) {
      if (result.isAllGranted) {
        BleActivityScreen.bleViewModel.startScanning(ref);
      } else {
        showDialog(
            context: context, builder: (context) => dialogOnPermissionDenied());
      }
    });
  }

  /// Function which connects with the desired BLE device
  void _connectWithDevice(
    BluetoothDevice device,
    DeviceConnectionState deviceConnectionState,
  ) async {
    // Returning if already connected
    if (deviceConnectionState == DeviceConnectionState.connected) {
      customSnackBar(
        context,
        "${device.advName} is already connected",
      );
      return;
    }

    // Stopping scan if already scanning
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    // Updating the state to connecting
    ref.read(bleStateProvider.notifier).updateConnectionState(
          device.remoteId,
          DeviceConnectionState.connecting,
        );

    // Attempting connection
    await BleActivityScreen.bleViewModel
        .connectWithDevice(device, ref)
        .then((isSuccess) {
      if (isSuccess) {
        customSnackBar(
            context, "Connected with ${device.advName} successfully :)");
      } else {
        customSnackBar(
          context,
          "Pairing unsuccessful or Failed to connect with ${device.advName} :(",
        );
      }
    });
  }

  /// Function which returns the list item (ble device item)
  Widget _buildDeviceItem(int index) {
    final bleState = ref.watch(bleStateProvider);
    final bleDevice = bleState.availableBleDevices[index].scanResult.device;
    final deviceConnectionState =
        bleState.availableBleDevices[index].connectionState;
    return BleDeviceItem(
      deviceName: bleDevice.advName,
      deviceAddress: bleDevice.remoteId.toString(),
      connectionState: deviceConnectionState,
      onNavigate: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => BleInteractionScreen(
            device: bleDevice,
            index: index,
          ),
        ),
      ),
      onDisconnect: () {
        bleDevice.disconnect();
      },
      onConnect: () async {
        _connectWithDevice(bleDevice, deviceConnectionState);
      },
    );
  }

  /// Returns a dialog which is to be shown to the user
  /// when the requested permissions are denied
  AlertDialog dialogOnPermissionDenied() {
    return AlertDialog(
      title: const Row(
        children: [
          Text(
            'Permissions Required ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8.5),
            child: Icon(Icons.warning_amber_rounded, size: 30),
          )
        ],
      ),
      content: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please grant the following permissions from your settings to proceed:',
            style: TextStyle(fontWeight: FontWeight.w400),
          ),
          Text(
            '\nLocation, Nearby devices',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => openAppSettings(),
          child: const Text('Go to settings'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
