class UserModel {
  final String id;
  final String email;
  final String role;
  final String token; // thêm dòng này !!

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["_id"],
      email: json["email"],
      role: json["role"],
      token: json["token"], // thêm dòng này !!
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "email": email,
      "role": role,
      "token": token, // thêm dòng này !!
    };
  }
}
