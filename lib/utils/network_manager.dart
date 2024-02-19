// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/providers/connectivity_provider.dart';
import 'package:ble_mqtt_app/widgets/custom_snack.dart';
import 'package:ble_mqtt_app/widgets/network_banner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkManager {
  NetworkManager._();

  static final NetworkManager _instance = NetworkManager._();

  factory NetworkManager() {
    return _instance;
  }

  late ConnectivityResult connectionStatus;
  late WidgetRef ref;

  void Function(ConnectivityResult) onConnectionStateChanged =
      (ConnectivityResult result) {};

  /// Function to initialize and listen to network changes
  void init(WidgetRef ref, BuildContext context) {
    print("Subscribing to network state");
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      connectionStatus = result;
      ref.read(connectivityProvider.notifier).updateConnectivityState(result);
      // onConnectionStateChanged(result);
      networkBanner(context, connectionStatus);

      print("RESULT $result");
    });
  }

  /// Function to check and update the current status of connectivity
  /// Returns a [bool] which shows if network is available or not
  Future<bool> checkForConnectivity(BuildContext context) async {
    ConnectivityResult status = await Connectivity().checkConnectivity();
    connectionStatus = status;
    if (NetworkManager().connectionStatus == ConnectivityResult.none) {
      // ignore: use_build_context_synchronously
      customSnackBar(
        context,
        "Please connect to a network and proceed.",
      );
      return false;
    } else {
      return true;
    }
  }
}
