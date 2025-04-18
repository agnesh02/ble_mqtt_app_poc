// ignore_for_file: avoid_print

/// Class which helps in providing some additional functions needed for BLE operations
class BleOperationsHelper {
  BleOperationsHelper._();
  static final _instance = BleOperationsHelper._();

  factory BleOperationsHelper() {
    return _instance;
  }

  /// Function which takes the data from the app to
  /// generate a packet frame as required by the EDP
  List<int> generateTherapySchedulePacketFrame({
    required int slotNumber,
    required int durationInMinutes,
    required DateTime startTime,
  }) {
    List<int> packetFrame = [];

    packetFrame.add(0xA5);
    packetFrame.add(0x06);
    packetFrame.add(0x20);
    packetFrame.add(slotNumber);

    List<int> timeAsBytes = convertTimeToBytes(startTime);
    for (var i in timeAsBytes) {
      packetFrame.add(i);
    }
    packetFrame.add(durationInMinutes);
    packetFrame.add(0x00);

    print(packetFrame);
    convertBytesToTime(timeAsBytes);

    return packetFrame;
  }

  /// Function which is used to convert the time to epoch time
  /// and then into bytes as required by the EDP device
  List<int> convertTimeToBytes(DateTime time) {
    int epochTime = time.millisecondsSinceEpoch ~/ 1000;
    List<int> epochBytes = [];
    while (epochTime > 0) {
      epochBytes.add(epochTime & 0xFF);
      epochTime >>= 8;
    }
    epochBytes = epochBytes.reversed.toList();
    return epochBytes;
  }

  /// Function which is used to convert back the bytes received from the EDP device
  /// as epoch time and then back into a DateTime format
  DateTime convertBytesToTime(List<int> data) {
    // List<int> epochBytes = [101, 220, 132, 100];
    List<int> epochBytes = data;
    int epochTime = 0;
    for (int byte in epochBytes) {
      epochTime = (epochTime << 8) | byte;
    }

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(epochTime * 1000);
    print('DateTime: $dateTime');

    return dateTime;
  }
}
