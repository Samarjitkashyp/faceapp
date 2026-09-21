class UserModel {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? employeeId;
  final String? phoneNumber;
  final String? address;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.employeeId,
    this.phoneNumber,
    this.address,
    this.role = 'member',
    this.createdAt,
  });

  String get fullName {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    if (first.isEmpty && last.isEmpty) return username;
    return '$first $last'.trim();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      employeeId: json['employee_id'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      role: json['role'] ?? 'member',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'employee_id': employeeId,
      'phone_number': phoneNumber,
      'address': address,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
