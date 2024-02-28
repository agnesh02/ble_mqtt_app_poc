// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/device_connection_state.dart';
import 'package:ble_mqtt_app/providers/ble_data_provider.dart';
import 'package:ble_mqtt_app/providers/ble_provider.dart';
import 'package:ble_mqtt_app/viewModels/ble_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/ble_device_header.dart';
import 'package:ble_mqtt_app/widgets/custom_snack.dart';
import 'package:ble_mqtt_app/widgets/time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final elevatedButtonStyle = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

class BleInteractionScreen extends ConsumerWidget {
  const BleInteractionScreen({
    super.key,
    required this.device,
    required this.index,
  });

  final BluetoothDevice device;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleStateProvider);
    final edpParameters = ref.watch(eliraParametersProvider);
    final edpService = ref.watch(edpServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("EDP Device"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            BleDeviceHeader(
                deviceName: device.advName,
                connectionState:
                    bleState.availableBleDevices[index].connectionState,
                deviceAddress: device.remoteId.toString(),
                onReconnect: () async {
                  print("Attempting reconnection...");
                  // await device.disconnect();
                  ref.read(bleStateProvider.notifier).updateConnectionState(
                        device.remoteId,
                        DeviceConnectionState.connecting,
                      );
                  await BleViewModel()
                      .connectWithDevice(device, ref)
                      .then((isSuccess) {
                    if (isSuccess) {
                      customSnackBar(context,
                          "Reconnected with ${device.advName} successfully :)");
                    } else {
                      customSnackBar(context,
                          "Failed to reconnect with ${device.advName} :(");
                    }
                  });
                }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Device Parameters",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
                ElevatedButton(
                  style: elevatedButtonStyle,
                  onPressed: () async {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (cntxt) => processingDialog(),
                    );

                    BleViewModel().subscribeToCommandsAndResponses(
                      device,
                      edpService!,
                      ref,
                    );

                    await BleViewModel()
                        .checkDeviceParameters(device, edpService)
                        .then((result) {
                      ref.read(eliraParametersProvider.notifier).state = result;
                      print(result.toString());
                      Navigator.of(context).pop();
                    });
                  },
                  child: const Text("Check"),
                )
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ParameterRow(
                    title: "Battery Voltage",
                    data: edpParameters.battery,
                  ),
                  ParameterRow(
                    title: "Temperature",
                    data: edpParameters.temperature,
                  ),
                  ParameterRow(
                    title: "Amplitude",
                    data: edpParameters.amplitude,
                    bottomBorder: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            CommandButton(
              title: "Update Current Time",
              onClick: () {
                print("Command 1");
                showDialog(
                  context: context,
                  builder: (cntxt) => processingDialog(),
                );
                BleViewModel()
                    .updateDeviceTime(device, edpService!)
                    .then((value) => Navigator.of(context).pop());
              },
            ),
            CommandButton(
              title: "Set Therapy Schedules",
              onClick: () async {
                print("Command 2");

                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (cntxt) => pickTimeDialog(
                    context,
                    ref,
                    (startTime, duration) {
                      final now = DateTime.now();
                      final time = DateTime(now.year, now.month, now.day,
                          startTime.hour, startTime.minute);
                      print(time);
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (cntxt) => processingDialog(),
                      );
                      BleViewModel()
                          .scheduleTherapy(device, edpService!, time, duration)
                          .then((value) => Navigator.of(context).pop());
                    },
                  ),
                );
              },
            ),
            CommandButton(
              title: "Show Therapy Schedules",
              onClick: () async {
                showDialog(
                  context: context,
                  builder: (cntxt) => processingDialog(),
                );
                await BleViewModel()
                    .getTherapySchedules(device, edpService!)
                    .then((_) {
                  Navigator.of(context).pop();
                  _showTherapySchedules(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ParameterRow extends StatelessWidget {
  const ParameterRow({
    super.key,
    required this.title,
    required this.data,
    this.bottomBorder = true,
  });

  final String title;
  final String data;
  final bool bottomBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            style: bottomBorder ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$title: "),
            Text(data),
          ],
        ),
      ),
    );
  }
}

class CommandButton extends StatelessWidget {
  const CommandButton({
    super.key,
    required this.title,
    required this.onClick,
  });

  final String title;
  final void Function() onClick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        style: elevatedButtonStyle,
        onPressed: onClick,
        child: Text(title),
      ),
    );
  }
}

AlertDialog processingDialog() {
  return const AlertDialog(
    title: Text("Processing", textAlign: TextAlign.center),
    content: SizedBox(
      height: 100,
      width: 100,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );
}

void _showTherapySchedules(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (cntxt) {
      return SizedBox(
        height: 400,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_outlined),
                Text(
                  'SCHEDULED THERAPIES',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Consumer(builder: (cntxt, ref, _) {
              final therapySchedules = ref.watch(scheduledTherapiesProvider);
              return _buildTherapyScheduleTable(therapySchedules);
            }),
          ],
        ),
      );
    },
  );
}

Widget _buildTherapyScheduleTable(TherapySchedules therapySchedules) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Slot')),
        DataColumn(label: Text("Day")),
        DataColumn(label: Text("Date")),
        DataColumn(label: Text("Time")),
        DataColumn(label: Text("Duration")),
      ],
      rows: [
        _buildDataRow(therapySchedules.slot1, 1),
        _buildDataRow(therapySchedules.slot2, 2),
        _buildDataRow(therapySchedules.slot3, 3),
        _buildDataRow(therapySchedules.slot4, 4),
      ],
    ),
  );
}

DataRow _buildDataRow(TherapyData? therapyData, int slotNumber) {
  return DataRow(
    cells: [
      DataCell(Text(slotNumber.toString())),
      DataCell(Text(therapyData?.day ?? "No data")),
      DataCell(Text(therapyData?.date ?? "No data")),
      DataCell(Text(therapyData?.formattedTime ?? "No data")),
      DataCell(
        Align(
          alignment: Alignment.center,
          child: Text(
            "${therapyData?.durationTime} min",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ],
  );
}
