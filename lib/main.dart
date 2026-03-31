import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaraudeMap',
      theme: AppTheme.getTheme(),
      home: const LoginScreen(),
      routes: {
        '/authenticate': (context) => const LoginScreen(),
        '/home': (context) => const MapScreen(),
        '/list': (context) => const ListScreen(),
      },
    );
  }
}
