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
  }) {
    List<int> packetFrame = [];

    packetFrame.add(0xA5);
    packetFrame.add(0x06);
    packetFrame.add(0x20);
    packetFrame.add(slotNumber);

    List<int> timeAsBytes = convertTimeToBytes();
    for (var i in timeAsBytes) {
      packetFrame.add(i);
    }
    packetFrame.add(durationInMinutes);
    packetFrame.add(0x00);

    print('Epoch Time: $packetFrame');
    print(packetFrame);
    convertBytesToTime(timeAsBytes);

    return packetFrame;
  }

  List<int> convertTimeToBytes() {
    DateTime time = DateTime.now();
    int epochTime = time.millisecondsSinceEpoch ~/ 1000;
    List<int> epochBytes = [];
    while (epochTime > 0) {
      epochBytes.add(epochTime & 0xFF);
      epochTime >>= 8;
    }
    epochBytes = epochBytes.reversed.toList();
    return epochBytes;
  }

  void convertBytesToTime(List<int> data) {
    // List<int> epochBytes = [101, 220, 132, 100];
    List<int> epochBytes = data;
    int epochTime = 0;
    for (int byte in epochBytes) {
      epochTime = (epochTime << 8) | byte;
    }

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(epochTime * 1000);

    print('DateTime: $dateTime');
  }
}
