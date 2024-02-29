// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/ble/device_connection_state.dart';
import 'package:ble_mqtt_app/models/ble/edp_parameters.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Class which is used to manage the state of BLE
/// Handles state of the scanned results
/// Handles the current scanning state
class BleState {
  List<BleDevice> availableBleDevices;
  bool isScanning;

  BleState({
    required this.availableBleDevices,
    required this.isScanning,
  });
}

/// Class which is used to manage the state of a particular BLE device
/// Handles the device's current connection state
/// Holds the details of that particular device (scanResult and scanResult.device)
class BleDevice {
  BleDevice({
    required this.connectionState,
    required this.scanResult,
  });
  DeviceConnectionState connectionState;
  ScanResult scanResult;
}

class BleStateNotifier extends StateNotifier<BleState> {
  BleStateNotifier()
      : super(BleState(availableBleDevices: [], isScanning: false));

  /// Function which is used to update the list of scanned/available devices
  void updateList(ScanResult newResult) {
    bool isNew = true;

    // Checking if device is already listed
    for (var device in state.availableBleDevices) {
      if (device.scanResult == newResult) {
        isNew = false;
      }
    }

    // If listed ignoring
    if (!isNew) {
      return;
    }

    // Updating the list and initializing the connection state as disconnected
    state = BleState(
      availableBleDevices: [
        ...state.availableBleDevices,
        BleDevice(
            connectionState: DeviceConnectionState.disconnected,
            scanResult: newResult)
      ],
      isScanning: state.isScanning,
    );
  }

  /// Function which is used to update if the app is currently scanning or not
  void updateScanningState(bool currentState) {
    state = BleState(
      availableBleDevices: [...state.availableBleDevices],
      isScanning: currentState,
    );
  }

  /// Function which is used to update the current connection state of a particular BLE device
  void updateConnectionState(
    DeviceIdentifier deviceId,
    DeviceConnectionState currentConnectionState,
  ) {
    for (var device in state.availableBleDevices) {
      if (device.scanResult.device.remoteId == deviceId) {
        device.connectionState = currentConnectionState;
      }
    }

    state = BleState(
      availableBleDevices: [...state.availableBleDevices],
      isScanning: state.isScanning,
    );
  }
}

/// Provider which is used to handle
/// 1. List of available devices
/// 2. Current scanning state of BLE
final bleStateProvider = StateNotifierProvider<BleStateNotifier, BleState>(
  (ref) => BleStateNotifier(),
);

/// Provider which is used to handle the BLE power state (On/Off)
final bleHardwareProvider = StateProvider<bool>((ref) => false);

/// Provider which holds the basic parameters of the Elira device.
/// The data comes under 'Device Parameters'
final eliraParametersProvider = StateProvider<EdpParameters>(
  (ref) => EdpParameters(battery: "--", temperature: "--", amplitude: "--"),
);

/// Provider which is holds the [edpService] (The actual service from the Elira device which we need for all the functionalities)
final edpServiceProvider = StateProvider<BluetoothService?>((ref) => null);
