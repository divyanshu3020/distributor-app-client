import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  IconData _getIcon(String type) {
    switch (type) {
      case 'reorder_reminder':
        return Icons.local_fire_department;
      case 'dispatch_alert':
        return Icons.local_shipping;
      case 'arrival_alert':
        return Icons.location_on;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'reorder_reminder':
        return AppTheme.accentAmber;
      case 'dispatch_alert':
        return AppTheme.primaryBlue;
      case 'arrival_alert':
        return const Color(0xFF16A34A);
      case 'announcement':
        return const Color(0xFF7C3AED);
      default:
        return AppTheme.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifService = context.watch<NotificationService>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          IconButton(
            tooltip: 'Simulate Catchy Reorder Reminder',
            icon: const Icon(Icons.flash_on, color: Colors.amber),
            onPressed: () {
              notifService.simulateZomatoNudge();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚡ Zomato/Swiggy-style catchy reorder push notification received!'),
                  backgroundColor: AppTheme.primaryDark,
                ),
              );
            },
          ),
        ],
      ),
      body: notifService.notifications.isEmpty
          ? const Center(child: Text('No notifications at this time.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifService.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final notif = notifService.notifications[idx];
                final iconColor = _getColor(notif.type);
                final isNudge = notif.type == 'reorder_reminder';

                return InkWell(
                  onTap: () => notifService.markAsRead(notif.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: notif.isRead ? AppTheme.surfaceWhite : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: notif.isRead ? AppTheme.borderSubtle : const Color(0xFFBBF7D0),
                        width: notif.isRead ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getIcon(notif.type), color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                        color: AppTheme.textMain,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.body,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormatter.formatDateTime(notif.createdAt),
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                  if (isNudge)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                      ),
                                      child: const Text(
                                        'REORDER NUDGE',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
