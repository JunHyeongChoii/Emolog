import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/todo_entry.dart';
import '../models/ledger_entry.dart';
import 'add_emotion_screen.dart';
import 'edit_emotion_screen.dart';
import 'detail_emotion_screen.dart';
import 'monthly_emotion_screen.dart';
import 'notification_screen.dart';

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ===== Phase 2: 이번 주 인사이트 계산 =====
String? _computeWeeklyInsight(
  List<EmotionEntry> emotions,
  List<LedgerEntry> ledgers,
  List<TodoEntry> todos,
  DateTime today,
) {
  final last7Strs = List.generate(
    7,
    (i) => _fmtDate(today.subtract(Duration(days: i))),
  ).toSet();

  final weekEmotions = emotions
      .where((e) => last7Strs.contains(e.date) && !e.isEmpty)
      .toList();
  if (weekEmotions.length < 3) return null;

  final weekLedgers = ledgers.where((l) => last7Strs.contains(l.date)).toList();
  final weekTodos = todos.where((t) => last7Strs.contains(t.date)).toList();

  final stressDates =
      weekEmotions.where((e) => e.score <= 2).map((e) => e.date).toSet();
  final normalDates =
      weekEmotions.where((e) => e.score >= 3).map((e) => e.date).toSet();

  // 1) 스트레스 날 vs 평소 지출 비교
  int stressSpend = 0;
  int normalSpend = 0;
  for (var l in weekLedgers.where((l) => l.type == 'expense')) {
    if (stressDates.contains(l.date)) {
      stressSpend += l.amount;
    } else if (normalDates.contains(l.date)) {
      normalSpend += l.amount;
    }
  }
  final avgStress = stressDates.isEmpty ? 0 : stressSpend / stressDates.length;
  final avgNormal = normalDates.isEmpty ? 0 : normalSpend / normalDates.length;
  if (stressDates.isNotEmpty && avgNormal > 0 && avgStress > avgNormal) {
    final diff = ((avgStress - avgNormal) / avgNormal * 100).toInt();
    if (diff >= 20) {
      return '감정 점수가 낮은 날 지출이 평소보다 $diff% 높았어요 💸\n스트레스와 소비, 연결되어 있을지도 몰라요.';
    }
  }

  // 2) 후회 소비의 스트레스 날 발생 비율
  final regretSpends = weekLedgers
      .where((l) => l.type == 'expense' && l.spendMood == 1)
      .toList();
  if (regretSpends.isNotEmpty) {
    final regretOnStress =
        regretSpends.where((l) => stressDates.contains(l.date)).length;
    final ratio = (regretOnStress / regretSpends.length * 100).toInt();
    if (ratio >= 50) {
      return '이번 주 후회 소비의 $ratio%가 감정 점수가 낮은 날 일어났어요 💭\n힘든 날엔 결제 전에 한 번 더 생각해봐요.';
    }
  }

  // 3) 힘든 날의 감정 원인 태그
  final Map<String, int> hardTagCounts = {};
  for (var e in weekEmotions.where((e) => e.score <= 2)) {
    for (var tag in e.tags) {
      hardTagCounts[tag] = (hardTagCounts[tag] ?? 0) + 1;
    }
  }
  if (hardTagCounts.isNotEmpty) {
    final topHard =
        hardTagCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return "이번 주 나를 힘들게 한 건 '${topHard.key}'였어요 🏷️\n다음 주엔 이 부분에 여유를 만들어보세요.";
  }

  // 4) 할 일 완료율과 기분
  double highTodoAvgScore = 0;
  int highTodoCount = 0;
  double lowTodoAvgScore = 0;
  int lowTodoCount = 0;
  for (var e in weekEmotions) {
    final dayTodos = weekTodos.where((t) => t.date == e.date).toList();
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
    if (highAvg > lowAvg + 0.3) {
      return '할 일을 많이 끝낸 날 기분이 더 좋았어요 ✅\n성취감이 기분에 큰 힘이 되고 있어요.';
    }
  }

  // 5) 폴백: 평균 감정 점수
  final avgScore =
      weekEmotions.fold(0, (sum, e) => sum + e.score) / weekEmotions.length;
  return '이번 주 평균 감정 점수는 ${avgScore.toStringAsFixed(1)}점이에요 😊\n꾸준한 기록, 정말 멋져요!';
}

// ===== Phase 2: streak 계산 =====
class _StreakInfo {
  final int streak;
  final int monthCount;
  final int daysElapsed;
  const _StreakInfo(this.streak, this.monthCount, this.daysElapsed);
}

_StreakInfo _computeStreak(List<EmotionEntry> emotions, DateTime today) {
  final recordedDates =
      emotions.where((e) => !e.isEmpty).map((e) => e.date).toSet();

  int streak = 0;
  var cursor = today;
  while (recordedDates.contains(_fmtDate(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  final monthPrefix = '${today.year}-${today.month.toString().padLeft(2, '0')}';
  final monthCount =
      recordedDates.where((d) => d.startsWith(monthPrefix)).length;

  return _StreakInfo(streak, monthCount, today.day);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, EmotionEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '기록 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('이 감정 기록을 삭제할까요?\n삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (result == true) await entry.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Emolog',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MonthlyEmotionScreen()),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<EmotionEntry>('emotions').listenable(),
        builder: (context, emotionBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<TodoEntry>('todos').listenable(),
            builder: (context, todoBox, _) {
              return ValueListenableBuilder(
                valueListenable: Hive.box<LedgerEntry>('ledger').listenable(),
                builder: (context, ledgerBox, _) {
                  if (emotionBox.isEmpty) {
                    return const Center(
                      child: Text(
                        '아직 기록이 없어요\n아래 + 버튼을 눌러 기록해보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final today = DateTime.now();

                  // 최근 7일 날짜 문자열 목록
                  final recentDates = <String>{};
                  for (int i = 0; i < 7; i++) {
                    recentDates
                        .add(_fmtDate(today.subtract(Duration(days: i))));
                  }

                  // 최근 7일 기록만 필터링 + 정렬
                  final entries = emotionBox.values
                      .where((e) => recentDates.contains(e.date))
                      .toList()
                    ..sort((a, b) {
                      if (a.date == b.date) {
                        return a.createdAt.compareTo(b.createdAt);
                      }
                      return a.date.compareTo(b.date);
                    });

                  final Map<String, List<EmotionEntry>> grouped = {};
                  for (var entry in entries) {
                    grouped.putIfAbsent(entry.date, () => []).add(entry);
                  }

                  final weeklyInsight = _computeWeeklyInsight(
                    emotionBox.values.toList(),
                    ledgerBox.values.toList(),
                    todoBox.values.toList(),
                    today,
                  );
                  final streakInfo = _computeStreak(
                    emotionBox.values.toList(),
                    today,
                  );

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          children: [
                            _WeeklyInsightCard(message: weeklyInsight),
                            const SizedBox(height: 12),
                            _StreakCard(info: streakInfo),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: grouped.length + 1,
                          itemBuilder: (context, index) {

                            // 마지막 항목: 이전 기록 보기 버튼
                            if (index == grouped.length) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    top: 8, bottom: 24),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MonthlyEmotionScreen(),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F8FC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.history_rounded,
                                            size: 18,
                                            color: Color(0xFF534AB7)),
                                        SizedBox(width: 8),
                                        Text(
                                          '이전 기록 보기',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF534AB7),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.chevron_right_rounded,
                                            size: 18,
                                            color: Color(0xFF534AB7)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final date = grouped.keys.elementAt(index);
                            final dayEntries = grouped[date]!;
                            final parts = date.split('-');
                            final dt = DateTime(
                              int.parse(parts[0]),
                              int.parse(parts[1]),
                              int.parse(parts[2]),
                            );
                            final weekdays = [
                              '월', '화', '수', '목', '금', '토', '일',
                            ];
                            final weekday = weekdays[dt.weekday - 1];

                            final todos = todoBox.values
                                .where((t) => t.date == date)
                                .toList();
                            final totalTodos = todos.length;
                            final doneTodos =
                                todos.where((t) => t.isDone).length;
                            final todoProgress = totalTodos == 0
                                ? -1.0
                                : doneTodos / totalTodos;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${parts[1]}/${parts[2]}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        weekday,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...dayEntries.map(
                                  (entry) => _SwipeCard(
                                    entry: entry,
                                    todoProgress: todoProgress,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DetailEmotionScreen(entry: entry),
                                      ),
                                    ),
                                    onEdit: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditEmotionScreen(entry: entry),
                                      ),
                                    ),
                                    onDelete: () =>
                                        _confirmDelete(context, entry),
                                  ),
                                ),
                                const Divider(height: 24),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF534AB7),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEmotionScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _WeeklyInsightCard extends StatelessWidget {
  final String? message;

  const _WeeklyInsightCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF534AB7), Color(0xFF7B6FE0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 나의 인사이트',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message ?? '기록이 쌓일수록 더 정확한 인사이트를 드릴 수 있어요!\n오늘 하루는 어떠셨나요? 😊',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final _StreakInfo info;

  const _StreakCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final text = info.streak > 0
        ? '🔥 ${info.streak}일 연속 기록 중! 이번 달 ${info.monthCount}/${info.daysElapsed}일'
        : '오늘부터 기록을 시작해볼까요? 🔥';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFFC05621),
        ),
      ),
    );
  }
}

class _SwipeCard extends StatefulWidget {
  final EmotionEntry entry;
  final double todoProgress;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SwipeCard({
    required this.entry,
    required this.todoProgress,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  double _dragOffset = 0.0;
  static const double _maxOffset = 80.0;

  Widget _todoBadge() {
    if (widget.todoProgress < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '할일 없음',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      );
    } else if (widget.todoProgress >= 1.0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEDFE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 10, color: Color(0xFF534AB7)),
            SizedBox(width: 2),
            Text(
              '100%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF534AB7),
              ),
            ),
          ],
        ),
      );
    } else {
      final percent = (widget.todoProgress * 100).toInt();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F5EE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 10, color: Color(0xFF0F6E56)),
            const SizedBox(width: 2),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F6E56),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset -= details.delta.dx;
          _dragOffset = _dragOffset.clamp(-_maxOffset, _maxOffset);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset > _maxOffset / 2) {
          setState(() => _dragOffset = _maxOffset);
        } else if (_dragOffset < -_maxOffset / 2) {
          setState(() => _dragOffset = 0.0);
          widget.onEdit();
        } else {
          setState(() => _dragOffset = 0.0);
        }
      },
      child: Stack(
        children: [
          // 왼쪽: 초록 수정 버튼
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: _maxOffset,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                    SizedBox(height: 4),
                    Text(
                      '수정',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 오른쪽: 빨간 삭제 버튼
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  setState(() => _dragOffset = 0.0);
                  widget.onDelete();
                },
                child: Container(
                  width: _maxOffset,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.white, size: 24),
                      SizedBox(height: 4),
                      Text(
                        '삭제',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 감정 카드
          GestureDetector(
            onTap: _dragOffset == 0
                ? widget.onTap
                : () => setState(() => _dragOffset = 0.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(-_dragOffset, 0, 0),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.entry.isEmpty
                    ? Colors.grey.shade100
                    : const Color(0xFFF8F8FC),
                borderRadius: BorderRadius.circular(14),
                border: widget.entry.isEmpty
                    ? Border.all(color: Colors.grey.shade300, width: 1)
                    : null,
              ),
              child: widget.entry.isEmpty
                  ? Row(
                      children: [
                        const Text('😶', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 14),
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
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '감정을 기록해주세요',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: 16),
                            const SizedBox(height: 4),
                            Text(
                              widget.entry.createdAt,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Text(
                          widget.entry.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 14),
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
                                      color: i < widget.entry.score
                                          ? const Color(0xFF534AB7)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.entry.memo.isEmpty
                                    ? '메모 없음'
                                    : widget.entry.memo,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.entry.memo.isEmpty
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                if (widget.entry.diary.isNotEmpty) ...[
                                  const Icon(
                                    Icons.edit_note_rounded,
                                    size: 16,
                                    color: Color(0xFF534AB7),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                _todoBadge(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.entry.createdAt,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}