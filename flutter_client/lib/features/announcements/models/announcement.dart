class Announcement {
  final String id;
  final String title;
  final String message;
  final String category; // 'product_launch', 'price_update', 'holiday_closure', 'urgent', 'general'
  final bool isPublished;
  final bool pinned;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.isPublished,
    required this.pinned,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      category: json['category'] as String? ?? 'general',
      isPublished: json['is_published'] as bool? ?? true,
      pinned: json['pinned'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'is_published': isPublished,
      'pinned': pinned,
    };
  }
}
