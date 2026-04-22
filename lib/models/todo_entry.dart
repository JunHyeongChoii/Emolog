import 'package:hive/hive.dart';

part 'todo_entry.g.dart';

@HiveType(typeId: 1)
class TodoEntry extends HiveObject {
  @HiveField(0)
  late String title;        // 할일 내용

  @HiveField(1)
  late bool isDone;         // 완료 여부

  @HiveField(2)
  late String date;         // 날짜 "2026-04-21"

  @HiveField(3)
  late String createdAt;    // 생성 시각

  @HiveField(4)
  late String repeatType;   // 'once' / 'weekly' / 'monthly'

  @HiveField(5)
  late List<int> repeatDays; // 매주: [1,3,5] (월=1, 화=2 ... 일=7)

  @HiveField(6)
  late int repeatDay;       // 매월: 1~31
}