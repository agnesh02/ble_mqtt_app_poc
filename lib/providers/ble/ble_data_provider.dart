import 'package:ble_mqtt_app/utils/ble/ble_operations_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Class which holds the actual data of a therapy, start time and the duration
class TherapyData {
  TherapyData({
    this.time,
    this.duration,
  });

  final DateTime? time;
  final int? duration;

  String get day {
    return DateFormat.E().format(time!);
  }

  String get date {
    return DateFormat('M/d/yyyy').format(time!);
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(time!);
  }

  String get durationTime {
    return duration.toString();
  }

  @override
  String toString() {
    String formattedTime = DateFormat.yMEd().add_jms().format(time!);
    return "Time: $formattedTime | Duration: $duration";
  }
}

/// Class which represent all the 4 therapy slots which have its own [TherapyData]
/// Used to manage the sate
class TherapySchedules {
  TherapySchedules({
    required this.slot1,
    required this.slot2,
    required this.slot3,
    required this.slot4,
  });

  final TherapyData? slot1;
  final TherapyData? slot2;
  final TherapyData? slot3;
  final TherapyData? slot4;
}

class ScheduledTherapiesNotifier extends StateNotifier<TherapySchedules> {
  ScheduledTherapiesNotifier()
      : super(
          TherapySchedules(
            slot1: TherapyData(),
            slot2: TherapyData(),
            slot3: TherapyData(),
            slot4: TherapyData(),
          ),
        );

  /// Function which is used to update a slot inside [TherapySchedules] class
  /// Results in updating the state and show it to the user
  void updateSlot(int slotNumber, List<int> slotData) {
    final timeInSlot =
        BleOperationsHelper().convertBytesToTime(slotData.sublist(4, 8));

    final durationInSlot = slotData[8];
    final therapyData = TherapyData(time: timeInSlot, duration: durationInSlot);
    late TherapySchedules newTherapySchedulesObj;

    newTherapySchedulesObj = TherapySchedules(
      slot1: slotNumber == 1 ? therapyData : state.slot1,
      slot2: slotNumber == 2 ? therapyData : state.slot2,
      slot3: slotNumber == 3 ? therapyData : state.slot3,
      slot4: slotNumber == 4 ? therapyData : state.slot4,
    );

    state = newTherapySchedulesObj;

    // switch (slotNumber) {
    //   case 1:
    //     newTherapySchedulesObj = TherapySchedules(
    //       slot1: therapyData,
    //       slot2: state.slot2,
    //       slot3: state.slot3,
    //       slot4: state.slot4,
    //     );
    //     break;
    //   case 2:
    //     newTherapySchedulesObj = TherapySchedules(
    //       slot1: state.slot1,
    //       slot2: therapyData,
    //       slot3: state.slot3,
    //       slot4: state.slot4,
    //     );
    //     break;
    //   case 3:
    //     newTherapySchedulesObj = TherapySchedules(
    //       slot1: state.slot1,
    //       slot2: state.slot2,
    //       slot3: therapyData,
    //       slot4: state.slot4,
    //     );
    //     break;

    //   case 4:
    //     newTherapySchedulesObj = TherapySchedules(
    //       slot1: state.slot1,
    //       slot2: state.slot2,
    //       slot3: state.slot3,
    //       slot4: therapyData,
    //     );
    //     break;
    // }
    // state = newTherapySchedulesObj;
  }

  // void assignFetchedTherapySchedules(
  //   List<int> slot1,
  //   List<int> slot2,
  //   List<int> slot3,
  //   List<int> slot4,
  // ) {
  //   final bleOperationsHelper = BleOperationsHelper();
  //   final timeInSlot1 = bleOperationsHelper.convertBytesToTime(slot1);
  //   final durationInSlot1 = slot1[8];

  //   final timeInSlot2 = bleOperationsHelper.convertBytesToTime(slot2);
  //   final durationInSlot2 = slot2[8];

  //   final timeInSlot3 = bleOperationsHelper.convertBytesToTime(slot3);
  //   final durationInSlot3 = slot3[8];

  //   final timeInSlot4 = bleOperationsHelper.convertBytesToTime(slot4);
  //   final durationInSlot4 = slot4[8];

  //   state = TherapySchedules(
  //     slot1: TherapyData(time: timeInSlot1, duration: durationInSlot1),
  //     slot2: TherapyData(time: timeInSlot2, duration: durationInSlot2),
  //     slot3: TherapyData(time: timeInSlot3, duration: durationInSlot3),
  //     slot4: TherapyData(time: timeInSlot4, duration: durationInSlot4),
  //   );
  // }
}

/// Provider which is used for 'show therapy schedules'
final scheduledTherapiesProvider =
    StateNotifierProvider<ScheduledTherapiesNotifier, TherapySchedules>(
  (ref) => ScheduledTherapiesNotifier(),
);
