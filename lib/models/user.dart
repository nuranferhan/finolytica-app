class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String currency;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.currency = 'TRY',
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'],
      avatarUrl: map['avatar_url'],
      currency: map['currency'] ?? 'TRY',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'currency': currency,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? currency,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName)';
  }
}