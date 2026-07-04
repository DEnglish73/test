import 'package:flutter/material.dart';

import 'services/progress.dart';
import 'ui/level_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Progress.init();
  runApp(const PrismApp());
}

class PrismApp extends StatelessWidget {
  const PrismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prism',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E15),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF57E6C0),
          brightness: Brightness.dark,
        ),
      ),
      home: const LevelSelectScreen(),
    );
  }
}
