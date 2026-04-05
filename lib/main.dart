import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/emotion_entry.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hive 초기화
  await Hive.initFlutter();
  Hive.registerAdapter(EmotionEntryAdapter());
  await Hive.openBox<EmotionEntry>('emotions');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emolog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF534AB7)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}