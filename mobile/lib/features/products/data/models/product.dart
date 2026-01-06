import 'package:mobile/features/settings/data/models/currency.dart';

class Product {
  Product({
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
    this.isAvailable = true,
    this.stock,
    this.preparationTime,
    this.vendorType,
    this.isBestSeller = false,
    this.rating,
    this.reviewCount,
    this.optionGroups = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
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
      isAvailable: json['isAvailable'] ?? true,
      stock: json['stock'],
      preparationTime: json['preparationTime'],
      vendorType: json['vendorType'],
      isBestSeller: json['isBestSeller'] ?? false,
      rating:
          (json['rating'] as num?)?.toDouble() ??
          (json['averageRating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'],
      optionGroups:
          (json['optionGroups'] as List<dynamic>?)
              ?.map(
                (e) => ProductOptionGroup.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'name': name,
      'description': description,
      'category': category,
      'categoryId': categoryId,
      'price': price,
      'currency': currency.toInt(),
      'currencyCode': currency.code,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'stock': stock,
      'preparationTime': preparationTime,
      'isBestSeller': isBestSeller,
      'rating': rating,
      'reviewCount': reviewCount,
      'optionGroups': optionGroups.map((e) => e.toJson()).toList(),
    };
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
  final bool isAvailable;
  final int? stock;
  final int? preparationTime;
  final int? vendorType;
  final bool isBestSeller;
  final double? rating;
  final int? reviewCount;
  final List<ProductOptionGroup> optionGroups;
}

class ProductOptionGroup {
  ProductOptionGroup({
    this.id,
    required this.name,
    this.isRequired = false,
    this.allowMultiple = false,
    this.minSelection = 0,
    this.maxSelection = 0,
    this.displayOrder = 0,
    this.options = const [],
  });

  factory ProductOptionGroup.fromJson(Map<String, dynamic> json) {
    return ProductOptionGroup(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      isRequired: json['isRequired'] ?? false,
      allowMultiple: json['allowMultiple'] ?? false,
      minSelection: json['minSelection'] ?? 0,
      maxSelection: json['maxSelection'] ?? 0,
      displayOrder: json['displayOrder'] ?? 0,
      options:
          (json['options'] as List<dynamic>?)
              ?.map(
                (e) => ProductOptionValue.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'isRequired': isRequired,
      'allowMultiple': allowMultiple,
      'minSelection': minSelection,
      'maxSelection': maxSelection,
      'displayOrder': displayOrder,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }

  final String? id;
  final String name;
  final bool isRequired;
  final bool allowMultiple;
  final int minSelection;
  final int maxSelection;
  final int displayOrder;
  final List<ProductOptionValue> options;
}

class ProductOptionValue {
  ProductOptionValue({
    this.id,
    required this.name,
    this.priceAdjustment = 0,
    this.isDefault = false,
    this.displayOrder = 0,
  });

  factory ProductOptionValue.fromJson(Map<String, dynamic> json) {
    return ProductOptionValue(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble() ?? 0,
      isDefault: json['isDefault'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'priceAdjustment': priceAdjustment,
      'isDefault': isDefault,
      'displayOrder': displayOrder,
    };
  }

  final String? id;
  final String name;
  final double priceAdjustment;
  final bool isDefault;
  final int displayOrder;
}
