import 'package:flutter/material.dart';
import '../models/emotion_entry.dart';

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
    {'emoji': '😢', 'label': '최악', 'score': 1},
    {'emoji': '😔', 'label': '힘들어', 'score': 2},
    {'emoji': '😐', 'label': '보통', 'score': 3},
    {'emoji': '😊', 'label': '좋아', 'score': 4},
    {'emoji': '😄', 'label': '최고', 'score': 5},
  ];

  @override
  void initState() {
    super.initState();
    // 기존 기록 값으로 초기화
    _selectedScore = widget.entry.score;
    _memoController = TextEditingController(text: widget.entry.memo);
    // 기존 기록에 diary 필드가 없을 수 있어서 예외 처리
    _diaryController = TextEditingController(
      text: widget.entry.diary.isEmpty ? '' : widget.entry.diary,
    );
  }

  @override
  void dispose() {
    _memoController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  // 수정 내용 저장
  void _save() async {
    widget.entry.score = _selectedScore;
    widget.entry.emoji = _emotions[_selectedScore - 1]['emoji'];
    widget.entry.memo = _memoController.text;
    widget.entry.diary = _diaryController.text;
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
          '기록 수정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // 키보드 올라올 때 스크롤 가능하도록
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 표시 (수정 불가)
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

            // 일기 본문
            Row(
              children: [
                const Text(
                  '일기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF085041),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _diaryController,
              maxLines: 8,
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