import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/todo_entry.dart';
import '../models/ledger_entry.dart';
import 'add_todo_screen.dart';
import 'add_ledger_screen.dart';
import 'edit_ledger_screen.dart';

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

  final List<Map<String, dynamic>> _emotions = [
    {
      'emoji': '😢',
      'label': '최악',
      'score': 1,
      'title': '분노, 극심한 스트레스, 불안',
      'desc': '지금 마음이 너무 폭발할 것 같나요?',
      'color': Color(0xFFFFEBEB),
      'textColor': Color(0xFFA32D2D),
    },
    {
      'emoji': '😔',
      'label': '힘들어',
      'score': 2,
      'title': '우울, 무기력, 슬픔',
      'desc': '할 일 달성률이 급락하기 쉬운 구간이에요',
      'color': Color(0xFFEEEDFE),
      'textColor': Color(0xFF3C3489),
    },
    {
      'emoji': '😐',
      'label': '보통',
      'score': 3,
      'title': '평범함, 차분함, 무던함',
      'desc': '가장 객관적인 판단이 가능한 상태예요',
      'color': Color(0xFFF1EFE8),
      'textColor': Color(0xFF5F5E5A),
    },
    {
      'emoji': '😊',
      'label': '좋아',
      'score': 4,
      'title': '기쁨, 뿌듯함, 감사',
      'desc': '성취감이 높고 지출이 안정적인 구간이에요',
      'color': Color(0xFFE1F5EE),
      'textColor': Color(0xFF085041),
    },
    {
      'emoji': '😄',
      'label': '최고',
      'score': 5,
      'title': '설렘, 열정, 자신감',
      'desc': '에너지가 넘쳐서 할 일을 초과 달성하기 좋은 구간이에요',
      'color': Color(0xFFEAF3DE),
      'textColor': Color(0xFF27500A),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedScore = widget.entry.isEmpty ? 3 : widget.entry.score;
    _memoController = TextEditingController(text: widget.entry.memo);
    _diaryController = TextEditingController(text: widget.entry.diary);
  }

  @override
  void dispose() {
    _memoController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  void _save() async {
    widget.entry.score = _selectedScore;
    widget.entry.emoji = _emotions[_selectedScore - 1]['emoji'];
    widget.entry.memo = _memoController.text;
    widget.entry.diary = _diaryController.text;
    widget.entry.isEmpty = false;
    await widget.entry.save();
    if (mounted) Navigator.pop(context);
  }

  void _toggleDone(TodoEntry todo) {
    todo.isDone = !todo.isDone;
    todo.save();
  }

  Future<void> _confirmDeleteTodo(TodoEntry todo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '할 일 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('이 할 일을 삭제할까요?'),
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
    if (result == true) await todo.delete();
  }

  Future<void> _confirmDeleteLedger(LedgerEntry ledger) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '내역 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('이 내역을 삭제할까요?'),
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
    if (result == true) await ledger.delete();
  }

  String _repeatLabel(TodoEntry todo) {
    if (todo.repeatType == 'weekly') {
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      return todo.repeatDays.map((d) => weekdays[d - 1]).join('·');
    } else if (todo.repeatType == 'monthly') {
      return '매월 ${todo.repeatDay}일';
    }
    return '오늘만';
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEmotion = _emotions[_selectedScore - 1];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.entry.isEmpty ? '감정 기록하기' : '기록 수정',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
              '기분을 선택해주세요',
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF534AB7),
                                  width: 2.5,
                                )
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
                          color: isSelected
                              ? const Color(0xFF534AB7)
                              : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 동적 감정 설명 카드
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(_selectedScore),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: currentEmotion['color'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentEmotion['title'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: currentEmotion['textColor'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentEmotion['desc'],
                      style: TextStyle(
                        fontSize: 13,
                        color: currentEmotion['textColor'],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

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
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTodoScreen(date: widget.entry.date),
                    ),
                  ),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF534AB7),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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

                final done = todos.where((t) => t.isDone).length;
                final progress = done / todos.length;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$done/${todos.length}개 완료',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
                    ...todos.map(
                      (todo) => Container(
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
                                    ? const Icon(
                                        Icons.check,
                                        size: 13,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                todo.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: todo.isDone
                                      ? Colors.grey
                                      : Colors.black87,
                                  decoration: todo.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: todo.repeatType == 'once'
                                    ? const Color(0xFFE1F5EE)
                                    : const Color(0xFFEEEDFE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _repeatLabel(todo),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: todo.repeatType == 'once'
                                      ? const Color(0xFF085041)
                                      : const Color(0xFF534AB7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const Divider(height: 32),

            // 가계부 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '수입/지출',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddLedgerScreen()),
                  ),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF534AB7),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ValueListenableBuilder(
              valueListenable: Hive.box<LedgerEntry>('ledger').listenable(),
              builder: (context, box, _) {
                final ledgers = box.values
                    .where((l) => l.date == widget.entry.date)
                    .toList();

                if (ledgers.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '수입/지출을 추가해보세요!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final totalIncome = ledgers
                    .where((l) => l.type == 'income')
                    .fold(0, (sum, l) => sum + l.amount);
                final totalExpense = ledgers
                    .where((l) => l.type == 'expense')
                    .fold(0, (sum, l) => sum + l.amount);

                return Column(
                  children: [
                    // 수입/지출 요약
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F5EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '+${_formatAmount(totalIncome)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F6E56),
                                  ),
                                ),
                                const Text(
                                  '수입',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF085041),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCEBEB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '-${_formatAmount(totalExpense)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFA32D2D),
                                  ),
                                ),
                                const Text(
                                  '지출',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF791F1F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 내역 카드 (탭 → 수정, − → 삭제)
                    ...ledgers.map(
                      (ledger) => Container(
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
                              onTap: () => _confirmDeleteLedger(ledger),
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

                            // 카테고리 아이콘
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ledger.type == 'income'
                                    ? const Color(0xFFE1F5EE)
                                    : const Color(0xFFFCEBEB),
                              ),
                              child: Center(
                                child: Text(
                                  ledger.categoryEmoji,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 내역 정보
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditLedgerScreen(entry: ledger),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ledger.memo.isEmpty
                                          ? ledger.category
                                          : ledger.memo,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      ledger.category,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 금액
                            Text(
                              ledger.type == 'income'
                                  ? '+${_formatAmount(ledger.amount)}'
                                  : '-${_formatAmount(ledger.amount)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: ledger.type == 'income'
                                    ? const Color(0xFF0F6E56)
                                    : const Color(0xFFA32D2D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                child: Text(
                  widget.entry.isEmpty ? '기록하기' : '수정 완료',
                  style: const TextStyle(
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
