class Product {
  final int id;
  final int vendorId;
  final String? vendorName;
  final String name;
  final String? description;
  final String? category;
  final int? categoryId;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final int? stock;
  final int? preparationTime;

  Product({
    required this.id,
    required this.vendorId,
    this.vendorName,
    required this.name,
    this.description,
    this.category,
    this.categoryId,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.stock,
    this.preparationTime,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      categoryId: json['categoryId'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      stock: json['stock'],
      preparationTime: json['preparationTime'],
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
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'stock': stock,
      'preparationTime': preparationTime,
    };
  }
}
