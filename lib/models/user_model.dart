class UserModel {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String? photoUrl;
  final String? notes;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.notes,
    this.isAdmin = false,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      username: map['username'] ?? map['email'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['profileImageUrl'],
      notes: map['notes'],
      isAdmin: map['role'] == 'admin' ? true : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'notes': notes,
      'isAdmin': isAdmin, 
    };
  } 

  UserModel copyWith({
    String? username,
    String? email,
    String? phone,
    String? photoUrl,
    String? notes,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
} 