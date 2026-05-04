import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ledger_entry.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // 예산 저장용 (SharedPreferences 대신 간단히 Map으로 관리)
  final Map<String, TextEditingController> _controllers = {};

  final List<Map<String, String>> _categories = [
    {'name': '전체', 'emoji': '💳'},
    {'name': '식비', 'emoji': '🍔'},
    {'name': '교통', 'emoji': '🚌'},
    {'name': '쇼핑', 'emoji': '🛍️'},
    {'name': '주거', 'emoji': '🏠'},
    {'name': '의료', 'emoji': '💊'},
    {'name': '여가', 'emoji': '🎮'},
    {'name': '교육', 'emoji': '📚'},
    {'name': '기타', 'emoji': '➕'},
  ];

  // 이번 달 카테고리별 지출 합계
  Map<String, int> _getMonthlyExpense() {
    final now = DateTime.now();
    final prefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final box = Hive.box<LedgerEntry>('ledger');
    final entries = box.values
        .where((e) => e.date.startsWith(prefix) && e.type == 'expense')
        .toList();

    final Map<String, int> result = {};
    for (var entry in entries) {
      result[entry.category] = (result[entry.category] ?? 0) + entry.amount;
      result['전체'] = (result['전체'] ?? 0) + entry.amount;
    }
    return result;
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  void initState() {
    super.initState();
    for (var cat in _categories) {
      _controllers[cat['name']!] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthlyExpense = _getMonthlyExpense();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '예산 설정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이번 달 예산을 설정해주세요',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            ...(_categories.map((cat) {
              final name = cat['name']!;
              final emoji = cat['emoji']!;
              final spent = monthlyExpense[name] ?? 0;
              final budgetText = _controllers[name]!.text;
              final budget = int.tryParse(budgetText.replaceAll(',', '')) ?? 0;
              final progress = budget > 0
                  ? (spent / budget).clamp(0.0, 1.0)
                  : 0.0;
              final isOver = budget > 0 && spent > budget;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FC),
                  borderRadius: BorderRadius.circular(14),
                  border: isOver
                      ? Border.all(color: Colors.red.shade300)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (isOver)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '초과!',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 예산 입력
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controllers[name],
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: '예산 입력',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              suffixText: '원',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (budget > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatAmount(spent)}원 지출',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOver ? Colors.red : Colors.grey,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOver
                                  ? Colors.red
                                  : const Color(0xFF534AB7),
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
                          color: isOver ? Colors.red : const Color(0xFF534AB7),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            })),

            const SizedBox(height: 8),
            const Text(
              '※ 예산은 앱을 종료하면 초기화돼요.\n추후 업데이트에서 저장 기능이 추가될 예정이에요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
