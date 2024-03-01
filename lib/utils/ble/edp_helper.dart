class EdpHelper {
  static const uuidEdpService = "f000ee00-0451-4000-b000-000000000000";
  static const uuidBatteryVoltage = "f000ee03-0451-4000-b000-000000000000";
  static const uuidAmplitude = "f000ee04-0451-4000-b000-000000000000";
  static const uuidTemperature = "f000ee01-0451-4000-b000-000000000000";
  static const uuidCommandAndResponse = "f000ee07-0451-4000-b000-000000000000";

  static const commandGetDeviceTime = [0xA5, 0x00, 0x25, 0x00, 0x00];
  static const commandGetTherapySchedules = [0xA5, 0x00, 0x24, 0x00, 0x00];
}
