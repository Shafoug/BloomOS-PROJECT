import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';

import '../../state/plants_store.dart';

class DeviceSetupScreen extends StatefulWidget {
  final bool isGuest;

  const DeviceSetupScreen({
    super.key,
    this.isGuest = false,
  });

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  BluetoothConnection? _connection;
  List<BluetoothDevice> _bondedDevices = [];

  final TextEditingController _wifiNameController = TextEditingController();
  final TextEditingController _wifiPasswordController =
  TextEditingController();

  bool _isBluetoothEnabled = false;
  bool _isLoadingDevices = false;
  bool _isConnecting = false;
  bool _isConnected = false;

  String? _connectedDeviceName;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  @override
  void dispose() {
    _wifiNameController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    try {
      final enabled = await _bluetooth.isEnabled ?? false;

      if (!mounted) return;

      setState(() {
        _isBluetoothEnabled = enabled;
      });

      if (enabled) {
        await _loadBondedDevices();
      }
    } catch (e) {
      _showMessage('Bluetooth init failed: $e');
    }
  }

  Future<void> _enableBluetooth() async {
    try {
      await _bluetooth.requestEnable();

      final enabled = await _bluetooth.isEnabled ?? false;

      if (!mounted) return;

      setState(() {
        _isBluetoothEnabled = enabled;
      });

      if (enabled) {
        await _loadBondedDevices();
      }
    } catch (e) {
      _showMessage('Failed to enable Bluetooth: $e');
    }
  }

  Future<void> _loadBondedDevices() async {
    setState(() {
      _isLoadingDevices = true;
    });

    try {
      final devices = await _bluetooth.getBondedDevices();

      if (!mounted) return;

      setState(() {
        _bondedDevices = devices;
      });
    } catch (e) {
      _showMessage('Failed to load paired devices: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDevices = false;
        });
      }
    }
  }

  Future<void> _sendCommandRaw(String command) async {
    if (_connection == null || !_isConnected) {
      throw Exception('No device connected');
    }

    _connection!.output.add(utf8.encode('$command\n'));
    await _connection!.output.allSent;
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      await _connection?.close();

      final connection = await BluetoothConnection.toAddress(device.address);

      if (!mounted) return;

      setState(() {
        _connection = connection;
        _isConnected = true;
        _connectedDeviceName = device.name ?? 'ESP32 Device';
      });

      context.read<PlantsStore>().attachBluetooth(_sendCommandRaw);

      _showMessage('Connected to ${device.name ?? device.address}');

      connection.input?.listen(
            (data) {
          final incoming = utf8.decode(data, allowMalformed: true).trim();

          if (incoming.isNotEmpty) {
            debugPrint('ESP says: $incoming');

            if (!mounted) return;

            context
                .read<PlantsStore>()
                .updateBluetoothLiveDataFromPacket(incoming);
          }
        },
        onDone: () {
          if (!mounted) return;

          setState(() {
            _isConnected = false;
            _connectedDeviceName = null;
            _connection = null;
          });

          context.read<PlantsStore>().detachBluetooth();
        },
      );
    } catch (e) {
      _showMessage('Connection failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await _connection?.close();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _connection = null;
      _isConnected = false;
      _connectedDeviceName = null;
    });

    context.read<PlantsStore>().detachBluetooth();

    _showMessage('Disconnected');
  }

  Future<void> _sendWifiCredentials() async {
    final ssid = _wifiNameController.text.trim();
    final password = _wifiPasswordController.text.trim();

    if (ssid.isEmpty || password.isEmpty) {
      _showMessage('Enter Wi-Fi name and password first');
      return;
    }

    try {
      await _sendCommandRaw('WIFI_SETUP:$ssid|$password');
      _showMessage('Wi-Fi sent to ESP32');
    } catch (e) {
      _showMessage('Failed to send Wi-Fi: $e');
    }
  }

  void _showDevicePicker() {
    if (!_isBluetoothEnabled) {
      _showMessage('Please enable Bluetooth first');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF4F7F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        if (_isLoadingDevices) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (_bondedDevices.isEmpty) {
          return SizedBox(
            height: 240,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No paired Bluetooth devices found.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pair your ESP32 from phone Bluetooth settings first.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadBondedDevices();
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _bondedDevices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final device = _bondedDevices[index];

                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF5E8),
                    child: Icon(
                      Icons.bluetooth,
                      color: Color(0xFF4F9B57),
                    ),
                  ),
                  title: Text(device.name ?? 'Unknown Device'),
                  subtitle: Text(device.address),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    Navigator.pop(context);
                    await _connectToDevice(device);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlantsStore>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F3),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Device Setup',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _actionTile(
            icon: Icons.bluetooth,
            title: _isConnected ? 'Bluetooth Connected' : 'Bluetooth Pairing',
            subtitle: _isConnected
                ? 'Connected to $_connectedDeviceName'
                : 'Choose a paired ESP32 device',
            onTap: _showDevicePicker,
          ),

          if (!widget.isGuest) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wi-Fi Setup',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Send Wi-Fi credentials to ESP32 for Firebase sync.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6F8E69),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _wifiNameController,
                    decoration: const InputDecoration(
                      labelText: 'Wi-Fi Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _wifiPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Wi-Fi Password',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isConnected ? _sendWifiCredentials : null,
                      child: const Text('Send Wi-Fi to ESP32'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isBluetoothEnabled ? _showDevicePicker : _enableBluetooth,
              child: Text(
                _isBluetoothEnabled ? 'Bluetooth Pairing' : 'Enable Bluetooth',
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (_isConnected)
            SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: _disconnectDevice,
                child: const Text('Disconnect'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusCard(PlantsStore store) {
    final bool btLive = store.hasFreshBluetoothData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _isConnected
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFF1F3F2),
            child: Icon(
              _isConnected ? Icons.check_circle : Icons.link_off,
              color: _isConnected ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Device Connected' : 'No Device Connected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  btLive
                      ? 'Bluetooth live data is active'
                      : (_isConnected
                      ? (_connectedDeviceName ?? 'ESP32 connected')
                      : 'Pair from system Bluetooth settings first'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEAF5E8),
                child: Icon(
                  icon,
                  color: const Color(0xFF4F9B57),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}