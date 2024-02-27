// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// final startTimeProvider = StateProvider((ref) => TimeOfDay.now());
// final endTimeProvider = StateProvider((ref) => TimeOfDay.now());

class ScheduleTherapyTimings {
  ScheduleTherapyTimings({
    this.startTime = const TimeOfDay(hour: 3, minute: 15),
    this.endTime = const TimeOfDay(hour: 3, minute: 30),
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;
}

class TimingsNotifier extends StateNotifier<ScheduleTherapyTimings> {
  TimingsNotifier() : super(ScheduleTherapyTimings());

  void updateStartTime(TimeOfDay selectedStartTime) {
    state = ScheduleTherapyTimings(
        startTime: selectedStartTime, endTime: state.endTime);
  }

  void updateEndTime(TimeOfDay selectedEndTime) {
    state = ScheduleTherapyTimings(
        startTime: state.startTime, endTime: selectedEndTime);
  }
}

final timingsProvider =
    StateNotifierProvider<TimingsNotifier, ScheduleTherapyTimings>(
  (ref) => TimingsNotifier(),
);

String displayTiming(BuildContext context, TimeOfDay time) {
  final now = DateTime.now();

  final dateTime = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );

  final formattedTime = TimeOfDay.fromDateTime(dateTime).format(context);
  return formattedTime;
}

int calculateDuration(TimeOfDay startTime, TimeOfDay endTime) {
  final startDateTime = DateTime(0, 0, 0, startTime.hour, startTime.minute);
  final endDateTime = DateTime(0, 0, 0, endTime.hour, endTime.minute);

  final difference = endDateTime.difference(startDateTime);

  print(difference);

  return difference.inMinutes;
}
