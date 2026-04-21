import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import 'add_emotion_screen.dart';
import 'edit_emotion_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 삭제 확인 다이얼로그
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
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<EmotionEntry>('emotions').listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                '아직 기록이 없어요\n아래 + 버튼을 눌러 기록해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final entries = box.values.toList();
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 헤더
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

                  // 감정 카드 목록
                  ...dayEntries.map((entry) => _SwipeToDeleteCard(
                    entry: entry,
                    onDelete: () => _confirmDelete(context, entry),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditEmotionScreen(entry: entry),
                      ),
                    ),
                  )),

                  const Divider(height: 24),
                ],
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

class _SwipeToDeleteCard extends StatefulWidget {
  final EmotionEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SwipeToDeleteCard({
    required this.entry,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_SwipeToDeleteCard> createState() => _SwipeToDeleteCardState();
}

class _SwipeToDeleteCardState extends State<_SwipeToDeleteCard> {
  double _dragOffset = 0.0;
  static const double _maxOffset = 80.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset -= details.delta.dx;
          _dragOffset = _dragOffset.clamp(0.0, _maxOffset);
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          _dragOffset = _dragOffset > _maxOffset / 2 ? _maxOffset : 0.0;
        });
      },
      child: Stack(
        children: [
          // 빨간 삭제 버튼
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
                color: const Color(0xFFF8F8FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // 감정 이모지
                  Text(
                    widget.entry.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 14),

                  // 메모 및 점수
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 감정 점수 닷
                        Row(
                          children: List.generate(5, (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < widget.entry.score
                                  ? const Color(0xFF534AB7)
                                  : Colors.grey.shade300,
                            ),
                          )),
                        ),
                        const SizedBox(height: 4),

                        // 한줄 메모
                        Text(
                          widget.entry.memo.isEmpty
                              ? ''
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

                  // 오른쪽: 일기 아이콘 + 시간
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 일기 있을 때만 아이콘 표시
                      if (widget.entry.diary.isNotEmpty)
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 16,
                          color: Color(0xFF534AB7),
                        )
                      else
                        const SizedBox(height: 16),

                      const SizedBox(height: 4),

                      // 기록 시간
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