import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/announcement_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'product_launch';
  bool _pinned = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _postAnnouncement() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and message'), backgroundColor: AppTheme.alertRed),
      );
      return;
    }

    final success = await context.read<AnnouncementService>().createAnnouncement(
      title: title,
      message: message,
      category: _category,
      pinned: _pinned,
    );

    if (mounted) {
      if (success) {
        _titleController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement broadcasted to all distributors!'), backgroundColor: AppTheme.successGreen),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final annService = context.watch<AnnouncementService>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Manage Factory Announcements'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Distributor Announcement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _titleController,
                    label: 'Announcement Title',
                    hint: 'e.g., New 20L Bucket Mold Installed',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _messageController,
                    label: 'Announcement Message',
                    hint: 'Details regarding production schedules, pricing, or new lines...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: const [
                      DropdownMenuItem(value: 'product_launch', child: Text('Product Launch')),
                      DropdownMenuItem(value: 'price_update', child: Text('Price Update')),
                      DropdownMenuItem(value: 'general', child: Text('General Notice')),
                      DropdownMenuItem(value: 'holiday_closure', child: Text('Holiday / Maintenance')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent Alert')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Pin Announcement to Top', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _pinned,
                    onChanged: (val) => setState(() => _pinned = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Publish Announcement',
                    icon: Icons.campaign_outlined,
                    onPressed: _postAnnouncement,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Active Published Announcements',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: annService.announcements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = annService.announcements[idx];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          if (item.pinned)
                            const Icon(Icons.push_pin, size: 16, color: AppTheme.primaryBlue),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.message, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
