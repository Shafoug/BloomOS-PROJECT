import 'package:flutter/material.dart';

import 'package:bloomos_clean/navigation/main_navigation.dart';
import '../auth/login_screen.dart';
import '../welcome/welcome_screen.dart';

class AppRoutes {
  static const welcome = '/welcome';
  static const login = '/login';
  static const main = '/main';

  static Map<String, WidgetBuilder> get routes => {
    welcome: (_) => const WelcomeScreen(),
    login: (_) => const LoginScreen(),
    main: (_) => const MainNavigation(isGuest: false),
  };
}