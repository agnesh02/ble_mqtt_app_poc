// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/models/ble/device_connection_state.dart';
import 'package:ble_mqtt_app/providers/ble/ble_data_provider.dart';
import 'package:ble_mqtt_app/providers/ble/ble_provider.dart';
import 'package:ble_mqtt_app/viewModels/ble_viewmodel.dart';
import 'package:ble_mqtt_app/widgets/ble/ble_device_header.dart';
import 'package:ble_mqtt_app/widgets/ble/time_picker.dart';
import 'package:ble_mqtt_app/widgets/common/custom_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// To reuse across elevated buttons in this screen
final elevatedButtonStyle = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

class BleInteractionScreen extends ConsumerStatefulWidget {
  const BleInteractionScreen({
    Key? key,
    required this.device,
    required this.index,
  }) : super(key: key);

  final BluetoothDevice device;
  final int index;

  @override
  ConsumerState<BleInteractionScreen> createState() =>
      _BleInteractionScreenState();
}

class _BleInteractionScreenState extends ConsumerState<BleInteractionScreen> {
  @override
  void initState() {
    super.initState();
    BleViewModel().subscribeToCommandsAndResponses(
      widget.device,
      ref.read(edpServiceProvider)!,
      ref,
    );
  }

  /// Function to reconnect the device if it got disconnected unexpectedly
  Future<void> reconnectToDevice() async {
    print("Attempting reconnection...");
    ref.read(bleStateProvider.notifier).updateConnectionState(
          widget.device.remoteId,
          DeviceConnectionState.connecting,
        );
    await BleViewModel()
        .connectWithDevice(widget.device, ref)
        .then((isSuccess) {
      if (isSuccess) {
        customSnackBar(context,
            "Reconnected with ${widget.device.advName} successfully :)");
      } else {
        customSnackBar(
          context,
          "Pairing unsuccessful or Failed to reconnect with ${widget.device.advName} :(",
        );
      }
    });
  }

  /// Function to check and update the Elira device parameters
  Future<void> checkDeviceParameters(BluetoothService edpService) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (cntxt) => processingDialog(),
    );

    await BleViewModel()
        .checkDeviceParameters(widget.device, edpService)
        .then((result) {
      ref.read(eliraParametersProvider.notifier).state = result;
      print(result.toString());
      Navigator.of(context).pop();
    });
  }

  /// Function which builds the basic info section which consists of device parameters
  Widget basicInfoSection(BluetoothService edpService) {
    final bleState = ref.watch(bleStateProvider);
    final edpParameters = ref.watch(eliraParametersProvider);
    return Column(
      children: [
        const SizedBox(height: 20),
        BleDeviceHeader(
          deviceName: widget.device.advName,
          connectionState:
              bleState.availableBleDevices[widget.index].connectionState,
          deviceAddress: widget.device.remoteId.toString(),
          onReconnect: reconnectToDevice,
        ),
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
              onPressed: () => checkDeviceParameters(edpService),
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
      ],
    );
  }

  /// Function which renders the 'Update Current Time button' and perform the its functionality
  Widget buttonUpdateCurrentTime(BluetoothService edpService) {
    return CommandButton(
      title: "Update Current Time",
      onClick: () async {
        print("Command 1");
        showDialog(
          context: context,
          builder: (cntxt) => processingDialog(),
        );
        await BleViewModel()
            .updateDeviceTime(widget.device, edpService)
            .then((value) => Navigator.of(context).pop());
      },
    );
  }

  /// Function which renders the 'Set Therapy Schedules' button and perform the its functionality
  Widget buttonSetTherapySchedules(BluetoothService edpService) {
    return CommandButton(
      title: "Set Therapy Schedules",
      onClick: () async {
        print("Command 2");

        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (cntxt) => pickTimeDialog(
            context,
            ref,
            (slotNumber, startTime, duration) async {
              final now = DateTime.now();
              final time = DateTime(
                now.year,
                now.month,
                now.day,
                startTime.hour,
                startTime.minute,
              );
              print(time);
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (cntxt) => processingDialog(),
              );
              await BleViewModel()
                  .scheduleTherapy(
                    widget.device,
                    edpService,
                    slotNumber,
                    time,
                    duration,
                  )
                  .then((value) => Navigator.of(context).pop());
            },
          ),
        );
      },
    );
  }

  /// Function which renders the 'Show Therapy Schedules' button and perform the its functionality
  Widget buttonShowTherapySchedules(BluetoothService edpService) {
    return CommandButton(
      title: "Show Therapy Schedules",
      onClick: () async {
        showDialog(
          context: context,
          builder: (cntxt) => processingDialog(),
        );
        await BleViewModel()
            .getTherapySchedules(widget.device, edpService)
            .then((value) {
          Navigator.of(context).pop();
          _showTherapySchedules(context);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final edpService = ref.watch(edpServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("EDP Device"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            basicInfoSection(edpService!),
            const SizedBox(height: 25),
            buttonUpdateCurrentTime(edpService),
            buttonSetTherapySchedules(edpService),
            buttonShowTherapySchedules(edpService),
          ],
        ),
      ),
    );
  }
}

/// Class which is used to render a row that comes under the device parameters
class ParameterRow extends StatelessWidget {
  const ParameterRow({
    Key? key,
    required this.title,
    required this.data,
    this.bottomBorder = true,
  }) : super(key: key);

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

/// Class which is used to render the button which will be used to carry out various functionalities on the device
class CommandButton extends StatelessWidget {
  const CommandButton({
    Key? key,
    required this.title,
    required this.onClick,
  }) : super(key: key);

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

/// An alert dialog which is used to let the user know that an operation isd being done behind the scenes
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

/// A bottom modal sheet which displays the therapy information obtained from the EDP device
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

/// Function which is used to render the stored therapy information in a table format, which is later displayed using [_showTherapySchedules]
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

/// Function which renders a data row to be placed under the table
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
