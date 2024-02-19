import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
    networkBanner(
  BuildContext context,
  ConnectivityResult connectionStatus,
) {
  String connectionStatusText = 'Unknown';
  Color connectionStatusColor = Colors.grey;

  switch (connectionStatus) {
    case ConnectivityResult.wifi:
      connectionStatusText = 'Wi-Fi';
      connectionStatusColor = Colors.green;
      break;
    case ConnectivityResult.mobile:
      connectionStatusText = 'Mobile';
      connectionStatusColor = Colors.green;
      break;
    case ConnectivityResult.none:
      connectionStatusText = 'No Internet';
      connectionStatusColor = Colors.red;
      break;
    default:
      connectionStatusText = 'Unknown';
      break;
  }

  ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

  return scaffoldMessenger.showMaterialBanner(
    MaterialBanner(
      padding: const EdgeInsets.all(20),
      content: Text(
        'Connection Status:\n$connectionStatusText',
        style: const TextStyle(color: Colors.white),
      ),
      leading: const Icon(Icons.signal_wifi_bad_rounded),
      backgroundColor: connectionStatusColor,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            scaffoldMessenger.clearMaterialBanners();
          },
          child: const Text(
            'DISMISS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
