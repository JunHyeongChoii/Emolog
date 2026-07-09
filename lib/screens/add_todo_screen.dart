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

  // 반복 설정
  String _repeatType = 'once'; // 'once' / 'weekly' / 'monthly'
  final List<int> _selectedWeekdays = [];
  int _selectedMonthDay = 1;

  // 세트 기록 설정
  bool _isSetType = false;
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();

  final List<String> _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void dispose() {
    _titleController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  // 다음 반복 날짜들 생성 (앞으로 60일)
  List<String> _generateDates() {
    final List<String> dates = [];
    final parts = widget.date.split('-');
    final baseDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    String dateToStr(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    if (_repeatType == 'once') {
      dates.add(widget.date);
    } else if (_repeatType == 'weekly') {
      for (int i = 0; i < 60; i++) {
        final d = baseDate.add(Duration(days: i));
        if (_selectedWeekdays.contains(d.weekday)) {
          dates.add(dateToStr(d));
        }
      }
    } else if (_repeatType == 'monthly') {
      for (int i = 0; i < 60; i++) {
        final d = baseDate.add(Duration(days: i));
        if (d.day == _selectedMonthDay) {
          dates.add(dateToStr(d));
        }
      }
    }
    return dates;
  }

  void _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('할 일 이름을 입력해주세요!')));
      return;
    }

    if (_repeatType == 'weekly' && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('반복할 요일을 선택해주세요!')));
      return;
    }

    // 세트 기록 검증
    int reps = 0;
    int sets = 0;
    if (_isSetType) {
      reps = int.tryParse(_repsController.text.trim()) ?? 0;
      sets = int.tryParse(_setsController.text.trim()) ?? 0;
      if (reps <= 0 || sets <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('개수와 세트 수를 입력해주세요!')));
        return;
      }
    }

    final box = Hive.box<TodoEntry>('todos');
    final now = DateTime.now();
    final createdAt =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final dates = _generateDates();
    for (final dateStr in dates) {
      final entry = TodoEntry()
        ..title = _titleController.text.trim()
        ..isDone = false
        ..date = dateStr
        ..createdAt = createdAt
        ..repeatType = _repeatType
        ..repeatDays = List.from(_selectedWeekdays)
        ..repeatDay = _repeatType == 'monthly' ? _selectedMonthDay : 0
        ..isSetType = _isSetType
        ..repsPerSet = reps
        ..targetSets = sets
        ..completedSets = 0;
      await box.add(entry);
    }

    if (mounted) Navigator.pop(context);
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
            // 날짜 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.date,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 24),

            // 할 일 이름
            const Text(
              '할 일 이름',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              maxLength: 30,
              decoration: InputDecoration(
                hintText: '어떤 일을 할 건가요?',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 세트 기록 토글
            GestureDetector(
              onTap: () => setState(() => _isSetType = !_isSetType),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _isSetType
                      ? const Color(0xFFEEEDFE)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSetType
                        ? const Color(0xFF534AB7)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔁', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '세트 기록',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isSetType
                                  ? const Color(0xFF3C3489)
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            '팔굽혀펴기 10개씩 5세트처럼 세트 단위로 기록해요',
                            style: TextStyle(
                              fontSize: 11,
                              color: _isSetType
                                  ? const Color(0xFF534AB7)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isSetType,
                      onChanged: (v) => setState(() => _isSetType = v),
                      activeColor: const Color(0xFF534AB7),
                    ),
                  ],
                ),
              ),
            ),

            // 세트 기록 켜면 개수/세트 입력칸 표시
            if (_isSetType) ...[
              const SizedBox(height: 16),
              const Text(
                '개수 / 세트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '10',
                        suffixText: '개',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF534AB7),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '×',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '5',
                        suffixText: '세트',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF534AB7),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // 반복 설정
            const Text(
              '반복',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _repeatChip('오늘만', 'once'),
                const SizedBox(width: 8),
                _repeatChip('매주', 'weekly'),
                const SizedBox(width: 8),
                _repeatChip('매월', 'monthly'),
              ],
            ),

            // 매주: 요일 선택
            if (_repeatType == 'weekly') ...[
              const SizedBox(height: 16),
              const Text(
                '반복할 요일',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final weekday = i + 1;
                  final isSelected = _selectedWeekdays.contains(weekday);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selectedWeekdays.remove(weekday);
                      } else {
                        _selectedWeekdays.add(weekday);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF534AB7)
                            : const Color(0xFFF5F5F5),
                      ),
                      child: Center(
                        child: Text(
                          _weekdayLabels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],

            // 매월: 날짜 선택
            if (_repeatType == 'monthly') ...[
              const SizedBox(height: 16),
              const Text(
                '반복할 날짜',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<int>(
                  value: _selectedMonthDay,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: List.generate(31, (i) => i + 1)
                      .map(
                        (d) =>
                            DropdownMenuItem(value: d, child: Text('매월 $d일')),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMonthDay = v ?? 1),
                ),
              ),
            ],

            const SizedBox(height: 32),

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

  Widget _repeatChip(String label, String type) {
    final isSelected = _repeatType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _repeatType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF534AB7)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
