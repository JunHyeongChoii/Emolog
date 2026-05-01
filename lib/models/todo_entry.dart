import 'package:hive/hive.dart';

part 'todo_entry.g.dart';

@HiveType(typeId: 1)
class TodoEntry extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late bool isDone;

  @HiveField(2)
  late String date;

  @HiveField(3)
  late String createdAt;

  @HiveField(4)
  String repeatType;

  @HiveField(5)
  List<int> repeatDays;

  @HiveField(6)
  int repeatDay;

  // 기본값 설정 — 기존 데이터에 필드가 없어도 오류 안 나게
  TodoEntry({
    this.repeatType = 'once',
    this.repeatDays = const [],
    this.repeatDay = 0,
  });
}
