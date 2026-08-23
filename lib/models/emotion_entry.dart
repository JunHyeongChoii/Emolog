import 'package:hive/hive.dart';

part 'emotion_entry.g.dart';

@HiveType(typeId: 0)
class EmotionEntry extends HiveObject {
  @HiveField(0)
  late String date; // 날짜 "2026-05-13"

  @HiveField(1)
  late int score; // 감정 점수 (0~5)

  @HiveField(2)
  late String emoji; // 이모지

  @HiveField(3)
  late String memo; // 한줄 메모

  @HiveField(4)
  late String createdAt; // 저장 시각

  @HiveField(5)
  String diary = ''; // 일기 본문

  @HiveField(6)
  bool isEmpty = false; // 빈 항목 여부

  // ===== Phase 1: 감정 원인 태그 (신규) =====
  @HiveField(7, defaultValue: <String>[])
  List<String> tags = []; // 감정 원인 태그 (예: ['과제·일', '돈'])
}
