import 'package:hive/hive.dart';

part 'todo_entry.g.dart';

@HiveType(typeId: 1)
class TodoEntry extends HiveObject {
  @HiveField(0)
  late String title; // 할 일 제목

  @HiveField(1)
  bool isDone = false; // 완료 여부

  @HiveField(2)
  late String date; // 날짜 "2026-05-13"

  @HiveField(3)
  late String createdAt; // 저장 시각

  @HiveField(4)
  String repeatType = 'once'; // 'once' / 'weekly' / 'monthly'

  @HiveField(5)
  List<int> repeatDays = []; // 매주 반복 요일 (1=월 ~ 7=일)

  @HiveField(6)
  int repeatDay = 0; // 매월 반복 날짜

  // ===== 세트 기록 필드 (신규) =====
  @HiveField(7)
  bool isSetType = false; // 세트 기록 여부

  @HiveField(8)
  int repsPerSet = 0; // 세트당 개수 (예: 10)

  @HiveField(9)
  int targetSets = 0; // 목표 세트 수 (예: 5)

  @HiveField(10)
  int completedSets = 0; // 완료한 세트 수 (예: 2)
}
