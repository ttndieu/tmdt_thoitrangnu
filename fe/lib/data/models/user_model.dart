// lib/data/models/user_model.dart

import 'address_model.dart';

class UserModel {
  final String id;
  final String name;           // ← THÊM
  final String email;
  final String role;
  final String? phone;         // ← THÊM
  final String? avatar;        // ← THÊM
  final List<String> wishlist; // ← THÊM
  final List<AddressModel> addresses; // ← THÊM
  final String token;
  final DateTime? createdAt;   // ← THÊM
  final DateTime? updatedAt;   // ← THÊM

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.wishlist = const [],
    this.addresses = const [],
    required this.token,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["_id"] ?? '',
      name: json["name"] ?? '',
      email: json["email"] ?? '',
      role: json["role"] ?? 'user',
      phone: json["phone"],
      avatar: json["avatar"],
      wishlist: json["wishlist"] != null
          ? List<String>.from(json["wishlist"].map((x) => x.toString()))
          : [],
      addresses: json["addresses"] != null
          ? List<AddressModel>.from(
              json["addresses"].map((x) => AddressModel.fromJson(x)))
          : [],
      token: json["token"] ?? '',
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : null,
      updatedAt: json["updatedAt"] != null
          ? DateTime.parse(json["updatedAt"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "email": email,
      "role": role,
      "phone": phone,
      "avatar": avatar,
      "wishlist": wishlist,
      "addresses": addresses.map((x) => x.toJson()).toList(),
      "token": token,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
  }

  // Helpers
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  AddressModel? get defaultAddress {
    try {
      return addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  bool isInWishlist(String productId) {
    return wishlist.contains(productId);
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatar,
    List<String>? wishlist,
    List<AddressModel>? addresses,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      wishlist: wishlist ?? this.wishlist,
      addresses: addresses ?? this.addresses,
      token: token ?? this.token,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}