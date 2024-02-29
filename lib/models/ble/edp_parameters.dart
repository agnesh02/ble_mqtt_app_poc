/// Class which holds the basic device data which comes under 'Device Parameters'
class EdpParameters {
  EdpParameters({
    required this.battery,
    required this.temperature,
    required this.amplitude,
  });

  String battery;
  String temperature;
  String amplitude;

  @override
  String toString() {
    return "Battery: $battery | Temp: $temperature | Amplitude: $amplitude";
  }
}
