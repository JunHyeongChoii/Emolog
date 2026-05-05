import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/ledger_entry.dart';

class MonthPickerWidget extends StatefulWidget {
  final int year;
  final int month;
  final Function(int year, int month) onChanged;
  final bool showEmotionDots; // 감정 기록 있는 달 표시
  final bool showLedgerDots;  // 가계부 기록 있는 달 표시

  const MonthPickerWidget({
    super.key,
    required this.year,
    required this.month,
    required this.onChanged,
    this.showEmotionDots = false,
    this.showLedgerDots = false,
  });

  @override
  State<MonthPickerWidget> createState() => _MonthPickerWidgetState();
}

class _MonthPickerWidgetState extends State<MonthPickerWidget> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.year;
    _selectedMonth = widget.month;
  }

  // 해당 년/월에 감정 기록이 있는지 확인
  bool _hasEmotionData(int year, int month) {
    final prefix =
        '$year-${month.toString().padLeft(2, '0')}';
    final box = Hive.box<EmotionEntry>('emotions');
    return box.values
        .any((e) => e.date.startsWith(prefix) && !e.isEmpty);
  }

  // 해당 년/월에 가계부 기록이 있는지 확인
  bool _hasLedgerData(int year, int month) {
    final prefix =
        '$year-${month.toString().padLeft(2, '0')}';
    final box = Hive.box<LedgerEntry>('ledger');
    return box.values.any((e) => e.date.startsWith(prefix));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 핸들
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          '년/월 선택',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 년도 선택
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedYear--),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF534AB7)),
              ),
            ),
            const SizedBox(width: 20),
            Text(
              '$_selectedYear년',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => setState(() => _selectedYear++),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF534AB7)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 월 선택 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 2.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final isSelected = _selectedYear == widget.year &&
                month == _selectedMonth;
            final isCurrentSelected =
                _selectedYear == widget.year &&
                    month == widget.month;

            final hasData = (widget.showEmotionDots &&
                    _hasEmotionData(_selectedYear, month)) ||
                (widget.showLedgerDots &&
                    _hasLedgerData(_selectedYear, month));

            return GestureDetector(
              onTap: () {
                setState(() => _selectedMonth = month);
                widget.onChanged(_selectedYear, month);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isCurrentSelected
                      ? const Color(0xFF534AB7)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: hasData && !isCurrentSelected
                      ? Border.all(
                          color: const Color(0xFFAFA9EC),
                          width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$month월',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrentSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrentSelected
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),
        const Text(
          '테두리 있는 달 = 기록 있는 달',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// 모달 띄우는 함수
void showMonthPicker({
  required BuildContext context,
  required int year,
  required int month,
  required Function(int year, int month) onChanged,
  bool showEmotionDots = false,
  bool showLedgerDots = false,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: MonthPickerWidget(
        year: year,
        month: month,
        onChanged: onChanged,
        showEmotionDots: showEmotionDots,
        showLedgerDots: showLedgerDots,
      ),
    ),
  );
}