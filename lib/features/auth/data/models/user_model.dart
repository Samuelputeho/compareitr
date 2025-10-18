import 'package:compareitr/core/common/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.name,
    required super.phoneNumber,
    required super.email,
    required super.id,
    required super.street,
    required super.location,
    required super.proPic,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    print('📸 Parsing user JSON - proPic field: "${map['proPic']}", propic field: "${map['propic']}"');
    
    // Handle phoneNumber - try lowercase first, then camelCase
    final phoneNumberValue = map['phonenumber'] ?? map['phoneNumber'];
    
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      id: map['id'] ?? '',
      location: map['location'] ?? '',
      street: map['street'] ?? '',
      proPic: map['propic'] ?? map['proPic'] ?? '',  // Try lowercase first, then camelCase
      phoneNumber: phoneNumberValue is int
          ? phoneNumberValue
          : int.tryParse(phoneNumberValue?.toString() ?? '') ?? 0,
      role: map['role'] ?? 'customer',  // Default to 'customer' if role is not set
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? proPic,
    String? street,
    String? location,
    int? phoneNumber,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      proPic: proPic ?? this.proPic,
      street: street ?? this.street,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
    );
  }
}
