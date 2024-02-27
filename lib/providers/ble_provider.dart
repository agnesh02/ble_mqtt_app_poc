import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:ble_mqtt_app/models/edp_parameters.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BleState {
  List<BleDevice> availableBleDevices;
  bool isScanning;

  BleState({
    required this.availableBleDevices,
    required this.isScanning,
  });
}

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

  void updateList(ScanResult newResult) {
    bool isNew = true;

    for (var device in state.availableBleDevices) {
      if (device.scanResult == newResult) {
        isNew = false;
      }
    }

    if (!isNew) {
      return;
    }

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

  void updateScanningState(bool currentState) {
    state = BleState(
      availableBleDevices: [...state.availableBleDevices],
      isScanning: currentState,
    );
  }

  void updateConnectionState(
    DeviceIdentifier deviceId,
    DeviceConnectionState currentConnectionState,
  ) {
    for (var device in state.availableBleDevices) {
      if (device.scanResult.device.remoteId == deviceId) {
        device.connectionState = currentConnectionState;
      }
    }

    for (var device in state.availableBleDevices) {
      if (device.scanResult.device.remoteId == deviceId) {
        print(device.connectionState);
      }
    }
    state = BleState(
      availableBleDevices: [...state.availableBleDevices],
      isScanning: state.isScanning,
    );
  }
}

final bleStateProvider = StateNotifierProvider<BleStateNotifier, BleState>(
  (ref) => BleStateNotifier(),
);

final bleHardwareProvider = StateProvider((ref) => false);

final eliraParametersProvider = StateProvider(
  (ref) => EdpParameters(battery: "0", temperature: "0", amplitude: "0"),
);
