class SensorReading {
  final DateTime time;
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final double light;

  SensorReading({
    required this.time,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.light,
  });
}
