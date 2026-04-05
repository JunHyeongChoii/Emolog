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
          // 취소 버튼
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          // 삭제 버튼
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

    // 확인 눌렀을 때만 삭제
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
          // 통계 아이콘 (나중에 연결 예정)
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {},
          ),
        ],
      ),

      // Hive 데이터 변경 시 자동으로 화면 갱신
      body: ValueListenableBuilder(
        valueListenable: Hive.box<EmotionEntry>('emotions').listenable(),
        builder: (context, box, _) {

          // 기록 없을 때 안내 문구
          if (box.isEmpty) {
            return const Center(
              child: Text(
                '아직 기록이 없어요\n아래 + 버튼을 눌러 기록해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // 최신순 정렬
          final entries = box.values.toList().reversed.toList();

          // 날짜별 그룹화
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

              // 날짜 파싱 및 요일 계산
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

                  // 날짜 구분선
                  const Divider(height: 24),
                ],
              );
            },
          );
        },
      ),

      // + 버튼 → 감정 기록 화면으로 이동
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

// 스와이프해서 삭제 버튼 노출하는 카드 위젯
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
  // 카드가 얼마나 밀렸는지 (0.0 ~ 80.0)
  double _dragOffset = 0.0;

  // 삭제 버튼 최대 너비 (카드의 1/4)
  static const double _maxOffset = 80.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 왼쪽으로 드래그할 때
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset -= details.delta.dx;
          _dragOffset = _dragOffset.clamp(0.0, _maxOffset);
        });
      },
      // 드래그 끝났을 때 절반 이상 밀면 최대치, 아니면 원래대로
      onHorizontalDragEnd: (details) {
        setState(() {
          _dragOffset = _dragOffset > _maxOffset / 2 ? _maxOffset : 0.0;
        });
      },
      child: Stack(
        children: [

          // 뒤에 깔리는 빨간 삭제 버튼
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                // 빨간 버튼 탭 → 확인 다이얼로그
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

          // 앞에 보이는 감정 카드
          GestureDetector(
            // 밀려있으면 탭 시 원래대로, 아니면 수정 화면으로 이동
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

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 감정 점수 닷(dot) 표시
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

                        // 메모 텍스트
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

                  // 기록 시간
                  Text(
                    widget.entry.createdAt,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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