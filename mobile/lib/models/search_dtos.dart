import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/models/currency.dart';

class ProductSearchRequestDto {
  ProductSearchRequestDto({
    this.query,
    this.category,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.vendorId,
    this.vendorType,
    this.sortBy,
    this.page = 1,
    this.pageSize = 20,
  });
  final String? query;
  final String? category;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final String? vendorId;
  final int? vendorType; // 1 = Restaurant, 2 = Market
  final String? sortBy; // "price_asc", "price_desc", "name", "newest"
  final int page;
  final int pageSize;
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
    if (vendorType != null) {
      map['vendorType'] = vendorType;
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      map['sortBy'] = sortBy;
    }

    return map;
  }
}

class VendorSearchRequestDto {
  VendorSearchRequestDto({
    this.query,
    this.city,
    this.minRating,
    this.userLatitude,
    this.userLongitude,
    this.maxDistanceInKm,
    this.vendorType,
    this.sortBy,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? query;
  final String? city;
  final double? minRating;
  final double? userLatitude;
  final double? userLongitude;
  final double? maxDistanceInKm;
  final int? vendorType; // 1 = Restaurant, 2 = Market
  final String?
  sortBy; // "name", "newest", "rating_desc", "popularity", "distance"
  final int page;
  final int pageSize;

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
    if (vendorType != null) {
      map['vendorType'] = vendorType;
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      map['sortBy'] = sortBy;
    }

    return map;
  }
}

class PagedResultDto<T> {
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
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
}

class AutocompleteResultDto {
  AutocompleteResultDto({
    required this.id,
    required this.name,
    required this.type,
    this.imageUrl,
  });

  factory AutocompleteResultDto.fromJson(Map<String, dynamic> json) {
    return AutocompleteResultDto(
      id: json['id'].toString(),
      name: json['name'],
      imageUrl: json['imageUrl'],
      type: json['type'],
    );
  }
  final String id;
  final String name;
  final String? imageUrl;
  final String type; // "product" or "vendor"
}

// Helper classes for typed PagedResultDto
class ProductDto {
  ProductDto({
    required this.id,
    required this.vendorId,
    this.vendorName,
    required this.name,
    this.description,
    this.category,
    this.categoryId,
    required this.price,
    this.currency = Currency.try_,
    this.imageUrl,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'].toString(),
      vendorId: json['vendorId'].toString(),
      vendorName: json['vendorName'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      categoryId: json['categoryId']?.toString(),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] != null
          ? Currency.fromInt(json['currency'] as int?)
          : Currency.fromString(json['currencyCode'] as String?),
      imageUrl: json['imageUrl'],
    );
  }
  final String id;
  final String vendorId;
  final String? vendorName;
  final String name;
  final String? description;
  final String? category;
  final String? categoryId;
  final double price;
  final Currency currency;
  final String? imageUrl;

  Product toProduct() {
    return Product(
      id: id,
      vendorId: vendorId,
      vendorName: vendorName,
      name: name,
      description: description,
      category: category,
      categoryId: categoryId,
      price: price,
      currency: currency,
      imageUrl: imageUrl,
    );
  }
}

class VendorDto {
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
      id: json['id'].toString(),
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
  final String id;
  final String name;
  final String? imageUrl;
  final String address;
  final String? city;
  final double? rating;
  final int ratingCount;
  final double? latitude;
  final double? longitude;
  final double? distanceInKm;

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
