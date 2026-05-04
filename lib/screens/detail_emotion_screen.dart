import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/todo_entry.dart';
import '../models/ledger_entry.dart';
import 'edit_emotion_screen.dart';

class DetailEmotionScreen extends StatelessWidget {
  final EmotionEntry entry;

  const DetailEmotionScreen({super.key, required this.entry});

  void _toggleDone(TodoEntry todo) {
    todo.isDone = !todo.isDone;
    todo.save();
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    // 빈 항목이면 바로 수정 화면으로 이동
    if (entry.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => EditEmotionScreen(entry: entry)),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                    children: List.generate(
                      5,
                      (i) => Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < entry.score
                              ? const Color(0xFF534AB7)
                              : const Color(0xFFAFA9EC),
                        ),
                      ),
                    ),
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

            const Divider(height: 8),
            const SizedBox(height: 12),

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
              builder: (context, todoBox, _) {
                final todos = todoBox.values
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
                      (todo) => GestureDetector(
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
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
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
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            const Divider(height: 8),
            const SizedBox(height: 12),

            // 가계부 내역
            const Text(
              '오늘 수입/지출',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            ValueListenableBuilder(
              valueListenable: Hive.box<LedgerEntry>('ledger').listenable(),
              builder: (context, ledgerBox, _) {
                final ledgers = ledgerBox.values
                    .where((l) => l.date == entry.date)
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
                      '이 날 수입/지출 기록이 없어요',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // 수입/지출 합계
                final totalIncome = ledgers
                    .where((l) => l.type == 'income')
                    .fold(0, (sum, l) => sum + l.amount);
                final totalExpense = ledgers
                    .where((l) => l.type == 'expense')
                    .fold(0, (sum, l) => sum + l.amount);
                final balance = totalIncome - totalExpense;

                return Column(
                  children: [
                    // 요약 칩
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
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEDFE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _formatAmount(balance),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF534AB7),
                                  ),
                                ),
                                const Text(
                                  '합계',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF3C3489),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 내역 리스트
                    ...ledgers.map(
                      (ledger) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // 카테고리 아이콘
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ledger.type == 'income'
                                    ? const Color(0xFFE1F5EE)
                                    : const Color(0xFFFCEBEB),
                              ),
                              child: Center(
                                child: Text(
                                  ledger.categoryEmoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 내역 정보
                            Expanded(
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
