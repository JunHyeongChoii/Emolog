import 'package:hive/hive.dart';

part 'ledger_entry.g.dart';

@HiveType(typeId: 2)
class LedgerEntry extends HiveObject {
  @HiveField(0)
  late String date; // 날짜 "2026-05-04"

  @HiveField(1)
  late int amount; // 금액 (양수=수입, 음수=지출)

  @HiveField(2)
  late String type; // 'income' / 'expense'

  @HiveField(3)
  late String category; // '식비' / '교통' / '쇼핑' 등

  @HiveField(4)
  late String categoryEmoji; // '🍔' / '🚌' / '🛍️' 등

  @HiveField(5)
  late String memo; // 메모

  @HiveField(6)
  late String createdAt; // 저장 시각
}
