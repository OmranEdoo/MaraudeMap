import 'package:flutter/material.dart';

import 'config/theme.dart';
import 'services/profile_service.dart';
import 'services/supabase_bootstrap.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/list_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  await ProfileService.instance.hydrateCurrentSession();
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
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
