class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String productId;
  final String productName;
  final String productImage;
  final String orderId;
  final int rating;
  final String comment;
  final List<ReviewImage> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Parse user
    final user = json['user'] is Map ? json['user'] : {};
    
    // Parse product
    final product = json['product'] is Map ? json['product'] : {};
    final productImages = product['images'] is List ? product['images'] : [];
    
    return ReviewModel(
      id: json['_id'] ?? '',
      userId: user['_id'] ?? '',
      userName: user['name'] ?? 'Anonymous',
      userAvatar: user['avatar'],
      productId: product['_id'] ?? '',
      productName: product['name'] ?? '',
      productImage: productImages.isNotEmpty 
          ? (productImages[0]['url'] ?? '') 
          : '',
      orderId: json['order'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      images: (json['images'] as List?)
              ?.map((e) => ReviewImage.fromJson(e))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': {
        '_id': userId,
        'name': userName,
        'avatar': userAvatar,
      },
      'product': {
        '_id': productId,
        'name': productName,
      },
      'order': orderId,
      'rating': rating,
      'comment': comment,
      'images': images.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }
}

class ReviewImage {
  final String url;
  final String publicId;

  ReviewImage({
    required this.url,
    required this.publicId,
  });

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(
      url: json['url'] ?? '',
      publicId: json['public_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'public_id': publicId,
    };
  }
}

// ✅ CAN REVIEW RESPONSE MODEL
class CanReviewResponse {
  final bool canReview;
  final String? reason;
  final String? orderId;
  final ExistingReview? existingReview;

  CanReviewResponse({
    required this.canReview,
    this.reason,
    this.orderId,
    this.existingReview,
  });

  factory CanReviewResponse.fromJson(Map<String, dynamic> json) {
    return CanReviewResponse(
      canReview: json['canReview'] ?? false,
      reason: json['reason'],
      orderId: json['orderId'],
      existingReview: json['existingReview'] != null
          ? ExistingReview.fromJson(json['existingReview'])
          : null,
    );
  }
}

class ExistingReview {
  final String id;
  final int rating;
  final String comment;

  ExistingReview({
    required this.id,
    required this.rating,
    required this.comment,
  });

  factory ExistingReview.fromJson(Map<String, dynamic> json) {
    return ExistingReview(
      id: json['id'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
    );
  }
}