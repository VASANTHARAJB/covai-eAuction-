// lib/user_profile_model.dart

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String address; 
  final String kycStatus;
  final String type;
  final String status;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address, 
    required this.kycStatus,
    required this.type,
    required this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['id']?.toString() ?? '', 
      name: json['name'] ?? 'No Name',
      email: json['email'] ?? '',
      phoneNumber: json['phone'] ?? '',
      address: json['address'] ?? '', 
      // These map directly to your database columns
      kycStatus: json['kyc_status'] ?? 'Pending',
      type: json['type'] ?? 'Individual',
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': userId,
      'name': name,
      'email': email,
      'phone': phoneNumber,
      'address': address, 
    };
  }
}