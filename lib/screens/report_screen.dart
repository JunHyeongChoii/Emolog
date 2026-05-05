import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/todo_entry.dart';
import '../models/ledger_entry.dart';
import '../widgets/month_picker_widget.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late int _year;
  late int _month;

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

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final emotionBox = Hive.box<EmotionEntry>('emotions');
    final todoBox = Hive.box<TodoEntry>('todos');
    final ledgerBox = Hive.box<LedgerEntry>('ledger');

    // 해당 월 감정 기록 (빈 항목 제외)
    final emotions = emotionBox.values
        .where((e) => e.date.startsWith(_monthPrefix) && !e.isEmpty)
        .toList();

    // 해당 월 할일
    final todos = todoBox.values
        .where((t) => t.date.startsWith(_monthPrefix))
        .toList();

    // 해당 월 가계부
    final ledgers = ledgerBox.values
        .where((l) => l.date.startsWith(_monthPrefix))
        .toList();

    // 기본 통계
    final totalDays = emotions.length;
    final avgScore = totalDays == 0
        ? 0.0
        : emotions.fold(0, (sum, e) => sum + e.score) / totalDays;

    // 감정별 횟수
    final Map<int, int> scoreCounts = {};
    for (var e in emotions) {
      scoreCounts[e.score] = (scoreCounts[e.score] ?? 0) + 1;
    }

    // 긍정적인 날 (4~5점)
    final positiveDays = (scoreCounts[4] ?? 0) + (scoreCounts[5] ?? 0);

    // 종합 평가 메시지
    String heroEmoji;
    String heroTitle;
    String heroDesc;
    if (totalDays == 0) {
      heroEmoji = '📭';
      heroTitle = '이번 달 기록이 없어요';
      heroDesc = '감정을 기록하면 분석 리포트를 볼 수 있어요!';
    } else if (avgScore >= 4.0) {
      heroEmoji = '😄';
      heroTitle = '이번 달은 정말 좋은 한 달이었어요!';
      heroDesc =
          '평균 감정 점수 ${avgScore.toStringAsFixed(1)}점으로\n$totalDays일 중 $positiveDays일을 긍정적으로 보냈어요.';
    } else if (avgScore >= 3.0) {
      heroEmoji = '😊';
      heroTitle = '이번 달은 전반적으로 좋은 한 달이었어요!';
      heroDesc =
          '평균 감정 점수 ${avgScore.toStringAsFixed(1)}점으로\n$totalDays일 중 $positiveDays일을 긍정적으로 보냈어요.';
    } else if (avgScore >= 2.0) {
      heroEmoji = '😐';
      heroTitle = '이번 달은 조금 힘든 한 달이었어요';
      heroDesc =
          '평균 감정 점수 ${avgScore.toStringAsFixed(1)}점이에요.\n다음 달은 더 좋은 날들이 기다리고 있을 거예요!';
    } else {
      heroEmoji = '😔';
      heroTitle = '이번 달은 많이 힘드셨군요';
      heroDesc =
          '평균 감정 점수 ${avgScore.toStringAsFixed(1)}점이에요.\n자신을 위한 시간을 가져보세요.';
    }

    // 스트레스 날 vs 일반 날 지출 비교
    String spendingInsight = '';
    if (emotions.isNotEmpty && ledgers.isNotEmpty) {
      final stressDates = emotions
          .where((e) => e.score <= 2)
          .map((e) => e.date)
          .toSet();
      final normalDates = emotions
          .where((e) => e.score >= 3)
          .map((e) => e.date)
          .toSet();

      int stressSpend = 0;
      int stressCount = 0;
      int normalSpend = 0;
      int normalCount = 0;

      for (var l in ledgers.where((l) => l.type == 'expense')) {
        if (stressDates.contains(l.date)) {
          stressSpend += l.amount;
          stressCount++;
        } else if (normalDates.contains(l.date)) {
          normalSpend += l.amount;
          normalCount++;
        }
      }

      final avgStress = stressCount > 0 ? stressSpend / stressDates.length : 0;
      final avgNormal = normalCount > 0 ? normalSpend / normalDates.length : 0;

      if (stressDates.isNotEmpty && avgStress > avgNormal && avgNormal > 0) {
        final diff = ((avgStress - avgNormal) / avgNormal * 100).toInt();
        spendingInsight =
            '감정 점수가 낮은 날의 평균 지출이 ${_formatAmount(avgStress.toInt())}원으로, 평소보다 $diff% 높았어요. 스트레스 받을 때 충동 소비가 일어나고 있어요!';
      } else if (stressDates.isNotEmpty && avgStress <= avgNormal) {
        spendingInsight = '스트레스 받는 날에도 지출을 잘 관리하고 있어요! 👍';
      }
    }

    // 할일 완료율과 감정 상관관계
    String todoInsight = '';
    if (emotions.isNotEmpty && todos.isNotEmpty) {
      double highTodoAvgScore = 0;
      int highTodoCount = 0;
      double lowTodoAvgScore = 0;
      int lowTodoCount = 0;

      for (var e in emotions) {
        final dayTodos = todos.where((t) => t.date == e.date).toList();
        if (dayTodos.isEmpty) continue;

        final done = dayTodos.where((t) => t.isDone).length;
        final rate = done / dayTodos.length;

        if (rate >= 0.8) {
          highTodoAvgScore += e.score;
          highTodoCount++;
        } else {
          lowTodoAvgScore += e.score;
          lowTodoCount++;
        }
      }

      if (highTodoCount > 0 && lowTodoCount > 0) {
        final highAvg = highTodoAvgScore / highTodoCount;
        final lowAvg = lowTodoAvgScore / lowTodoCount;
        if (highAvg > lowAvg) {
          todoInsight =
              '할 일을 80% 이상 완료한 날의 평균 감정이 ${highAvg.toStringAsFixed(1)}점으로 가장 높았어요. 성취감이 기분에 큰 영향을 주고 있어요!';
        } else {
          todoInsight = '할 일 완료 여부와 관계없이 감정을 잘 유지하고 있어요!';
        }
      }
    }

    // 요일별 감정 평균
    final Map<int, List<int>> weekdayScores = {};
    for (var e in emotions) {
      final parts = e.date.split('-');
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      weekdayScores.putIfAbsent(dt.weekday, () => []).add(e.score);
    }

    String weekdayInsight = '';
    if (weekdayScores.length >= 3) {
      final weekdayAvgs = weekdayScores.map(
        (k, v) => MapEntry(k, v.fold(0, (a, b) => a + b) / v.length),
      );
      final bestDay = weekdayAvgs.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      final worstDay = weekdayAvgs.entries.reduce(
        (a, b) => a.value <= b.value ? a : b,
      );
      const weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
      weekdayInsight =
          '${weekdays[bestDay.key]}요일이 평균 ${bestDay.value.toStringAsFixed(1)}점으로 가장 좋고, ${weekdays[worstDay.key]}요일이 평균 ${worstDay.value.toStringAsFixed(1)}점으로 가장 힘들었어요.';
    }

    // 다음 달 팁
    final List<Map<String, String>> tips = [];
    if (spendingInsight.contains('충동 소비')) {
      tips.add({
        'title': '스트레스 날 지출 줄이기',
        'desc': '감정 점수가 낮은 날엔 큰 지출을 미뤄보세요. 기분이 나아진 후 결정하면 후회가 줄어요!',
      });
    }
    if (weekdayScores.isNotEmpty) {
      final weekdayAvgs = weekdayScores.map(
        (k, v) => MapEntry(k, v.fold(0, (a, b) => a + b) / v.length),
      );
      if (weekdayAvgs.isNotEmpty) {
        final worstDay = weekdayAvgs.entries.reduce(
          (a, b) => a.value <= b.value ? a : b,
        );
        const weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
        tips.add({
          'title': '${weekdays[worstDay.key]}요일 루틴 만들기',
          'desc':
              '${weekdays[worstDay.key]}요일 기분이 가장 낮아요. 작은 할 일부터 시작해서 성취감을 쌓아보세요!',
        });
      }
    }
    if (avgScore < 3.0) {
      tips.add({
        'title': '나를 위한 시간 만들기',
        'desc': '이번 달 힘드셨죠? 좋아하는 것을 하며 나를 위한 시간을 가져보세요.',
      });
    }
    if (tips.isEmpty) {
      tips.add({
        'title': '꾸준히 기록하기',
        'desc': '매일 감정을 기록하면 더 정확한 분석을 받을 수 있어요!',
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
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
                children: [
                  Text(
                    '$_year년 $_month월 리포트',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 종합 평가 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(heroEmoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 10),
                  Text(
                    heroTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C3489),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    heroDesc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF534AB7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (totalDays > 0) ...[
              // 인사이트
              const Text(
                '이달의 인사이트',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

              // 지출 인사이트
              if (spendingInsight.isNotEmpty)
                _insightCard(
                  '💸',
                  '스트레스와 지출의 관계',
                  spendingInsight,
                  spendingInsight.contains('충동 소비'),
                ),

              // 할일 인사이트
              if (todoInsight.isNotEmpty)
                _insightCard('✅', '할 일 완료율과 기분', todoInsight, false),

              // 요일 인사이트
              if (weekdayInsight.isNotEmpty)
                _insightCard('📅', '요일별 감정 패턴', weekdayInsight, false),

              const SizedBox(height: 16),

              // 감정 분포
              const Text(
                '감정 분포',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

              ...[1, 2, 3, 4, 5].map((score) {
                const emojis = ['', '😢', '😔', '😐', '😊', '😄'];
                const colors = [
                  Colors.transparent,
                  Color(0xFFA32D2D),
                  Color(0xFFAFA9EC),
                  Color(0xFF534AB7),
                  Color(0xFF534AB7),
                  Color(0xFF534AB7),
                ];
                final count = scoreCounts[score] ?? 0;
                final maxCount = scoreCounts.values.isEmpty
                    ? 1
                    : scoreCounts.values.reduce((a, b) => a > b ? a : b);
                final ratio = maxCount > 0 ? count / maxCount : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(emojis[score], style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: Colors.grey.shade200,
                            color: colors[score],
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$count일',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // 다음 달 팁
              const Text(
                '💡 다음 달을 위한 팁',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

              ...tips.map(
                (tip) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF085041),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip['desc']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F6E56),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _insightCard(String icon, String title, String desc, bool isWarning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: isWarning ? const Color(0xFFA32D2D) : Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
