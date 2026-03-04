// notification_service.dart - 空实现版本
// 这个文件只是为了保留接口，不实际发送系统通知

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 初始化通知（空实现）
  Future<void> init() async {
    // 不执行任何操作
    print('NotificationService.init() called - using mock implementation');
    return;
  }

  // 取消所有通知（空实现）
  Future<void> cancelAll() async {
    // 不执行任何操作
    print('NotificationService.cancelAll() called - using mock implementation');
    return;
  }

  // 显示即时通知（空实现）
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    print('Mock notification: $title - $body');
    return;
  }

  // 显示定时通知（空实现）
  Future<void> showScheduledNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    print('Mock scheduled notification: $title - $body at $scheduledTime');
    return;
  }

  // 显示每日提醒（空实现）
  Future<void> showDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    print('Mock daily reminder: $title - $body at $hour:$minute');
    return;
  }
}