// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:ble_mqtt_app/providers/ble_provider.dart';
import 'package:ble_mqtt_app/screens/ble_interaction_screen.dart';
import 'package:ble_mqtt_app/utils/ble_hardware_manager.dart';
import 'package:ble_mqtt_app/viewModels/ble_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/ble_device_item.dart';
import 'package:ble_mqtt_app/widgets/custom_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                BleActivityScreen.bleViewModel.startScanning(ref);
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: bleState.availableBleDevices.length,
        itemBuilder: (cntxt, index) {
          final bleDevice =
              bleState.availableBleDevices[index].scanResult.device;
          final deviceConnectionState =
              bleState.availableBleDevices[index].connectionState;
          return BleDeviceItem(
            deviceName: bleDevice.advName,
            deviceAddress: bleDevice.remoteId.toString(),
            connectionState: deviceConnectionState,
            onNavigate: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => const BleInteractionScreen(),
              ),
            ),
            onConnect: () async {
              if (deviceConnectionState == DeviceConnectionState.connected) {
                customSnackBar(
                  context,
                  "${bleDevice.advName} is already connected",
                );
                return;
              }

              if (bleState.isScanning) {
                await FlutterBluePlus.stopScan();
              }

              ref.read(bleStateProvider.notifier).updateConnectionState(
                    bleDevice.remoteId,
                    DeviceConnectionState.connecting,
                  );

              await BleActivityScreen.bleViewModel
                  .connectWithDevice(bleDevice, ref)
                  .then((isSuccess) {
                if (isSuccess) {
                  ref.read(bleStateProvider.notifier).updateConnectionState(
                        bleDevice.remoteId,
                        DeviceConnectionState.connected,
                      );
                  customSnackBar(context,
                      "Connected with ${bleDevice.advName} successfully :)");
                } else {
                  ref.read(bleStateProvider.notifier).updateConnectionState(
                        bleDevice.remoteId,
                        DeviceConnectionState.disconnected,
                      );
                  customSnackBar(context,
                      "Failed to connect with ${bleDevice.advName} :(");
                }
              });
            },
          );
        },
      ),
    );
  }
}
