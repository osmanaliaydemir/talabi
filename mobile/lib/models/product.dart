class Product {
  final int id;
  final int vendorId;
  final String? vendorName;
  final String name;
  final String? description;
  final String? category;
  final double price;
  final String? imageUrl;

  Product({
    required this.id,
    required this.vendorId,
    this.vendorName,
    required this.name,
    this.description,
    this.category,
    required this.price,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
    );
  }
}
