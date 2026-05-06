import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/emotion_entry.dart';
import 'models/todo_entry.dart';
import 'models/ledger_entry.dart';
import 'screens/home_screen.dart';
import 'screens/todo_screen.dart';
import 'screens/ledger_screen.dart';
import 'services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();
  Hive.registerAdapter(EmotionEntryAdapter());
  Hive.registerAdapter(TodoEntryAdapter());
  Hive.registerAdapter(LedgerEntryAdapter());
  await Hive.openBox<EmotionEntry>('emotions');
  await Hive.openBox<TodoEntry>('todos');
  await Hive.openBox<LedgerEntry>('ledger');

  // 앱 실행 시 빠진 날짜 자동 생성
  await _fillMissingDates();

  // 알림 서비스 초기화
  await NotificationService().init();
  // 저장된 알림 설정 복원
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('notification_enabled') ?? false;
  final hour = prefs.getInt('notification_hour') ?? 21;
  final minute = prefs.getInt('notification_minute') ?? 0;
  if (isEnabled) {
    await NotificationService().scheduleDailyNotification(
      hour: hour,
      minute: minute,
    );
  }
  runApp(const MyApp());
}

// 마지막 기록일부터 오늘까지 빠진 날짜 자동 생성
Future<void> _fillMissingDates() async {
  final box = Hive.box<EmotionEntry>('emotions');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  String dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final existingDates = box.values.map((e) => e.date).toSet();

  DateTime startDate;
  if (existingDates.isEmpty) {
    startDate = today;
  } else {
    final sortedDates = existingDates.toList()..sort();
    final lastDateStr = sortedDates.last;
    final parts = lastDateStr.split('-');
    final lastDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    startDate = lastDate.add(const Duration(days: 1));
  }

  DateTime current = startDate;
  while (!current.isAfter(today)) {
    final dateStr = dateToStr(current);
    if (!existingDates.contains(dateStr)) {
      final entry = EmotionEntry()
        ..date = dateStr
        ..score = 0
        ..emoji = '💭'
        ..memo = ''
        ..diary = ''
        ..isEmpty = true
        ..createdAt = '00:00';
      await box.add(entry);
    }
    current = current.add(const Duration(days: 1));
  }
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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TodoScreen(),
    const LedgerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF534AB7),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mood_rounded), label: '감정'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            label: '할 일',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: '가계부',
          ),
        ],
      ),
    );
  }
}
