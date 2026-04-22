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

  final List<Map<String, dynamic>> _emotions = [
    {'emoji': '😢', 'label': '최악', 'score': 1},
    {'emoji': '😔', 'label': '힘들어', 'score': 2},
    {'emoji': '😐', 'label': '보통', 'score': 3},
    {'emoji': '😊', 'label': '좋아', 'score': 4},
    {'emoji': '😄', 'label': '최고', 'score': 5},
  ];

  @override
  void dispose() {
    _memoController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  // 저장
  void _save() async {
    final box = Hive.box<EmotionEntry>('emotions');
    final now = DateTime.now();
    final entry = EmotionEntry()
      ..date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
      ..score = _selectedScore
      ..emoji = _emotions[_selectedScore - 1]['emoji']
      ..memo = _memoController.text
      ..diary = _diaryController.text
      ..createdAt = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

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
          '오늘 기분은요?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '지금 기분을 선택해주세요',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

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
                              ? Border.all(
                                  color: const Color(0xFF534AB7), width: 2.5)
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

            const SizedBox(height: 36),

            // 한줄 메모
            const Text(
              '한줄 메모',
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
            const SizedBox(height: 4),
            const Text(
              '선택 사항이에요',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _diaryController,
              maxLines: 8,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: '오늘 하루를 자유롭게 기록해보세요.\n\n어떤 일이 있었나요?\n무슨 생각을 했나요?',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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