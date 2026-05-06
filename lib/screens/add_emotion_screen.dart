import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emotion_entry.dart';

class AddEmotionScreen extends StatefulWidget {
  const AddEmotionScreen({super.key});

  @override
  State<AddEmotionScreen> createState() => _AddEmotionScreenState();
}

class _AddEmotionScreenState extends State<AddEmotionScreen> {
  int _selectedScore = 3;
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _diaryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _emotions = [
    {
      'emoji': '😢', 'label': '최악', 'score': 1,
      'title': '분노, 극심한 스트레스, 불안',
      'desc': '지금 마음이 너무 폭발할 것 같나요?',
      'color': Color(0xFFFFEBEB), 'textColor': Color(0xFFA32D2D),
    },
    {
      'emoji': '😔', 'label': '힘들어', 'score': 2,
      'title': '우울, 무기력, 슬픔',
      'desc': '할 일 달성률이 급락하기 쉬운 구간이에요',
      'color': Color(0xFFEEEDFE), 'textColor': Color(0xFF3C3489),
    },
    {
      'emoji': '😐', 'label': '보통', 'score': 3,
      'title': '평범함, 차분함, 무던함',
      'desc': '가장 객관적인 판단이 가능한 상태예요',
      'color': Color(0xFFF1EFE8), 'textColor': Color(0xFF5F5E5A),
    },
    {
      'emoji': '😊', 'label': '좋아', 'score': 4,
      'title': '기쁨, 뿌듯함, 감사',
      'desc': '성취감이 높고 지출이 안정적인 구간이에요',
      'color': Color(0xFFE1F5EE), 'textColor': Color(0xFF085041),
    },
    {
      'emoji': '😄', 'label': '최고', 'score': 5,
      'title': '설렘, 열정, 자신감',
      'desc': '에너지가 넘쳐서 할 일을 초과 달성하기 좋은 구간이에요',
      'color': Color(0xFFEAF3DE), 'textColor': Color(0xFF27500A),
    },
  ];

  @override
  void dispose() {
    _memoController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  // 날짜 선택
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF534AB7),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() async {
    final box = Hive.box<EmotionEntry>('emotions');
    final now = DateTime.now();
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    // 해당 날짜에 이미 빈 항목이 있으면 업데이트
    final existing = box.values
        .where((e) => e.date == dateStr)
        .toList();

    if (existing.isNotEmpty && existing.first.isEmpty) {
      // 빈 항목 업데이트
      final entry = existing.first;
      entry.score = _selectedScore;
      entry.emoji = _emotions[_selectedScore - 1]['emoji'];
      entry.memo = _memoController.text;
      entry.diary = _diaryController.text;
      entry.isEmpty = false;
      entry.createdAt =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await entry.save();
    } else if (existing.isEmpty) {
      // 새 항목 추가
      final entry = EmotionEntry()
        ..date = dateStr
        ..score = _selectedScore
        ..emoji = _emotions[_selectedScore - 1]['emoji']
        ..memo = _memoController.text
        ..diary = _diaryController.text
        ..isEmpty = false
        ..createdAt =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await box.add(entry);
    } else {
      // 이미 기록된 날짜면 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 해당 날짜에 감정이 기록되어 있어요!'),
            backgroundColor: Color(0xFF534AB7),
          ),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentEmotion = _emotions[_selectedScore - 1];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '오늘 기분은요?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 날짜 선택
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: Color(0xFF534AB7)),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                      style: const TextStyle(
                          fontSize: 15, color: Colors.black87),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF534AB7)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '지금 기분을 선택해주세요',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 이모지 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _emotions.map((e) {
                final isSelected = _selectedScore == e['score'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedScore = e['score']),
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
                                  width: 2.5)
                              : null,
                          color: isSelected
                              ? const Color(0xFFEEEDFE)
                              : Colors.transparent,
                        ),
                        child: Text(
                          e['emoji'],
                          style: TextStyle(
                              fontSize: isSelected ? 40 : 32),
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
                    horizontal: 16, vertical: 14),
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
            const Text('한줄 메모',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('선택 사항이에요',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
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
            const Text('일기',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('선택 사항이에요',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: _diaryController,
              maxLines: 8,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText:
                    '오늘 하루를 자유롭게 기록해보세요.\n\n어떤 일이 있었나요?\n무슨 생각을 했나요?',
                hintStyle: const TextStyle(
                    color: Colors.grey, fontSize: 14),
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