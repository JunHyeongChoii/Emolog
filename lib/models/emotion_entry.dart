import 'package:hive/hive.dart';

part 'emotion_entry.g.dart';

@HiveType(typeId: 0)
class EmotionEntry extends HiveObject {
  @HiveField(0)
  late String date;

  @HiveField(1)
  late int score;

  @HiveField(2)
  late String emoji;

  @HiveField(3)
  late String memo;

  @HiveField(4)
  late String createdAt;

  @HiveField(5)
  late String diary;

  @HiveField(6)
  bool isEmpty;

  // 기본값 설정
  EmotionEntry({this.isEmpty = false});
}
