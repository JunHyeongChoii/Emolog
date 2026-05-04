import 'package:flutter/material.dart';
import '../models/ledger_entry.dart';

class EditLedgerScreen extends StatefulWidget {
  final LedgerEntry entry;

  const EditLedgerScreen({super.key, required this.entry});

  @override
  State<EditLedgerScreen> createState() => _EditLedgerScreenState();
}

class _EditLedgerScreenState extends State<EditLedgerScreen> {
  late String _type;
  late TextEditingController _amountController;
  late TextEditingController _memoController;
  late String _selectedCategory;
  late String _selectedEmoji;
  late DateTime _selectedDate;

  final List<Map<String, String>> _expenseCategories = [
    {'name': '식비', 'emoji': '🍔'},
    {'name': '교통', 'emoji': '🚌'},
    {'name': '쇼핑', 'emoji': '🛍️'},
    {'name': '주거', 'emoji': '🏠'},
    {'name': '의료', 'emoji': '💊'},
    {'name': '여가', 'emoji': '🎮'},
    {'name': '교육', 'emoji': '📚'},
    {'name': '기타', 'emoji': '➕'},
  ];

  final List<Map<String, String>> _incomeCategories = [
    {'name': '월급', 'emoji': '💰'},
    {'name': '용돈', 'emoji': '🎁'},
    {'name': '부업', 'emoji': '💼'},
    {'name': '환급', 'emoji': '🔄'},
    {'name': '기타', 'emoji': '➕'},
  ];

  List<Map<String, String>> get _categories =>
      _type == 'expense' ? _expenseCategories : _incomeCategories;

  @override
  void initState() {
    super.initState();
    // 기존 데이터로 초기화
    _type = widget.entry.type;
    _amountController = TextEditingController(
      text: widget.entry.amount.toString(),
    );
    _memoController = TextEditingController(text: widget.entry.memo);
    _selectedCategory = widget.entry.category;
    _selectedEmoji = widget.entry.categoryEmoji;
    final parts = widget.entry.date.split('-');
    _selectedDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() async {
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('금액을 입력해주세요!')));
      return;
    }

    final amount = int.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 금액을 입력해주세요!')));
      return;
    }

    widget.entry.date =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    widget.entry.amount = amount;
    widget.entry.type = _type;
    widget.entry.category = _selectedCategory;
    widget.entry.categoryEmoji = _selectedEmoji;
    widget.entry.memo = _memoController.text;
    await widget.entry.save();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '내역 수정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 수입/지출 탭
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _type = 'expense';
                      _selectedCategory = '식비';
                      _selectedEmoji = '🍔';
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'expense'
                            ? const Color(0xFFFCEBEB)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _type == 'expense'
                              ? const Color(0xFFA32D2D)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '지출',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _type == 'expense'
                              ? const Color(0xFFA32D2D)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _type = 'income';
                      _selectedCategory = '월급';
                      _selectedEmoji = '💰';
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'income'
                            ? const Color(0xFFE1F5EE)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _type == 'income'
                              ? const Color(0xFF0F6E56)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '수입',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _type == 'income'
                              ? const Color(0xFF0F6E56)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 날짜 선택
            const Text(
              '날짜',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 금액 입력
            const Text(
              '금액',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.grey),
                suffixText: '원',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _type == 'expense'
                    ? const Color(0xFFA32D2D)
                    : const Color(0xFF0F6E56),
              ),
            ),

            const SizedBox(height: 24),

            // 카테고리 선택
            const Text(
              '카테고리',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat['name']!;
                    _selectedEmoji = cat['emoji']!;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (_type == 'expense'
                                ? const Color(0xFFFCEBEB)
                                : const Color(0xFFE1F5EE))
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? (_type == 'expense'
                                  ? const Color(0xFFA32D2D)
                                  : const Color(0xFF0F6E56))
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '${cat['emoji']} ${cat['name']}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? (_type == 'expense'
                                  ? const Color(0xFFA32D2D)
                                  : const Color(0xFF0F6E56))
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 메모
            const Text(
              '메모',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '선택 사항이에요',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              maxLength: 30,
              decoration: InputDecoration(
                hintText: '어디서 쓴 돈인가요?',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

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
