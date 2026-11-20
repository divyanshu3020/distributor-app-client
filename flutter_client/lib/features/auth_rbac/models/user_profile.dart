class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role; // 'super_admin' | 'staff' | 'distributor'
  final String? businessName;
  final String? gstNumber;
  final String? address;
  final String? fcmToken;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.businessName,
    this.gstNumber,
    this.address,
    this.fcmToken,
    required this.createdAt,
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isStaff => role == 'staff';
  bool get isDistributor => role == 'distributor';

  String get roleDisplay {
    switch (role) {
      case 'super_admin':
        return 'Super Admin (Owner)';
      case 'staff':
        return 'Restricted Staff (Accountant/Marketing)';
      case 'distributor':
        return 'B2B Distributor';
      default:
        return role;
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'User',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'distributor',
      businessName: json['business_name'] as String?,
      gstNumber: json['gst_number'] as String?,
      address: json['address'] as String?,
      fcmToken: json['fcm_token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'business_name': businessName,
      'gst_number': gstNumber,
      'address': address,
      'fcm_token': fcmToken,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? role,
    String? businessName,
    String? gstNumber,
    String? address,
    String? fcmToken,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
