import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';

class AnnouncementsFeedScreen extends StatelessWidget {
  const AnnouncementsFeedScreen({super.key});

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'product_launch':
        return AppTheme.primaryBlue;
      case 'price_update':
        return const Color(0xFF059669);
      case 'urgent':
        return AppTheme.alertRed;
      case 'holiday_closure':
        return const Color(0xFFD97706);
      default:
        return AppTheme.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final annService = context.watch<AnnouncementService>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Factory News & Announcements'),
      ),
      body: annService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : annService.announcements.isEmpty
              ? const Center(child: Text('No announcements posted yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: annService.announcements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final item = annService.announcements[idx];
                    final catColor = _getCategoryColor(item.category);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.pinned ? AppTheme.primaryBlue.withOpacity(0.5) : AppTheme.borderSubtle,
                          width: item.pinned ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: catColor),
                                ),
                              ),
                              if (item.pinned)
                                const Row(
                                  children: [
                                    Icon(Icons.push_pin, size: 14, color: AppTheme.primaryBlue),
                                    SizedBox(width: 4),
                                    Text('PINNED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.message,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            DateFormatter.formatDate(item.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
