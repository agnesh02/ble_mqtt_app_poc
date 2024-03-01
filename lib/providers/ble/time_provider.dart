// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Class which holds the time information set by the user under 'Set therapy schedules'
/// Holds the start and end time chose by the user from [pickTimeDialog]
class ScheduleTherapyTimings {
  ScheduleTherapyTimings({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? duration,
  })  : startTime = startTime ?? TimeOfDay.now(),
        endTime = endTime ?? TimeOfDay.now(),
        duration = calculateDuration(
          startTime ?? TimeOfDay.now(),
          endTime ?? TimeOfDay.now(),
        );

  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int duration;
}

class TimingsNotifier extends StateNotifier<ScheduleTherapyTimings> {
  TimingsNotifier() : super(ScheduleTherapyTimings());

  void updateStartTime(TimeOfDay selectedStartTime) {
    updateDuration(selectedStartTime, state.endTime);
    state = ScheduleTherapyTimings(
      startTime: selectedStartTime,
      endTime: state.endTime,
      duration: state.duration,
    );
  }

  void updateEndTime(TimeOfDay selectedEndTime) {
    updateDuration(state.startTime, selectedEndTime);
    state = ScheduleTherapyTimings(
      startTime: state.startTime,
      endTime: selectedEndTime,
      duration: state.duration,
    );
  }

  void updateDuration(TimeOfDay selectedStartTime, TimeOfDay selectedEndTime) {
    final result = calculateDuration(
      selectedStartTime,
      selectedEndTime,
    );
    state = ScheduleTherapyTimings(
      startTime: selectedStartTime,
      endTime: selectedEndTime,
      duration: result,
    );
  }
}

/// Provider which handles the state of therapy timings set by the user
final timingsProvider =
    StateNotifierProvider<TimingsNotifier, ScheduleTherapyTimings>(
  (ref) => TimingsNotifier(),
);

/// Function which formats the entered time into a good readable format and returns it
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

/// Function which calculate the duration between the start and end time set by the user
int calculateDuration(TimeOfDay startTime, TimeOfDay endTime) {
  final startDateTime = DateTime(0, 0, 0, startTime.hour, startTime.minute);
  final endDateTime = DateTime(0, 0, 0, endTime.hour, endTime.minute);

  final difference = endDateTime.difference(startDateTime);

  print(difference);

  return difference.inMinutes;
}
