import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo_entry.dart';

class AddTodoScreen extends StatefulWidget {
  final String date;

  const AddTodoScreen({super.key, required this.date});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final TextEditingController _titleController = TextEditingController();
  String _repeatType = 'once';
  final List<int> _selectedDays = [];
  int _repeatDay = 1;

  final List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('할 일을 입력해주세요!')),
      );
      return;
    }

    if (_repeatType == 'weekly' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요일을 선택해주세요!')),
      );
      return;
    }

    final box = Hive.box<TodoEntry>('todos');
    final now = DateTime.now();
    final createdAt =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (_repeatType == 'once') {
      final todo = TodoEntry()
        ..title = _titleController.text.trim()
        ..isDone = false
        ..date = widget.date
        ..createdAt = createdAt
        ..repeatType = 'once'
        ..repeatDays = []
        ..repeatDay = 0;
      await box.add(todo);

    } else if (_repeatType == 'weekly') {
      final baseDate = DateTime.parse(widget.date);
      final Set<String> addedDates = {};

      for (int week = 0; week < 4; week++) {
        for (int day in _selectedDays) {
          final weekStart =
              baseDate.subtract(Duration(days: baseDate.weekday - 1));
          final targetDate =
              weekStart.add(Duration(days: day - 1 + (week * 7)));
          final dateStr =
              '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

          if (!addedDates.contains(dateStr)) {
            addedDates.add(dateStr);
            final todo = TodoEntry()
              ..title = _titleController.text.trim()
              ..isDone = false
              ..date = dateStr
              ..createdAt = createdAt
              ..repeatType = 'weekly'
              ..repeatDays = List.from(_selectedDays)
              ..repeatDay = 0;
            await box.add(todo);
          }
        }
      }

    } else if (_repeatType == 'monthly') {
      final baseDate = DateTime.parse(widget.date);
      for (int month = 0; month < 3; month++) {
        final targetMonth = baseDate.month + month;
        final targetYear = baseDate.year + (targetMonth - 1) ~/ 12;
        final adjustedMonth = ((targetMonth - 1) % 12) + 1;
        final lastDay = DateTime(targetYear, adjustedMonth + 1, 0).day;
        final day = _repeatDay > lastDay ? lastDay : _repeatDay;
        final dateStr =
            '$targetYear-${adjustedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

        final todo = TodoEntry()
          ..title = _titleController.text.trim()
          ..isDone = false
          ..date = dateStr
          ..createdAt = createdAt
          ..repeatType = 'monthly'
          ..repeatDays = []
          ..repeatDay = _repeatDay;
        await box.add(todo);
      }
    }

    if (mounted) Navigator.pop(context);
  }

  Widget _buildRepeatTab(String label, String type) {
    final isSelected = _repeatType == type;
    return GestureDetector(
      onTap: () => setState(() => _repeatType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF534AB7) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF534AB7)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '할 일 추가',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 1. 반복 설정 (위로 이동)
            const Text(
              '반복 설정',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildRepeatTab('오늘만', 'once'),
                const SizedBox(width: 8),
                _buildRepeatTab('매주', 'weekly'),
                const SizedBox(width: 8),
                _buildRepeatTab('매월', 'monthly'),
              ],
            ),

            const SizedBox(height: 20),

            // 매주: 요일 선택
            if (_repeatType == 'weekly') ...[
              const Text(
                '요일 선택 (복수 선택 가능)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final isSelected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF534AB7)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF534AB7)
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _weekdays[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],

            // 매월: 날짜 선택
            if (_repeatType == 'monthly') ...[
              const Text(
                '매월 몇 일에 반복할까요?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _repeatDay,
                    isExpanded: true,
                    items: List.generate(31, (i) => i + 1)
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text('매월 $day일'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _repeatDay = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Divider(height: 8),
            const SizedBox(height: 20),

            // 2. 할 일 입력 (아래로 이동)
            const Text(
              '할 일',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '할 일을 입력해주세요',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF534AB7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '저장하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}