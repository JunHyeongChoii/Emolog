import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import 'detail_emotion_screen.dart';
import 'report_screen.dart';
import '../widgets/month_picker_widget.dart';

class MonthlyEmotionScreen extends StatefulWidget {
  const MonthlyEmotionScreen({super.key});

  @override
  State<MonthlyEmotionScreen> createState() => _MonthlyEmotionScreenState();
}

class _MonthlyEmotionScreenState extends State<MonthlyEmotionScreen> {
  late int _year;
  late int _month;
  bool _isCalendarView = true; // true: 캘린더뷰, false: 리스트뷰

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  String get _monthPrefix => '$_year-${_month.toString().padLeft(2, '0')}';

  final List<String> _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  // 해당 월 첫날 요일 (월=0 ~ 일=6)
  int _firstWeekday() {
    final first = DateTime(_year, _month, 1);
    return first.weekday - 1;
  }

  // 해당 월 마지막 날
  int _lastDay() {
    return DateTime(_year, _month + 1, 0).day;
  }

  String _dateStr(int day) =>
      '$_year-${_month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _prevMonth,
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF534AB7),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => showMonthPicker(
                context: context,
                year: _year,
                month: _month,
                onChanged: (y, m) => setState(() {
                  _year = y;
                  _month = m;
                }),
                showEmotionDots: true,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_year년 $_month월',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Color(0xFF534AB7),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _nextMonth,
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF534AB7),
              ),
            ),
          ],
        ),
        actions: [
          // 리포트 버튼
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF534AB7)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
          // 캘린더/리스트 뷰 전환
          IconButton(
            icon: Icon(
              _isCalendarView
                  ? Icons.list_rounded
                  : Icons.calendar_month_rounded,
              color: const Color(0xFF534AB7),
            ),
            onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<EmotionEntry>('emotions').listenable(),
        builder: (context, box, _) {
          // 해당 월 기록 필터링
          final entries =
              box.values.where((e) => e.date.startsWith(_monthPrefix)).toList()
                ..sort((a, b) => a.date.compareTo(b.date));

          // 날짜별 Map
          final Map<String, EmotionEntry> entryMap = {};
          for (var e in entries) {
            entryMap[e.date] = e;
          }

          // 실제 기록된 항목 (isEmpty 제외)
          final recorded = entries.where((e) => !e.isEmpty).toList();

          // 평균 점수
          final avgScore = recorded.isEmpty
              ? 0.0
              : recorded.fold(0, (sum, e) => sum + e.score) / recorded.length;

          // 감정별 횟수
          final Map<int, int> scoreCounts = {};
          for (var e in recorded) {
            scoreCounts[e.score] = (scoreCounts[e.score] ?? 0) + 1;
          }

          // 최다 감정
          String topEmoji = '-';
          if (scoreCounts.isNotEmpty) {
            final topScore = scoreCounts.entries
                .reduce((a, b) => a.value >= b.value ? a : b)
                .key;
            const emojis = ['', '😢', '😔', '😐', '😊', '😄'];
            topEmoji = emojis[topScore];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 요약 카드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDFE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem(
                        '평균 기분',
                        avgScore == 0 ? '-' : avgScore.toStringAsFixed(1),
                        const Color(0xFF534AB7),
                      ),
                      Container(
                        width: 0.5,
                        height: 40,
                        color: const Color(0xFFAFA9EC),
                      ),
                      _summaryItem('최다 감정', topEmoji, const Color(0xFF534AB7)),
                      Container(
                        width: 0.5,
                        height: 40,
                        color: const Color(0xFFAFA9EC),
                      ),
                      _summaryItem(
                        '기록한 날',
                        '${recorded.length}일',
                        const Color(0xFF534AB7),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 감정별 횟수
                if (recorded.isNotEmpty) ...[
                  const Text(
                    '감정별 횟수',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _emotionChip('😢', scoreCounts[1] ?? 0),
                      const SizedBox(width: 6),
                      _emotionChip('😔', scoreCounts[2] ?? 0),
                      const SizedBox(width: 6),
                      _emotionChip('😐', scoreCounts[3] ?? 0),
                      const SizedBox(width: 6),
                      _emotionChip('😊', scoreCounts[4] ?? 0),
                      const SizedBox(width: 6),
                      _emotionChip('😄', scoreCounts[5] ?? 0),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 캘린더 뷰 / 리스트 뷰 전환
                if (_isCalendarView)
                  _buildCalendar(entryMap)
                else
                  _buildList(entries),
              ],
            ),
          );
        },
      ),
    );
  }

  // 캘린더 뷰
  Widget _buildCalendar(Map<String, EmotionEntry> entryMap) {
    final firstWeekday = _firstWeekday();
    final lastDay = _lastDay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이달 기록',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),

        // 요일 헤더
        Row(
          children: _weekdayLabels
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: d == '토'
                            ? Colors.blue.shade400
                            : d == '일'
                            ? Colors.red.shade400
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),

        // 날짜 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.85,
          ),
          itemCount: firstWeekday + lastDay,
          itemBuilder: (context, index) {
            if (index < firstWeekday) return const SizedBox();

            final day = index - firstWeekday + 1;
            final dateStr = _dateStr(day);
            final entry = entryMap[dateStr];
            final isToday =
                dateStr ==
                '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

            return GestureDetector(
              onTap: entry != null
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailEmotionScreen(entry: entry),
                      ),
                    )
                  : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: entry != null && !entry.isEmpty
                      ? const Color(0xFFF8F8FC)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: const Color(0xFF534AB7), width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (entry != null && !entry.isEmpty)
                      Text(entry.emoji, style: const TextStyle(fontSize: 16))
                    else
                      const SizedBox(height: 16),
                    const SizedBox(height: 2),
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 10,
                        color: isToday ? const Color(0xFF534AB7) : Colors.grey,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 리스트 뷰
  Widget _buildList(List<EmotionEntry> entries) {
    final filtered = entries
        .where((e) => !e.isEmpty)
        .toList()
        .reversed
        .toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            '이번 달 감정 기록이 없어요',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: filtered.map((entry) {
        final parts = entry.date.split('-');
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        final weekday = weekdays[dt.weekday - 1];

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailEmotionScreen(entry: entry),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // 날짜
                Column(
                  children: [
                    Text(
                      '${parts[2]}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF534AB7),
                      ),
                    ),
                    Text(
                      weekday,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // 이모지
                Text(entry.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),

                // 점수 + 메모
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < entry.score
                                  ? const Color(0xFF534AB7)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.memo.isEmpty ? '메모 없음' : entry.memo,
                        style: TextStyle(
                          fontSize: 13,
                          color: entry.memo.isEmpty
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // 일기 아이콘
                if (entry.diary.isNotEmpty)
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: Color(0xFF534AB7),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF534AB7)),
        ),
      ],
    );
  }

  Widget _emotionChip(String emoji, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              '$count회',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
