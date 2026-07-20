import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/plant_firestore_service.dart';

class PlantsStore extends ChangeNotifier {
  final PlantFirestoreService _service = PlantFirestoreService();

  List<Plant> plants = [];
  StreamSubscription<List<Plant>>? _plantsSubscription;

  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  bool cloudSyncEnabled = true;

  bool hasFreshBluetoothData = false;

  double bluetoothSoilMoisture = 0;
  double bluetoothTomatoSoil = 0;
  double bluetoothPotatoSoil = 0;
  double bluetoothTemperature = 0;
  double bluetoothHumidity = 0;
  bool bluetoothPumpOn = false;
  bool bluetoothAutoPump = true;
  bool bluetoothCloudOnline = false;
  String bluetoothSource = 'Bluetooth';

  Future<void> Function(String command)? _sendCommand;

  String _normalizePlant(String value) {
    return value.trim().toLowerCase();
  }

  Future<void> refreshAfterAuthChange() async {
    await listenToPlants();
  }

  Future<void> clearForGuest() async {
    await _plantsSubscription?.cancel();
    _plantsSubscription = null;
    plants = [];
    hasFreshBluetoothData = false;
    _sendCommand = null;
    notifyListeners();
  }

  Future<void> listenToPlants() async {
    await _plantsSubscription?.cancel();

    if (!isSignedIn || !cloudSyncEnabled) {
      notifyListeners();
      return;
    }

    _plantsSubscription = _service.streamPlants().listen((data) {
      plants = data;
      notifyListeners();
    });
  }

  Future<String?> addPlant({
    required String plantType,
  }) async {
    final selected = _normalizePlant(plantType);

    final exists = plants.any(
          (p) => _normalizePlant(p.plantType) == selected,
    );

    if (exists) {
      return '${Plant.displayName(selected)} already added.';
    }

    final plant = Plant(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      deviceId: 'esp32_001',
      plantType: selected,
      dryThreshold: Plant.defaultDryThreshold(selected),
      tempThreshold: Plant.defaultTempThreshold(selected),
    );

    plants.insert(0, plant);
    notifyListeners();

    if (isSignedIn && cloudSyncEnabled) {
      unawaited(
        _service.addPlant(plantType: selected).catchError((e) {
          debugPrint('Firebase addPlant error: $e');
          return null;
        }),
      );
    }

    return null;
  }

  Future<String?> updatePlant({
    required String plantId,
    required String plantType,
  }) async {
    final selected = _normalizePlant(plantType);

    final exists = plants.any(
          (p) => p.id != plantId && _normalizePlant(p.plantType) == selected,
    );

    if (exists) {
      return '${Plant.displayName(selected)} already added.';
    }

    final index = plants.indexWhere((p) => p.id == plantId);

    if (index != -1) {
      final old = plants[index];

      plants[index] = Plant(
        id: plantId,
        deviceId: old.deviceId,
        plantType: selected,
        soilMoisture: old.soilMoisture,
        temperature: old.temperature,
        humidity: old.humidity,
        light: old.light,
        pumpOn: old.pumpOn,
        dryThreshold: Plant.defaultDryThreshold(selected),
        tempThreshold: Plant.defaultTempThreshold(selected),
      );

      notifyListeners();
    }

    if (isSignedIn && cloudSyncEnabled) {
      unawaited(
        _service
            .updatePlant(
          plantId: plantId,
          plantType: selected,
        )
            .catchError((e) {
          debugPrint('Firebase updatePlant error: $e');
          return null;
        }),
      );
    }

    return null;
  }

  Future<void> deletePlant(String plantId) async {
    plants.removeWhere((p) => p.id == plantId);
    notifyListeners();

    if (isSignedIn && cloudSyncEnabled) {
      unawaited(
        _service.deletePlant(plantId).catchError((e) {
          debugPrint('Firebase deletePlant error: $e');
        }),
      );
    }
  }

  void attachBluetooth(Future<void> Function(String command) sendCommand) {
    _sendCommand = sendCommand;
    notifyListeners();
  }

  void detachBluetooth() {
    _sendCommand = null;
    hasFreshBluetoothData = false;
    bluetoothCloudOnline = false;
    bluetoothSource = 'Disconnected';
    notifyListeners();
  }

  Future<bool> sendBluetoothCommand(String command) async {
    if (_sendCommand == null) return false;

    try {
      await _sendCommand!(command);
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateBluetoothLiveDataFromPacket(String packet) {
    if (!packet.startsWith('DATA:')) return;

    final parts = packet.substring(5).split(',');

    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length != 2) continue;

      final key = kv[0].trim();
      final value = kv[1].trim();

      if (key == 'soil') {
        bluetoothSoilMoisture =
            double.tryParse(value) ?? bluetoothSoilMoisture;
      } else if (key == 'tomatoSoil') {
        bluetoothTomatoSoil =
            double.tryParse(value) ?? bluetoothTomatoSoil;
      } else if (key == 'potatoSoil') {
        bluetoothPotatoSoil =
            double.tryParse(value) ?? bluetoothPotatoSoil;
      } else if (key == 'temp') {
        bluetoothTemperature =
            double.tryParse(value) ?? bluetoothTemperature;
      } else if (key == 'hum') {
        bluetoothHumidity =
            double.tryParse(value) ?? bluetoothHumidity;
      } else if (key == 'pump') {
        bluetoothPumpOn = value == '1';
      } else if (key == 'auto') {
        bluetoothAutoPump = value == '1';
      } else if (key == 'cloud') {
        bluetoothCloudOnline = value == '1';
      } else if (key == 'source') {
        bluetoothSource = value;
      }
    }

    if (bluetoothCloudOnline) {
      bluetoothSource = 'Wi-Fi / Firebase';
    } else {
      bluetoothSource = 'Bluetooth';
    }

    hasFreshBluetoothData = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _plantsSubscription?.cancel();
    super.dispose();
  }
}