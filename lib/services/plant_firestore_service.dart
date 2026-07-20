import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/plant.dart';

class PlantFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _plantsRef {
    return _db.collection('users').doc(uid).collection('plants');
  }

  Stream<List<Plant>> streamPlants() {
    if (uid == null) return Stream.value([]);

    return _plantsRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final plantType = data['plantType'] ?? 'tomato';

          return Plant(
            id: doc.id,
            deviceId: data['deviceId'] ?? 'esp32_001',
            plantType: plantType,
            soilMoisture: (data['soilMoisture'] ?? 0).toDouble(),
            temperature: (data['temperature'] ?? 0).toDouble(),
            humidity: (data['humidity'] ?? 0).toDouble(),
            light: (data['light'] ?? 0).toDouble(),
            pumpOn: data['pumpOn'] ?? false,
            dryThreshold: (data['dryThreshold'] ?? 1200).toDouble(),
            tempThreshold: (data['tempThreshold'] ?? 28).toDouble(),
          );
        }).toList();
      },
    );
  }

  Future<String?> addPlant({
    required String plantType,
  }) async {
    if (uid == null) return 'Please sign in first.';

    final duplicate = await _plantsRef
        .where('plantType', isEqualTo: plantType)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      return '${Plant.displayName(plantType)} already added.';
    }

    await _plantsRef.add({
      'deviceId': 'esp32_001',
      'plantType': plantType,
      'soilMoisture': 0,
      'temperature': 0,
      'humidity': 0,
      'pumpOn': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return null;
  }

  Future<String?> updatePlant({
    required String plantId,
    required String plantType,
  }) async {
    if (uid == null) return 'Please sign in first.';

    final duplicate = await _plantsRef
        .where('plantType', isEqualTo: plantType)
        .limit(5)
        .get();

    final exists = duplicate.docs.any((doc) => doc.id != plantId);

    if (exists) {
      return '${Plant.displayName(plantType)} already added.';
    }

    await _plantsRef.doc(plantId).set({
      'deviceId': 'esp32_001',
      'plantType': plantType,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return null;
  }

  Future<void> deletePlant(String plantId) async {
    if (uid == null) return;
    await _plantsRef.doc(plantId).delete();
  }

  Future<void> syncLiveSnapshot({
    required double soilMoisture,
    required double temperature,
    required double humidity,
    required double light,
    required bool pumpOn,
  }) async {
    if (uid == null) return;

    final snapshot = await _plantsRef.get();

    for (final doc in snapshot.docs) {
      await doc.reference.set({
        'soilMoisture': soilMoisture,
        'temperature': temperature,
        'humidity': humidity,
        'light': light,
        'pumpOn': pumpOn,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteAllUserData() async {
    if (uid == null) return;

    final diagnosesSnapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('diagnoses')
        .get();

    for (final doc in diagnosesSnapshot.docs) {
      await doc.reference.delete();
    }

    final plantsSnapshot = await _plantsRef.get();

    for (final doc in plantsSnapshot.docs) {
      await doc.reference.delete();
    }

    await _db.collection('users').doc(uid).delete();
  }
}