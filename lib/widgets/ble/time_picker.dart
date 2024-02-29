// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/providers/ble/time_provider.dart';
import 'package:ble_mqtt_app/widgets/ble/slot_drop_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Custom alert dialog which allows the users to set a therapy schedule to the device
/// after making their desired input
AlertDialog pickTimeDialog(
  BuildContext context,
  WidgetRef ref,
  void Function(int slotNumber, TimeOfDay time, int therapyDuration)
      scheduleTherapy,
) {
  int selectedSlotNumber = 1;

  return AlertDialog(
    title: const Text("Select Time"),
    content: SizedBox(
      height: 240,
      width: 200,
      child: Column(
        children: [
          _buildTimeSelectionRow(ref, selectedSlotNumber, context),
          _buildStartTimeRow(ref, context),
          _buildEndTimeRow(ref, context),
          const SizedBox(height: 20),
          _buildDurationWidget(ref),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          _scheduleTherapy(ref, scheduleTherapy, selectedSlotNumber);
        },
        child: const Text("Schedule Therapy"),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text("Cancel"),
      ),
    ],
  );
}

Widget _buildTimeSelectionRow(
    WidgetRef ref, int selectedSlotNumber, BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TextButton(
        onPressed: () {},
        child: const Text(
          "Slot :",
          style: TextStyle(fontSize: 20),
        ),
      ),
      SlotDropdown(
        onSelection: (value) => selectedSlotNumber = value,
      ),
    ],
  );
}

Widget _buildStartTimeRow(WidgetRef ref, BuildContext context) {
  return Row(
    children: [
      TextButton(
        onPressed: () async {
          await showTimePicker(
            initialTime: TimeOfDay.now(),
            context: context,
          ).then((selectedTime) {
            print(selectedTime);
            ref.read(timingsProvider.notifier).updateStartTime(selectedTime!);
          });
        },
        child: const Text(
          "Start Time :",
          style: TextStyle(fontSize: 20),
        ),
      ),
      Consumer(
        builder: (context, ref, child) {
          final timings = ref.watch(timingsProvider);
          return Text(
            displayTiming(context, timings.startTime),
            style: const TextStyle(fontSize: 20),
          );
        },
      ),
    ],
  );
}

Widget _buildEndTimeRow(WidgetRef ref, BuildContext context) {
  return Row(
    children: [
      TextButton(
        onPressed: () async {
          await showTimePicker(
            initialTime: TimeOfDay.now(),
            context: context,
          ).then((selectedTime) {
            print(selectedTime);
            ref.read(timingsProvider.notifier).updateEndTime(selectedTime!);
          });
        },
        child: const Text(
          "End Time   :",
          style: TextStyle(fontSize: 20),
        ),
      ),
      Consumer(
        builder: (context, ref, child) {
          final timings = ref.watch(timingsProvider);
          return Text(
            displayTiming(context, timings.endTime),
            style: const TextStyle(fontSize: 20),
          );
        },
      ),
    ],
  );
}

Widget _buildDurationWidget(WidgetRef ref) {
  return Column(
    children: [
      CircleAvatar(
        maxRadius: 25,
        child: Consumer(
          builder: (context, ref, child) {
            final timings = ref.watch(timingsProvider);
            return Text(
              calculateDuration(timings.startTime, timings.endTime).toString(),
              style: const TextStyle(fontSize: 20),
            );
          },
        ),
      ),
      const Text("Duration"),
    ],
  );
}

void _scheduleTherapy(
    WidgetRef ref,
    void Function(int slotNumber, TimeOfDay time, int therapyDuration)
        scheduleTherapy,
    int selectedSlotNumber) {
  final timings = ref.read(timingsProvider);
  scheduleTherapy(
    selectedSlotNumber,
    timings.startTime,
    calculateDuration(timings.startTime, timings.endTime),
  );
}
