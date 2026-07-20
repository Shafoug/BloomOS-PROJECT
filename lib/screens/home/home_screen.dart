import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/plants_store.dart';

class HomeScreen extends StatelessWidget {
  final bool isGuest;

  const HomeScreen({
    super.key,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlantsStore>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),

            const Text(
              'Hello 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2A1F),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              isGuest ? 'Guest mode is active' : 'Smart Plant Care System',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7B8B78),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEAF7E8),
                    Color(0xFFDDF1DA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Plant Care',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF294B2D),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Monitor tomato and potato plants using ESP32, Bluetooth, Wi-Fi, and AI diagnosis.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6C826A),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_outlined,
                      size: 32,
                      color: Color(0xFF5AA05F),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'System Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2A1F),
              ),
            ),

            const SizedBox(height: 12),

            _featureCard(
              title: 'Nearby Control',
              subtitle: 'Bluetooth connection',
              icon: Icons.bluetooth_connected,
              points: const [
                'Connect directly to ESP32',
                'Control watering nearby',
                'Send Wi-Fi credentials to the device',
              ],
            ),

            const SizedBox(height: 12),

            _featureCard(
              title: 'Remote Monitoring',
              subtitle: 'Wi-Fi + Firebase',
              icon: Icons.wifi,
              points: const [
                'Live sensor updates',
                'Cloud monitoring for signed-in users',
                'Remote watering when Wi-Fi is available',
              ],
            ),

            const SizedBox(height: 12),

            _featureCard(
              title: 'AI Diagnosis',
              subtitle: 'Leaf analysis',
              icon: Icons.document_scanner_outlined,
              points: const [
                'Analyze leaf images',
                'Show simple diagnosis results',
                'Save diagnosis history for signed-in users',
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _featureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF7E8),
                child: Icon(
                  icon,
                  color: const Color(0xFF4E9B57),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF7B8B78),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
                (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $e',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF3F4D3D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}