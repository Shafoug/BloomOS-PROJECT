class Plant {
  final String id;
  final String deviceId;

  String plantType;

  double soilMoisture;
  double temperature;
  double humidity;
  double light;
  bool pumpOn;

  double dryThreshold;
  double tempThreshold;

  Plant({
    required this.id,
    required this.deviceId,
    required this.plantType,
    this.soilMoisture = 0,
    this.temperature = 0,
    this.humidity = 0,
    this.light = 0,
    this.pumpOn = false,
    this.dryThreshold = 1200,
    this.tempThreshold = 28,
  });

  static String displayName(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'tomato':
        return 'Tomato';
      case 'potato':
        return 'Potato';
      default:
        return 'Plant';
    }
  }

  static String displayType(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'tomato':
        return 'Fruit';
      case 'potato':
        return 'Vegetable';
      default:
        return 'Plant';
    }
  }

  static double defaultDryThreshold(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'tomato':
        return 1200;
      case 'potato':
        return 1300;
      default:
        return 1200;
    }
  }

  static double defaultTempThreshold(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'tomato':
        return 28;
      case 'potato':
        return 25;
      default:
        return 28;
    }
  }

  String get statusLabel {
    if (soilMoisture > dryThreshold || temperature >= tempThreshold + 5) {
      return 'Critical';
    } else if (soilMoisture > (dryThreshold - 200) ||
        temperature >= tempThreshold) {
      return 'Needs Water';
    } else {
      return 'Healthy';
    }
  }

  bool get isHealthy => statusLabel == 'Healthy';
}