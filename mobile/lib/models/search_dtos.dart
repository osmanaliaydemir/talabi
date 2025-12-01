import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';

class ProductSearchRequestDto {
  final String? query;
  final String? category;
  final int? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final int? vendorId;
  final String? sortBy; // "price_asc", "price_desc", "name", "newest"
  final int page;
  final int pageSize;

  ProductSearchRequestDto({
    this.query,
    this.category,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.vendorId,
    this.sortBy,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'page': page, 'pageSize': pageSize};

    if (query != null && query!.isNotEmpty) {
      map['query'] = query;
    }
    if (category != null && category!.isNotEmpty) {
      map['category'] = category;
    }
    if (categoryId != null) {
      map['categoryId'] = categoryId;
    }
    if (minPrice != null) {
      map['minPrice'] = minPrice;
    }
    if (maxPrice != null) {
      map['maxPrice'] = maxPrice;
    }
    if (vendorId != null) {
      map['vendorId'] = vendorId;
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      map['sortBy'] = sortBy;
    }

    return map;
  }
}

class VendorSearchRequestDto {
  final String? query;
  final String? city;
  final double? minRating;
  final double? userLatitude;
  final double? userLongitude;
  final double? maxDistanceInKm;
  final String?
  sortBy; // "name", "newest", "rating_desc", "popularity", "distance"
  final int page;
  final int pageSize;

  VendorSearchRequestDto({
    this.query,
    this.city,
    this.minRating,
    this.userLatitude,
    this.userLongitude,
    this.maxDistanceInKm,
    this.sortBy,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'page': page, 'pageSize': pageSize};

    if (query != null && query!.isNotEmpty) {
      map['query'] = query;
    }
    if (city != null && city!.isNotEmpty) {
      map['city'] = city;
    }
    if (minRating != null) {
      map['minRating'] = minRating;
    }
    if (userLatitude != null) {
      map['userLatitude'] = userLatitude;
    }
    if (userLongitude != null) {
      map['userLongitude'] = userLongitude;
    }
    if (maxDistanceInKm != null) {
      map['maxDistanceInKm'] = maxDistanceInKm;
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      map['sortBy'] = sortBy;
    }

    return map;
  }
}

class PagedResultDto<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedResultDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedResultDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResultDto<T>(
      items: (json['items'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}

class AutocompleteResultDto {
  final int id;
  final String name;
  final String type; // "product" or "vendor"

  AutocompleteResultDto({
    required this.id,
    required this.name,
    required this.type,
  });

  factory AutocompleteResultDto.fromJson(Map<String, dynamic> json) {
    return AutocompleteResultDto(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}

// Helper classes for typed PagedResultDto
class ProductDto {
  final int id;
  final int vendorId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;

  ProductDto({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
    );
  }

  Product toProduct() {
    return Product(
      id: id,
      vendorId: vendorId,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
    );
  }
}

class VendorDto {
  final int id;
  final String name;
  final String? imageUrl;
  final String address;
  final String? city;
  final double? rating;
  final int ratingCount;
  final double? latitude;
  final double? longitude;
  final double? distanceInKm;

  VendorDto({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.address,
    this.city,
    this.rating,
    this.ratingCount = 0,
    this.latitude,
    this.longitude,
    this.distanceInKm,
  });

  factory VendorDto.fromJson(Map<String, dynamic> json) {
    return VendorDto(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      address: json['address'],
      city: json['city'],
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      ratingCount: json['ratingCount'] ?? 0,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      distanceInKm: json['distanceInKm'] != null
          ? (json['distanceInKm'] as num).toDouble()
          : null,
    );
  }

  Vendor toVendor() {
    return Vendor(
      id: id,
      name: name,
      imageUrl: imageUrl,
      address: address,
      city: city,
      rating: rating,
      ratingCount: ratingCount,
      latitude: latitude,
      longitude: longitude,
      distanceInKm: distanceInKm,
    );
  }
}
