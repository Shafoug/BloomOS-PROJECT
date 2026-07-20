import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../navigation/main_navigation.dart';
import '../../services/auth_service.dart';
import '../../state/plants_store.dart';
import '../auth/login_screen.dart';
import '../device/device_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _humidityAlertKey = 'humidity_alert_enabled';
  static const String _tempAlertKey = 'temp_alert_enabled';
  static const String _wateringConfirmKey = 'watering_confirmation_enabled';
  static const String _cloudSyncKey = 'cloud_sync_enabled';
  static const String _autoPumpKey = 'auto_pump_enabled';

  bool _humidityAlert = true;
  bool _tempAlert = false;
  bool _wateringConfirm = true;
  bool _cloudSync = true;
  bool _autoPumpEnabled = true;

  bool _isLoadingSettings = true;

  bool get _isGuest => !AuthService().isSignedIn;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _humidityAlert = prefs.getBool(_humidityAlertKey) ?? true;
      _tempAlert = prefs.getBool(_tempAlertKey) ?? false;
      _wateringConfirm = prefs.getBool(_wateringConfirmKey) ?? true;
      _cloudSync = prefs.getBool(_cloudSyncKey) ?? true;
      _autoPumpEnabled = prefs.getBool(_autoPumpKey) ?? true;
      _isLoadingSettings = false;
    });

    final store = context.read<PlantsStore>();
    store.cloudSyncEnabled = _cloudSync;
    await store.listenToPlants();
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _updateHumidityAlert(bool value) async {
    setState(() => _humidityAlert = value);
    await _saveBool(_humidityAlertKey, value);
  }

  Future<void> _updateTempAlert(bool value) async {
    setState(() => _tempAlert = value);
    await _saveBool(_tempAlertKey, value);
  }

  Future<void> _updateWateringConfirm(bool value) async {
    setState(() => _wateringConfirm = value);
    await _saveBool(_wateringConfirmKey, value);
  }

  Future<void> _updateCloudSync(bool value) async {
    final store = context.read<PlantsStore>();

    setState(() => _cloudSync = value);
    await _saveBool(_cloudSyncKey, value);

    store.cloudSyncEnabled = value;
    await store.listenToPlants();

    await store.sendBluetoothCommand(value ? 'CLOUD_ON' : 'CLOUD_OFF');
  }

  Future<void> _updateAutoPump(bool value) async {
    final store = context.read<PlantsStore>();

    setState(() => _autoPumpEnabled = value);
    await _saveBool(_autoPumpKey, value);

    await store.sendBluetoothCommand(value ? 'AUTO_ON' : 'AUTO_OFF');

    try {
      await FirebaseDatabase.instance
          .ref('devices/esp32_001/settings')
          .update({'autoPumpEnabled': value});
    } catch (_) {}
  }

  Future<void> _logout() async {
    final plantsStore = context.read<PlantsStore>();

    await AuthService().signOut();
    await plantsStore.clearForGuest();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(isGuest: true),
      ),
          (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final plantsStore = context.read<PlantsStore>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await AuthService().deleteAccount();

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    await plantsStore.clearForGuest();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(isGuest: true),
      ),
          (route) => false,
    );
  }

  void _goToSignIn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openDeviceSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceSetupScreen(isGuest: _isGuest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF4F7F3),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _sectionHeader('DEVICE'),
          _buildActionTile(
            'Device Setup',
            Colors.black,
            _openDeviceSetup,
            subtitle: _isGuest
                ? 'Connect ESP32 via Bluetooth'
                : 'Connect ESP32 and configure Wi-Fi',
          ),

          if (!_isGuest) ...[
            _sectionHeader('ALERTS'),
            _buildSwitch(
              'Humidity',
              'Notify when humidity becomes low',
              _humidityAlert,
              _updateHumidityAlert,
            ),
            _buildSwitch(
              'Temperature',
              'Notify when temperature is high',
              _tempAlert,
              _updateTempAlert,
            ),
            _sectionHeader('AUTOMATION'),
            _buildSwitch(
              'Auto Pump',
              'Enable automatic watering from ESP32',
              _autoPumpEnabled,
              _updateAutoPump,
            ),
          ],

          _sectionHeader('AUTOMATION'),
          _buildSwitch(
            'Watering Confirmation',
            'Confirm before watering',
            _wateringConfirm,
            _updateWateringConfirm,
          ),

          if (!_isGuest) ...[
            _sectionHeader('CLOUD'),
            _buildSwitch(
              'Cloud Sync',
              'Sync data with Firebase',
              _cloudSync,
              _updateCloudSync,
            ),
          ],

          _sectionHeader('ACCOUNT'),
          if (_isGuest)
            _buildActionTile(
              'Sign In',
              Colors.black,
              _goToSignIn,
            )
          else ...[
            _buildActionTile('Logout', Colors.black, _logout),
            _buildActionTile('Delete Account', Colors.red, _deleteAccount),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSwitch(
      String title,
      String sub,
      bool val,
      Function(bool) onChange,
      ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      value: val,
      onChanged: onChange,
      activeThumbColor: Colors.green,
    );
  }

  Widget _buildActionTile(
      String title,
      Color color,
      VoidCallback onTap, {
        String? subtitle,
      }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
      onTap: onTap,
    );
  }
}