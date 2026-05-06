import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 0);

  // 알림 토글
  Future<void> _toggleNotification(bool value) async {
    setState(() => _isEnabled = value);

    if (value) {
      await NotificationService().scheduleDailyNotification(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '매일 ${_selectedTime.format(context)}에 알림이 올 거예요!',
            ),
            backgroundColor: const Color(0xFF534AB7),
          ),
        );
      }
    } else {
      await NotificationService().cancelNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림이 꺼졌어요')),
        );
      }
    }
  }

  // 시간 선택
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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

    if (picked != null) {
      setState(() => _selectedTime = picked);
      if (_isEnabled) {
        await NotificationService().scheduleDailyNotification(
          hour: picked.hour,
          minute: picked.minute,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '알림 시간이 ${picked.format(context)}으로 변경됐어요!',
              ),
              backgroundColor: const Color(0xFF534AB7),
            ),
          );
        }
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
          '알림 설정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 알림 설명 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Text('🔔', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '매일 감정 기록 알림',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3C3489),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '설정한 시간에 감정 기록을\n잊지 않도록 알려드려요!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF534AB7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 알림 켜기/끄기
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('📱', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알림 받기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '매일 감정 기록 알림을 받아요',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEnabled,
                    onChanged: _toggleNotification,
                    activeColor: const Color(0xFF534AB7),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 알림 시간 설정
            GestureDetector(
              onTap: _isEnabled ? _pickTime : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isEnabled
                      ? const Color(0xFFF8F8FC)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      '⏰',
                      style: TextStyle(
                        fontSize: 24,
                        color: _isEnabled ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '알림 시간',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _isEnabled
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                          Text(
                            '탭해서 시간을 변경해요',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isEnabled
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _selectedTime.format(context),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isEnabled
                            ? const Color(0xFF534AB7)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _isEnabled
                          ? const Color(0xFF534AB7)
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 안내 문구
            const Text(
              '※ 알림은 앱을 완전히 종료해도 작동해요.\n※ 기기 설정에서 앱 알림이 허용되어 있어야 해요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}