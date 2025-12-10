class Review {
  final String id;
  final String userId;
  final String userFullName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? productId;
  final String? vendorName;

  Review({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.productId,
    this.vendorName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      userId: json['userId'] ?? '',
      userFullName: json['userFullName'] ?? 'Anonymous',
      rating: json['rating'],
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      productId: json['productId']?.toString(),
      vendorName: json['vendorName'],
    );
  }
}

class ProductReviewsSummary {
  final double averageRating;
  final int totalRatings;
  final int totalComments;
  final List<Review> reviews;

  ProductReviewsSummary({
    required this.averageRating,
    required this.totalRatings,
    required this.totalComments,
    required this.reviews,
  });

  factory ProductReviewsSummary.fromJson(Map<String, dynamic> json) {
    return ProductReviewsSummary(
      averageRating: (json['averageRating'] as num).toDouble(),
      totalRatings: json['totalRatings'],
      totalComments: json['totalComments'],
      reviews: (json['reviews'] as List)
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
