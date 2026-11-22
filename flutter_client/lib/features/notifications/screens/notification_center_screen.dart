import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically mark all as read when user opens the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().markAllAsRead();
    });
  }

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifService.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                notifService.clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications cleared'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(milliseconds: 1500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
      body: notifService.notifications.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 54, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No notifications right now',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifService.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final notif = notifService.notifications[idx];
              final iconColor = _getColor(notif.type);

              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  notifService.removeNotification(notif.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification removed'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 1200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                            Text(
                              notif.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.body,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormatter.formatDate(notif.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
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
