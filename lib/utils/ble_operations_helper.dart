// ignore_for_file: avoid_print

class BleOperationsHelper {
  BleOperationsHelper._();
  static final _instance = BleOperationsHelper._();

  factory BleOperationsHelper() {
    return _instance;
  }

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

const uuidEdpService = "f000ee00-0451-4000-b000-000000000000";
const uuidBatteryVoltage = "f000ee03-0451-4000-b000-000000000000";
const uuidAmplitude = "f000ee04-0451-4000-b000-000000000000";
const uuidTemperature = "f000ee01-0451-4000-b000-000000000000";
const uuidCommandAndResponse = "f000ee07-0451-4000-b000-000000000000";
