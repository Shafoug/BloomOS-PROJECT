import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bloomos_clean/screens/core/theme/theme.dart';
import 'navigation/main_navigation.dart';
import 'screens/welcome/welcome_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart'; // 🔥 مهم تضيفيه
import 'state/plants_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await NotificationService.init(); // ✅ هنا التفعيل

  final plantsStore = PlantsStore();

  if (AuthService().isSignedIn) {
    await plantsStore.refreshAfterAuthChange();
  } else {
    await plantsStore.clearForGuest();
  }

  runApp(
    ChangeNotifierProvider.value(
      value: plantsStore,
      child: const BloomOSApp(),
    ),
  );
}

class BloomOSApp extends StatelessWidget {
  const BloomOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSignedIn = AuthService().isSignedIn;

    return MaterialApp(
      title: 'BloomOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: isSignedIn
          ? const MainNavigation(isGuest: false)
          : const WelcomeScreen(), // 👈 رجعناه صح
    );
  }
}