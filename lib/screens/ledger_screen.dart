import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ledger_entry.dart';
import 'add_ledger_screen.dart';
import 'budget_screen.dart';
import 'edit_ledger_screen.dart';
import '../widgets/month_picker_widget.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  String get _monthPrefix => '$_year-${_month.toString().padLeft(2, '0')}';

  String _formatAmount(int amount) {
    final abs = amount.abs();
    if (abs >= 10000) {
      return '${(abs / 10000).toStringAsFixed(abs % 10000 == 0 ? 0 : 1)}만';
    }
    return abs.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatAmountFull(int amount) {
    final abs = amount.abs();
    return abs.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            GestureDetector(
              onTap: _prevMonth,
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF534AB7),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => showMonthPicker(
                context: context,
                year: _year,
                month: _month,
                onChanged: (y, m) => setState(() {
                  _year = y;
                  _month = m;
                }),
                showLedgerDots: true,
              ),
              child: Row(
                children: [
                  Text(
                    '$_year년 $_month월',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Color(0xFF534AB7),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _nextMonth,
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF534AB7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF534AB7),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddLedgerScreen()),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<LedgerEntry>('ledger').listenable(),
        builder: (context, box, _) {
          final entries =
              box.values.where((e) => e.date.startsWith(_monthPrefix)).toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          final totalIncome = entries
              .where((e) => e.type == 'income')
              .fold(0, (sum, e) => sum + e.amount);
          final totalExpense = entries
              .where((e) => e.type == 'expense')
              .fold(0, (sum, e) => sum + e.amount);
          final balance = totalIncome - totalExpense;

          final Map<String, List<LedgerEntry>> grouped = {};
          for (var entry in entries) {
            grouped.putIfAbsent(entry.date, () => []).add(entry);
          }

          return Column(
            children: [
              // 요약 카드
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem(
                      '수입',
                      '+${_formatAmount(totalIncome)}',
                      const Color(0xFF0F6E56),
                    ),
                    Container(
                      width: 0.5,
                      height: 40,
                      color: const Color(0xFFAFA9EC),
                    ),
                    _summaryItem(
                      '지출',
                      '-${_formatAmount(totalExpense)}',
                      const Color(0xFFA32D2D),
                    ),
                    Container(
                      width: 0.5,
                      height: 40,
                      color: const Color(0xFFAFA9EC),
                    ),
                    _summaryItem(
                      '잔액',
                      balance >= 0
                          ? '+${_formatAmount(balance)}'
                          : '-${_formatAmount(balance.abs())}',
                      balance >= 0
                          ? const Color(0xFF534AB7)
                          : const Color(0xFFA32D2D),
                    ),
                  ],
                ),
              ),

              // 내역 리스트
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text(
                          '이번 달 내역이 없어요\n+ 버튼을 눌러 추가해보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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

                          final dayIncome = dayEntries
                              .where((e) => e.type == 'income')
                              .fold(0, (sum, e) => sum + e.amount);
                          final dayExpense = dayEntries
                              .where((e) => e.type == 'expense')
                              .fold(0, (sum, e) => sum + e.amount);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 날짜 헤더
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${parts[1]}/${parts[2]} $weekday',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (dayIncome > 0)
                                      Text(
                                        '+${_formatAmountFull(dayIncome)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF0F6E56),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (dayIncome > 0 && dayExpense > 0)
                                      const SizedBox(width: 8),
                                    if (dayExpense > 0)
                                      Text(
                                        '-${_formatAmountFull(dayExpense)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFA32D2D),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // 내역 카드 (탭 → 수정, 스와이프 → 삭제)
                              ...dayEntries.map(
                                (entry) => GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditLedgerScreen(entry: entry),
                                    ),
                                  ),
                                  child: Dismissible(
                                    key: Key(entry.key.toString()),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.centerRight,
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (_) async {
                                      final result = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          title: const Text(
                                            '내역 삭제',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: const Text('이 내역을 삭제할까요?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text(
                                                '취소',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                '삭제',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (result == true) {
                                        await entry.delete();
                                      }
                                      return false;
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F8FC),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: entry.type == 'income'
                                                  ? const Color(0xFFE1F5EE)
                                                  : const Color(0xFFFCEBEB),
                                            ),
                                            child: Center(
                                              child: Text(
                                                entry.categoryEmoji,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entry.memo.isEmpty
                                                      ? entry.category
                                                      : entry.memo,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                Text(
                                                  entry.category,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            entry.type == 'income'
                                                ? '+${_formatAmountFull(entry.amount)}'
                                                : '-${_formatAmountFull(entry.amount)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: entry.type == 'income'
                                                  ? const Color(0xFF0F6E56)
                                                  : const Color(0xFFA32D2D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const Divider(height: 16),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryItem(String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF534AB7)),
        ),
      ],
    );
  }
}
