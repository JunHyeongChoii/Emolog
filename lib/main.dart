import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/emotion_entry.dart';
import 'models/todo_entry.dart';
import 'models/ledger_entry.dart';
import 'screens/home_screen.dart';
import 'screens/todo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();
  Hive.registerAdapter(EmotionEntryAdapter());
  Hive.registerAdapter(TodoEntryAdapter());
  await Hive.openBox<EmotionEntry>('emotions');
  await Hive.openBox<TodoEntry>('todos');
  Hive.registerAdapter(LedgerEntryAdapter());
  await Hive.openBox<LedgerEntry>('ledger');

  // 앱 실행 시 빠진 날짜 자동 생성
  await _fillMissingDates();

  runApp(const MyApp());
}

// 마지막 기록일부터 오늘까지 빠진 날짜 자동 생성
Future<void> _fillMissingDates() async {
  final box = Hive.box<EmotionEntry>('emotions');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // 오늘 날짜 문자열
  String dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // 이미 기록된 날짜 목록
  final existingDates = box.values.map((e) => e.date).toSet();

  // 마지막 기록일 찾기
  DateTime startDate;
  if (existingDates.isEmpty) {
    // 기록이 하나도 없으면 오늘만 생성
    startDate = today;
  } else {
    // 가장 최근 기록일 다음날부터 시작
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

  // 시작일부터 오늘까지 빠진 날짜 채우기
  DateTime current = startDate;
  while (!current.isAfter(today)) {
    final dateStr = dateToStr(current);

    // 해당 날짜 기록이 없으면 빈 항목 생성
    if (!existingDates.contains(dateStr)) {
      final entry = EmotionEntry()
        ..date = dateStr
        ..score = 0
        ..emoji = '😶'
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

  final List<Widget> _screens = [const HomeScreen(), const TodoScreen()];

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
        ],
      ),
    );
  }
}
