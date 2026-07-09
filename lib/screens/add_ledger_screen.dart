import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ledger_entry.dart';

class AddLedgerScreen extends StatefulWidget {
  final String? initialDate;

  const AddLedgerScreen({super.key, this.initialDate});

  @override
  State<AddLedgerScreen> createState() => _AddLedgerScreenState();
}

class _AddLedgerScreenState extends State<AddLedgerScreen> {
  String _type = 'expense';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  String _selectedCategory = '식비';
  String _selectedEmoji = '🍔';
  late DateTime _selectedDate;
  bool _isUpdating = false;

  // Phase 1: 소비 감정 (0=미선택, 1=후회, 2=그저그럼, 3=만족, 4=최고)
  int _spendMood = 0;
  final List<Map<String, dynamic>> _moodOptions = [
    {'value': 1, 'emoji': '😩', 'label': '후회'},
    {'value': 2, 'emoji': '😐', 'label': '그저그럼'},
    {'value': 3, 'emoji': '😊', 'label': '만족'},
    {'value': 4, 'emoji': '🤩', 'label': '최고'},
  ];

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

  String _addComma(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialDate != null) {
      final parts = widget.initialDate!.split('-');
      _selectedDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } else {
      _selectedDate = DateTime.now();
    }

    _amountController.addListener(() {
      if (_isUpdating) return;
      _isUpdating = true;

      final text = _amountController.text.replaceAll(',', '');
      if (text.isEmpty) {
        _isUpdating = false;
        return;
      }

      final number = int.tryParse(text);
      if (number != null) {
        final formatted = _addComma(number);
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      _isUpdating = false;
    });
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

    final box = Hive.box<LedgerEntry>('ledger');
    final now = DateTime.now();
    final entry = LedgerEntry()
      ..date =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'
      ..amount = amount
      ..type = _type
      ..category = _selectedCategory
      ..categoryEmoji = _selectedEmoji
      ..memo = _memoController.text
      ..spendMood = _type == 'expense' ? _spendMood : 0
      ..createdAt =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    await box.add(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '내역 추가',
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

            // Phase 1: 소비 감정 (지출일 때만 표시)
            if (_type == 'expense') ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF5C97B),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💭 이 지출, 기분이 어때요?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8A5A00),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '선택하면 만족/후회 소비 리포트를 볼 수 있어요',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB08030)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _moodOptions.map((m) {
                        final isSelected = _spendMood == m['value'];
                        return GestureDetector(
                          onTap: () => setState(() {
                            // 같은 걸 다시 누르면 해제
                            _spendMood = isSelected ? 0 : m['value'] as int;
                          }),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFFFCEFD4)
                                      : Colors.transparent,
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xFFF5A623),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Text(
                                  m['emoji'] as String,
                                  style: TextStyle(
                                    fontSize: isSelected ? 30 : 24,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m['label'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF8A5A00)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

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
                hintText: '',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 저장 버튼
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
                  '저장하기',
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
