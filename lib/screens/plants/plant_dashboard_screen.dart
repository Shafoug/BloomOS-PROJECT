import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../state/plants_store.dart';

class PlantDashboardScreen extends StatefulWidget {
  final Plant plant;
  final bool isGuest;

  const PlantDashboardScreen({
    super.key,
    required this.plant,
    this.isGuest = false,
  });

  @override
  State<PlantDashboardScreen> createState() => _PlantDashboardScreenState();
}

class _PlantDashboardScreenState extends State<PlantDashboardScreen> {
  int selectedTab = 0;

  late final DatabaseReference _plantDataRef;
  late final DatabaseReference _pumpCommandRef;

  double _soilMoisture = 0;
  double _temperature = 0;
  double _humidity = 0;
  bool _pumpOn = false;

  String _currentSource = 'Disconnected';
  bool _currentConnected = false;

  @override
  void initState() {
    super.initState();

    _plantDataRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://bloomos-2583c-default-rtdb.firebaseio.com/',
    ).ref('devices/${widget.plant.deviceId}/plantData');

    _pumpCommandRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://bloomos-2583c-default-rtdb.firebaseio.com/',
    ).ref('devices/${widget.plant.deviceId}/plantCommands/pumpNow');

    _soilMoisture = widget.plant.soilMoisture;
    _temperature = widget.plant.temperature;
    _humidity = widget.plant.humidity;
    _pumpOn = widget.plant.pumpOn;
  }

  String getImage(String type) {
    switch (type.toLowerCase()) {
      case 'tomato':
        return 'assets/images/Tomato.jpeg';
      case 'potato':
        return 'assets/images/Potato.jpeg';
      default:
        return 'assets/images/Tomato.jpeg';
    }
  }

  bool _isRecentlyUpdated(int lastUpdated) {
    if (lastUpdated <= 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - lastUpdated) <= 30;
  }

  String getStatusLabel({
    required bool connected,
    required double soilMoisture,
    required double temperature,
  }) {
    if (!connected) return 'Disconnected';

    if (soilMoisture > widget.plant.dryThreshold ||
        temperature >= widget.plant.tempThreshold + 5) {
      return 'Critical';
    } else if (soilMoisture > (widget.plant.dryThreshold - 200) ||
        temperature >= widget.plant.tempThreshold) {
      return 'Needs Water';
    } else {
      return 'Healthy';
    }
  }

  Color getStatusColor({
    required bool connected,
    required double soilMoisture,
    required double temperature,
  }) {
    if (!connected) return Colors.grey;

    final status = getStatusLabel(
      connected: connected,
      soilMoisture: soilMoisture,
      temperature: temperature,
    );

    switch (status) {
      case 'Healthy':
        return Colors.green;
      case 'Needs Water':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _waterNow() async {
    final store = context.read<PlantsStore>();

    final bool firebaseAvailable =
        _currentSource == 'Wi-Fi / Firebase' &&
            _currentConnected &&
            !widget.isGuest;

    if (firebaseAvailable) {
      try {
        await _pumpCommandRef.set(true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Watering started via Wi-Fi')),
        );
        return;
      } catch (_) {}
    }

    final sentByBluetooth = await store.sendBluetoothCommand('PUMP_ON');

    if (sentByBluetooth) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Watering started via Bluetooth')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No connection available')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlantsStore>();

    return StreamBuilder<DatabaseEvent>(
      stream: _plantDataRef.onValue,
      builder: (context, snapshot) {
        double soilMoisture = _soilMoisture;
        double temperature = _temperature;
        double humidity = _humidity;
        bool pumpOn = _pumpOn;
        bool connected = false;
        String source = 'Disconnected';

        // Firebase first
        if (snapshot.hasData &&
            snapshot.data?.snapshot.value != null &&
            snapshot.data!.snapshot.value is Map) {
          final data = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          if (widget.plant.plantType == 'potato' && data['potato'] is Map) {
            final potato = Map<dynamic, dynamic>.from(data['potato']);
            soilMoisture =
                ((potato['soilMoisture'] ?? _soilMoisture) as num).toDouble();
          } else if (widget.plant.plantType == 'tomato' &&
              data['tomato'] is Map) {
            final tomato = Map<dynamic, dynamic>.from(data['tomato']);
            soilMoisture =
                ((tomato['soilMoisture'] ?? _soilMoisture) as num).toDouble();
          } else {
            soilMoisture =
                ((data['soilMoisture'] ?? _soilMoisture) as num).toDouble();
          }

          temperature =
              ((data['temperature'] ?? _temperature) as num).toDouble();
          humidity = ((data['humidity'] ?? _humidity) as num).toDouble();
          pumpOn = data['pumpOn'] ?? _pumpOn;

          final lastUpdated = (data['lastUpdated'] ?? 0) as int;
          final deviceConnected = data['deviceConnected'] == true;

          connected = deviceConnected && _isRecentlyUpdated(lastUpdated);
          source = connected ? 'Wi-Fi / Firebase' : 'Disconnected';
        }

        // Bluetooth fallback
        if (!connected && store.hasFreshBluetoothData) {
          if (widget.plant.plantType == 'potato') {
            soilMoisture = store.bluetoothPotatoSoil;
          } else {
            soilMoisture = store.bluetoothTomatoSoil > 0
                ? store.bluetoothTomatoSoil
                : store.bluetoothSoilMoisture;
          }

          temperature = store.bluetoothTemperature;
          humidity = store.bluetoothHumidity;
          pumpOn = store.bluetoothPumpOn;
          connected = true;
          source = 'Bluetooth';
        }

        _currentSource = source;
        _currentConnected = connected;

        return _buildPage(
          soilMoisture: soilMoisture,
          temperature: temperature,
          humidity: humidity,
          pumpOn: pumpOn,
          connected: connected,
          source: source,
        );
      },
    );
  }

  Widget _buildPage({
    required double soilMoisture,
    required double temperature,
    required double humidity,
    required bool pumpOn,
    required bool connected,
    required String source,
  }) {
    final statusLabel = getStatusLabel(
      connected: connected,
      soilMoisture: soilMoisture,
      temperature: temperature,
    );

    final statusColor = getStatusColor(
      connected: connected,
      soilMoisture: soilMoisture,
      temperature: temperature,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 20),
              _topInfo(statusLabel, statusColor, source),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  tabItem('Overview', 0),
                  const SizedBox(width: 24),
                  tabItem('History', 1),
                ],
              ),
              const Divider(),
              Expanded(
                child: selectedTab == 0
                    ? overview(
                  soilMoisture,
                  temperature,
                  humidity,
                  pumpOn,
                  connected,
                  source,
                )
                    : history(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context, true),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF3DA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back),
          ),
        ),
        const Expanded(
          child: Text(
            'Plant Details',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _topInfo(String statusLabel, Color statusColor, String source) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAF7),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              getImage(widget.plant.plantType),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.local_florist_outlined,
                  size: 60,
                  color: Colors.green,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          Plant.displayName(widget.plant.plantType),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Source: $source',
          style: const TextStyle(
            color: Color(0xFF6F8E69),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget overview(
      double moisture,
      double temp,
      double humidity,
      bool pumpOn,
      bool connected,
      String source,
      ) {
    final bool canWater = connected;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Current Data',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: dataCard(
                  'Moisture',
                  connected ? moisture.toStringAsFixed(0) : '--',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: dataCard(
                  'Temperature',
                  connected ? '${temp.toStringAsFixed(1)}°C' : '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: dataCard(
                  'Humidity',
                  connected ? '${humidity.toStringAsFixed(0)}%' : '--',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: dataCard(
                  'Pump',
                  connected ? (pumpOn ? 'ON' : 'OFF') : '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canWater ? _waterNow : null,
              icon: const Icon(Icons.water_drop_outlined),
              label: const Text('Watering Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7ED957),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            connected
                ? 'This action will use $source'
                : 'Connect Bluetooth or Wi-Fi first',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6F8E69),
            ),
          ),
        ],
      ),
    );
  }

  Widget history() {
    return const Center(
      child: Text(
        'History will appear here later',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget tabItem(String text, int index) {
    final active = selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              color: active ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 3,
            color: active ? Colors.green : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget dataCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}