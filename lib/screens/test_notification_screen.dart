import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/font_size_listener.dart';
import '../l10n/app_translations.dart';
import '../providers/language_provider.dart';

class TestNotificationScreen extends StatelessWidget {
  const TestNotificationScreen({super.key});

  void _showMockNotification(BuildContext context, String title, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return FontSizeListener(
          child: const SizedBox(),
          builder: (context, fontSize) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  AppTranslations.translate(context, 'test_notifications'),
                  style: TextStyle(fontSize: fontSize + 4),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card - 说明这是模拟通知
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.translate(context, 'demo_mode'),
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppTranslations.translate(context, 'notification_info'),
                                    style: TextStyle(
                                      fontSize: fontSize - 2,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Instant Notifications
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.notifications_active, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  AppTranslations.translate(context, 'instant_notifications'),
                                  style: TextStyle(
                                    fontSize: fontSize + 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildNotificationButton(
                              context,
                              Icons.notifications,
                              AppTranslations.translate(context, 'test_notification'),
                              AppTranslations.translate(context, 'test_notification_desc'),
                              Colors.blue,
                              fontSize,
                                  () {
                                _showMockNotification(
                                  context,
                                  AppTranslations.translate(context, 'test_notification'),
                                  AppTranslations.translate(context, 'test_notification_message'),
                                  Colors.blue,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildNotificationButton(
                              context,
                              Icons.newspaper,
                              AppTranslations.translate(context, 'news_update'),
                              AppTranslations.translate(context, 'news_update_desc'),
                              Colors.green,
                              fontSize,
                                  () {
                                _showMockNotification(
                                  context,
                                  AppTranslations.translate(context, 'news_update'),
                                  AppTranslations.translate(context, 'news_update_message'),
                                  Colors.green,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildNotificationButton(
                              context,
                              Icons.account_balance_wallet,
                              AppTranslations.translate(context, 'balance_update'),
                              AppTranslations.translate(context, 'balance_update_desc'),
                              Colors.purple,
                              fontSize,
                                  () {
                                _showMockNotification(
                                  context,
                                  AppTranslations.translate(context, 'balance_update'),
                                  AppTranslations.translate(context, 'balance_update_message'),
                                  Colors.purple,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Scheduled Notifications
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Text(
                                  AppTranslations.translate(context, 'scheduled_notifications'),
                                  style: TextStyle(
                                    fontSize: fontSize + 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildNotificationButton(
                              context,
                              Icons.timer_outlined,
                              AppTranslations.translate(context, 'schedule_5_seconds'),
                              AppTranslations.translate(context, 'schedule_5_seconds_desc'),
                              Colors.orange,
                              fontSize,
                                  () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.translate(context, 'notification_scheduled_5'),
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );

                                Future.delayed(const Duration(seconds: 5), () {
                                  _showMockNotification(
                                    context,
                                    AppTranslations.translate(context, 'scheduled_notification'),
                                    AppTranslations.translate(context, 'scheduled_notification_message_5'),
                                    Colors.orange,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildNotificationButton(
                              context,
                              Icons.timer_outlined,
                              AppTranslations.translate(context, 'schedule_10_seconds'),
                              AppTranslations.translate(context, 'schedule_10_seconds_desc'),
                              Colors.deepOrange,
                              fontSize,
                                  () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.translate(context, 'notification_scheduled_10'),
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );

                                Future.delayed(const Duration(seconds: 10), () {
                                  _showMockNotification(
                                    context,
                                    AppTranslations.translate(context, 'scheduled_notification'),
                                    AppTranslations.translate(context, 'scheduled_notification_message_10'),
                                    Colors.deepOrange,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Daily Reminders
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.alarm, color: Colors.teal[700]),
                                const SizedBox(width: 8),
                                Text(
                                  AppTranslations.translate(context, 'daily_reminders'),
                                  style: TextStyle(
                                    fontSize: fontSize + 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildNotificationButton(
                              context,
                              Icons.wb_sunny,
                              AppTranslations.translate(context, 'morning_reminder'),
                              AppTranslations.translate(context, 'morning_reminder_desc'),
                              Colors.amber,
                              fontSize,
                                  () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.translate(context, 'morning_reminder_set'),
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                    backgroundColor: Colors.amber,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildNotificationButton(
                              context,
                              Icons.nightlight,
                              AppTranslations.translate(context, 'evening_reminder'),
                              AppTranslations.translate(context, 'evening_reminder_desc'),
                              Colors.indigo,
                              fontSize,
                                  () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.translate(context, 'evening_reminder_set'),
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                    backgroundColor: Colors.indigo,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Clear All
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.settings, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Text(
                                  AppTranslations.translate(context, 'manage_notifications'),
                                  style: TextStyle(
                                    fontSize: fontSize + 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildNotificationButton(
                              context,
                              Icons.cancel,
                              AppTranslations.translate(context, 'clear_all_notifications'),
                              AppTranslations.translate(context, 'clear_all_notifications_desc'),
                              Colors.red,
                              fontSize,
                                  () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppTranslations.translate(context, 'notifications_cleared'),
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationButton(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Color color,
      double fontSize,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: fontSize - 4,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}