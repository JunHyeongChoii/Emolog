import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/todo_entry.dart';

class EditEmotionScreen extends StatefulWidget {
  final EmotionEntry entry;

  const EditEmotionScreen({super.key, required this.entry});

  @override
  State<EditEmotionScreen> createState() => _EditEmotionScreenState();
}

class _EditEmotionScreenState extends State<EditEmotionScreen> {
  late int _selectedScore;
  late TextEditingController _memoController;
  late TextEditingController _diaryController;
  final TextEditingController _todoController = TextEditingController();
  bool _showTodoInput = false;

  final List<Map<String, dynamic>> _emotions = [
    {'emoji': '😢', 'label': '최악', 'score': 1},
    {'emoji': '😔', 'label': '힘들어', 'score': 2},
    {'emoji': '😐', 'label': '보통', 'score': 3},
    {'emoji': '😊', 'label': '좋아', 'score': 4},
    {'emoji': '😄', 'label': '최고', 'score': 5},
  ];

  @override
  void initState() {
    super.initState();
    _selectedScore = widget.entry.score;
    _memoController = TextEditingController(text: widget.entry.memo);
    _diaryController = TextEditingController(text: widget.entry.diary);
  }

  @override
  void dispose() {
    _memoController.dispose();
    _diaryController.dispose();
    _todoController.dispose();
    super.dispose();
  }

  // 감정 기록 저장
  void _save() async {
    widget.entry.score = _selectedScore;
    widget.entry.emoji = _emotions[_selectedScore - 1]['emoji'];
    widget.entry.memo = _memoController.text;
    widget.entry.diary = _diaryController.text;
    await widget.entry.save();
    if (mounted) Navigator.pop(context);
  }

  // 할일 추가
  void _addTodo() {
    if (_todoController.text.trim().isEmpty) return;
    final box = Hive.box<TodoEntry>('todos');
    final now = DateTime.now();
    final todo = TodoEntry()
      ..title = _todoController.text.trim()
      ..isDone = false
      ..date = widget.entry.date
      ..createdAt = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    box.add(todo);
    _todoController.clear();
    setState(() => _showTodoInput = false);
  }

  // 할일 완료 토글
  void _toggleDone(TodoEntry todo) {
    todo.isDone = !todo.isDone;
    todo.save();
  }

  // 할일 삭제 확인
  Future<void> _confirmDeleteTodo(TodoEntry todo) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '기록 수정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
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
                widget.entry.date,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              '기분을 수정해주세요',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 이모지 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _emotions.map((e) {
                final isSelected = _selectedScore == e['score'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedScore = e['score']),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: const Color(0xFF534AB7), width: 2.5)
                              : null,
                          color: isSelected
                              ? const Color(0xFFEEEDFE)
                              : Colors.transparent,
                        ),
                        child: Text(
                          e['emoji'],
                          style: TextStyle(fontSize: isSelected ? 40 : 32),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        e['label'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? const Color(0xFF534AB7) : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

            // 한줄 메모
            const Text(
              '한줄 메모',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: '오늘 하루 한 줄로 표현하면?',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Divider(height: 32),

            // 일기
            const Text(
              '일기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _diaryController,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: '오늘 하루를 자유롭게 기록해보세요.',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Divider(height: 32),

            // 할일 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '할 일',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // + 버튼
                GestureDetector(
                  onTap: () => setState(() => _showTodoInput = !_showTodoInput),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF534AB7),
                    ),
                    child: Icon(
                      _showTodoInput ? Icons.close : Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 할일 입력창 (+ 눌렀을 때 나타남)
            if (_showTodoInput) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _todoController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '할 일 입력...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
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
              const SizedBox(height: 12),
            ],

            // 할일 목록
            ValueListenableBuilder(
              valueListenable: Hive.box<TodoEntry>('todos').listenable(),
              builder: (context, box, _) {
                final todos = box.values
                    .where((t) => t.date == widget.entry.date)
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
                      '할 일을 추가해보세요!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // 완료율
                final done = todos.where((t) => t.isDone).length;
                final progress = done / todos.length;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$done/${todos.length}개 완료',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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

                    // 할일 카드 (왼쪽 - 버튼, 체크 가능)
                    ...todos.map((todo) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // − 삭제 버튼
                          GestureDetector(
                            onTap: () => _confirmDeleteTodo(todo),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.shade50,
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 14,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 체크 버튼
                          GestureDetector(
                            onTap: () => _toggleDone(todo),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
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
                                      size: 13, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 할일 텍스트
                          Expanded(
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: todo.isDone ? Colors.grey : Colors.black87,
                                decoration: todo.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // 수정 완료 버튼
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
                  '수정 완료',
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
}