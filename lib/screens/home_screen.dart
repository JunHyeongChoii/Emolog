import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/todo_entry.dart';
import 'add_emotion_screen.dart';
import 'edit_emotion_screen.dart';
import 'detail_emotion_screen.dart';
import 'monthly_emotion_screen.dart';
import 'notification_screen.dart';

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
          // 알림 설정 버튼
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          // 통계 버튼
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
              if (emotionBox.isEmpty) {
                return const Center(
                  child: Text(
                    '아직 기록이 없어요\n아래 + 버튼을 눌러 기록해보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
//
              final entries = emotionBox.values.toList()
                ..sort((a, b) {
                  // 날짜가 같으면 생성 시간(createdAt) 비교, 다르면 날짜(date) 비교
                  if (a.date == b.date) {
                    return a.createdAt.compareTo(b.createdAt); // 시간 내림차순
                  }
                  return a.date.compareTo(b.date); // 날짜 내림차순
                });

              final Map<String, List<EmotionEntry>> grouped = {};
              for (var entry in entries) {
                grouped.putIfAbsent(entry.date, () => []).add(entry);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: grouped.length,
                itemBuilder: (context, index) {
                  final date = grouped.keys.elementAt(index);
                  final dayEntries = grouped[date]!;
                  final parts = date.split('-');
                  final dt = DateTime(
                    int.parse(parts[0]),
                    int.parse(parts[1]),
                    int.parse(parts[2]),
                  );
                  final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                  final weekday = weekdays[dt.weekday - 1];

                  final todos = todoBox.values
                      .where((t) => t.date == date)
                      .toList();
                  final totalTodos = todos.length;
                  final doneTodos = todos.where((t) => t.isDone).length;
                  final todoProgress = totalTodos == 0
                      ? -1.0
                      : doneTodos / totalTodos;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                              builder: (_) => DetailEmotionScreen(entry: entry),
                            ),
                          ),
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditEmotionScreen(entry: entry),
                            ),
                          ),
                          onDelete: () => _confirmDelete(context, entry),
                        ),
                      ),
                      const Divider(height: 24),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
