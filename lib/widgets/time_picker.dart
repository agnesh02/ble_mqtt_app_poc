// ignore_for_file: avoid_print

import 'package:ble_mqtt_app/providers/time_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

AlertDialog pickTimeDialog(
  BuildContext context,
  WidgetRef ref,
  void Function(TimeOfDay time, int therapyDuration) scheduleTherapy,
) {
  return AlertDialog(
    title: const Text("Select Time"),
    content: SizedBox(
      height: 200,
      width: 200,
      child: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await showTimePicker(
                    initialTime: TimeOfDay.now(),
                    context: context,
                  ).then((selectedTime) {
                    print(selectedTime);
                    ref
                        .read(timingsProvider.notifier)
                        .updateStartTime(selectedTime!);
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
          ),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await showTimePicker(
                    initialTime: TimeOfDay.now(),
                    context: context,
                  ).then((selectedTime) {
                    print(selectedTime);
                    ref
                        .read(timingsProvider.notifier)
                        .updateEndTime(selectedTime!);
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
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              CircleAvatar(
                maxRadius: 25,
                child: Consumer(
                  builder: (context, ref, child) {
                    final timings = ref.watch(timingsProvider);
                    return Text(
                      calculateDuration(timings.startTime, timings.endTime)
                          .toString(),
                      style: const TextStyle(fontSize: 20),
                    );
                  },
                ),
              ),
              const Text("Duration"),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          final timings = ref.read(timingsProvider);
          scheduleTherapy(
            timings.startTime,
            calculateDuration(timings.startTime, timings.endTime),
          );
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
