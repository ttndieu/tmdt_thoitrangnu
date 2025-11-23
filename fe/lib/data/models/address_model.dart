// lib/data/models/address_model.dart

class AddressModel {
  final String? id;
  final String fullName;
  final String phone;
  final String addressLine;
  final String ward;
  final String district;
  final String city;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.ward,
    required this.district,
    required this.city,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id']?.toString(),
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine: json['addressLine'] ?? '',
      ward: json['ward'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'fullName': fullName,
      'phone': phone,
      'addressLine': addressLine,
      'ward': ward,
      'district': district,
      'city': city,
      'isDefault': isDefault,
    };
  }

  String get fullAddress {
    return '$addressLine, $ward, $district, $city';
  }

  AddressModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? addressLine,
    String? ward,
    String? district,
    String? city,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}