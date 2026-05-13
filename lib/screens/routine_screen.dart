import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo_entry.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // 반복 뱃지 텍스트
  String _repeatLabel(TodoEntry todo) {
    if (todo.repeatType == 'weekly') {
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      return todo.repeatDays.map((d) => weekdays[d - 1]).join('·');
    } else if (todo.repeatType == 'monthly') {
      return '매월 ${todo.repeatDay}일';
    }
    return '오늘만';
  }

  // 삭제 확인 (오늘 이후 항목 전체 삭제)
  Future<void> _confirmDelete(
      BuildContext context, TodoEntry todo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('루틴 삭제',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            '이 루틴을 삭제할까요?\n오늘 이후 항목이 모두 삭제돼요.\n(과거 기록은 유지돼요)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      final box = Hive.box<TodoEntry>('todos');
      final today = _today();
      final toDelete = box.values
          .where((t) =>
              t.title == todo.title &&
              t.repeatType == todo.repeatType &&
              t.date.compareTo(today) >= 0)
          .toList();
      for (final t in toDelete) {
        await t.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '등록된 루틴',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TodoEntry>('todos').listenable(),
        builder: (context, box, _) {
          // 반복 할일만 필터링 (오늘 이후 항목 중 고유한 제목+반복타입)
          final today = _today();
          final allTodos = box.values
              .where((t) =>
                  t.repeatType != 'once' &&
                  t.date.compareTo(today) >= 0)
              .toList();

          // 중복 제거 (제목 + 반복타입 기준)
          final Map<String, TodoEntry> uniqueRoutines = {};
          for (var todo in allTodos) {
            final key = '${todo.title}_${todo.repeatType}';
            if (!uniqueRoutines.containsKey(key)) {
              uniqueRoutines[key] = todo;
            }
          }

          // 매주 / 매월 분리
          final weeklyRoutines = uniqueRoutines.values
              .where((t) => t.repeatType == 'weekly')
              .toList();
          final monthlyRoutines = uniqueRoutines.values
              .where((t) => t.repeatType == 'monthly')
              .toList();

          if (uniqueRoutines.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔁',
                      style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    '등록된 루틴이 없어요\n할 일 추가에서 매주/매월 반복을 설정해보세요!',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // 매주 반복
              if (weeklyRoutines.isNotEmpty) ...[
                const Text(
                  '매주 반복',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...weeklyRoutines.map((todo) => _RoutineCard(
                      todo: todo,
                      repeatLabel: _repeatLabel(todo),
                      onDelete: () =>
                          _confirmDelete(context, todo),
                    )),
                const SizedBox(height: 16),
              ],

              // 매월 반복
              if (monthlyRoutines.isNotEmpty) ...[
                if (weeklyRoutines.isNotEmpty)
                  const Divider(height: 8),
                const SizedBox(height: 16),
                const Text(
                  '매월 반복',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...monthlyRoutines.map((todo) => _RoutineCard(
                      todo: todo,
                      repeatLabel: _repeatLabel(todo),
                      onDelete: () =>
                          _confirmDelete(context, todo),
                    )),
              ],

              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '루틴을 삭제하면 오늘 이후 항목이 모두 삭제돼요',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final TodoEntry todo;
  final String repeatLabel;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.todo,
    required this.repeatLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 반복 아이콘
          const Icon(Icons.repeat_rounded,
              size: 18, color: Color(0xFF534AB7)),
          const SizedBox(width: 12),

          // 제목
          Expanded(
            child: Text(
              todo.title,
              style: const TextStyle(
                  fontSize: 15, color: Colors.black87),
            ),
          ),

          const SizedBox(width: 8),

          // 반복 뱃지
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDFE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              repeatLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF534AB7),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 삭제 버튼
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade50,
              ),
              child: Icon(Icons.delete_outline_rounded,
                  size: 15, color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}