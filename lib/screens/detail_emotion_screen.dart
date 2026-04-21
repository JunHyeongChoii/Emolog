import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/todo_entry.dart';

class DetailEmotionScreen extends StatelessWidget {
  final EmotionEntry entry;

  const DetailEmotionScreen({super.key, required this.entry});

  // 할일 완료 토글
  void _toggleDone(TodoEntry todo) {
    todo.isDone = !todo.isDone;
    todo.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          entry.date,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 감정 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(entry.emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < entry.score
                            ? const Color(0xFF534AB7)
                            : const Color(0xFFAFA9EC),
                      ),
                    )),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ['', '최악', '힘들어', '보통', '좋아', '최고'][entry.score],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF534AB7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.createdAt} 기록',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF534AB7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 한줄 메모
            if (entry.memo.isNotEmpty) ...[
              const Text(
                '한줄 메모',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.memo,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 일기 본문
            if (entry.diary.isNotEmpty) ...[
              const Text(
                '일기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.diary,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 오늘 할 일 (체크 가능)
            const Text(
              '오늘 할 일',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            ValueListenableBuilder(
              valueListenable: Hive.box<TodoEntry>('todos').listenable(),
              builder: (context, box, _) {
                final todos = box.values
                    .where((t) => t.date == entry.date)
                    .toList();

                if (todos.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '이 날 할 일 기록이 없어요',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // 완료율 계산
                final done = todos.where((t) => t.isDone).length;
                final progress = done / todos.length;

                return Column(
                  children: [
                    // 완료율 바
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$done/${todos.length}개 완료',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF534AB7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF534AB7),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 할일 목록 (체크 가능!)
                    ...todos.map((todo) => GestureDetector(
                      onTap: () => _toggleDone(todo),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // 체크 버튼 (탭 가능)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: todo.isDone
                                    ? const Color(0xFF534AB7)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: todo.isDone
                                      ? const Color(0xFF534AB7)
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: todo.isDone
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                todo.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: todo.isDone
                                      ? Colors.grey
                                      : Colors.black87,
                                  decoration: todo.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}