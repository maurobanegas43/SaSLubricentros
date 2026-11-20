class User {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final String? role;
  final bool? isActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.role,
    this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      isActive: json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive,
    };
  }

  @override
  String toString() => 'User(id: $id, email: $email, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
