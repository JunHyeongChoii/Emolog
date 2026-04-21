import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo_entry.dart';
import '../models/emotion_entry.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _todayLabel {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${weekdays[now.weekday - 1]}';
  }

  void _addTodo() {
    if (_controller.text.trim().isEmpty) return;
    final box = Hive.box<TodoEntry>('todos');
    final now = DateTime.now();
    final todo = TodoEntry()
      ..title = _controller.text.trim()
      ..isDone = false
      ..date = _today
      ..createdAt = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    box.add(todo);
    _controller.clear();
  }

  void _toggleDone(TodoEntry todo) {
    todo.isDone = !todo.isDone;
    todo.save();
  }

  Future<void> _confirmDelete(TodoEntry todo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('할 일 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('이 할 일을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (result == true) await todo.delete();
  }

  void _showEmotionDetail(BuildContext context, EmotionEntry entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '오늘 감정 기록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(entry.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < entry.score
                      ? const Color(0xFF534AB7)
                      : Colors.grey.shade300,
                ),
              )),
            ),
            const SizedBox(height: 12),
            if (entry.memo.isNotEmpty)
              Text(
                entry.memo,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            if (entry.diary.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${entry.createdAt} 기록',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '오늘 할 일',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TodoEntry>('todos').listenable(),
        builder: (context, todoBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<EmotionEntry>('emotions').listenable(),
            builder: (context, emotionBox, _) {
              final todos = todoBox.values
                  .where((t) => t.date == _today)
                  .toList();

              final todayEmotions = emotionBox.values
                  .where((e) => e.date == _today)
                  .toList();
              final latestEmotion =
                  todayEmotions.isNotEmpty ? todayEmotions.last : null;

              final total = todos.length;
              final done = todos.where((t) => t.isDone).length;
              final progress = total == 0 ? 0.0 : done / total;

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      children: [
                        Text(
                          _todayLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 오늘 감정 섹션
                        const Text(
                          '오늘 감정',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        latestEmotion != null
                            ? GestureDetector(
                                onTap: () => _showEmotionDetail(
                                    context, latestEmotion),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEEDFE),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(latestEmotion.emoji,
                                          style:
                                              const TextStyle(fontSize: 30)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: List.generate(
                                                  5,
                                                  (i) => Container(
                                                        width: 7,
                                                        height: 7,
                                                        margin: const EdgeInsets
                                                            .only(right: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: i 
                                                                  <latestEmotion
                                                                      .score
                                                              ? const Color(
                                                                  0xFF534AB7)
                                                              : const Color(
                                                                  0xFFAFA9EC),
                                                        ),
                                                      )),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              latestEmotion.memo.isEmpty
                                                  ? '메모 없음'
                                                  : latestEmotion.memo,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: latestEmotion
                                                        .memo.isEmpty
                                                    ? const Color.fromRGBO(83, 74, 183, 0.6)
                                                    : const Color(0xFF3C3489),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${latestEmotion.createdAt} 기록',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF534AB7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF534AB7),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8FC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.grey.shade200),
                                ),
                                child: const Center(
                                  child: Text(
                                    '아직 오늘 감정을 기록하지 않았어요',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                ),
                              ),

                        const SizedBox(height: 20),

                        // 할 일 섹션
                        const Text(
                          '할 일',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (total > 0) ...[
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$done개 완료',
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
                        ],

                        if (todos.isEmpty)
                          const Center(
                            child: Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                '오늘 할 일을 추가해보세요!',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ...todos.map((todo) => Dismissible(
                                key: Key(todo.key.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 8),
                                  padding:
                                      const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  await _confirmDelete(todo);
                                  return false;
                                },
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 8),
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F8FC),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _toggleDone(todo),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: todo.isDone
                                                ? const Color(0xFF534AB7)
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: todo.isDone
                                                  ? const Color(
                                                      0xFF534AB7)
                                                  : Colors.grey.shade400,
                                              width: 2,
                                            ),
                                          ),
                                          child: todo.isDone
                                              ? const Icon(Icons.check,
                                                  size: 14,
                                                  color: Colors.white)
                                              : null,
                                        ),
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
                                                ? TextDecoration
                                                    .lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),

                  // 입력창
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: '할 일 입력...',
                              hintStyle:
                                  const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _addTodo(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addTodo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF534AB7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            '추가',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}