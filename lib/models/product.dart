import 'specifications.dart';
import 'category.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final String company;
  final double price;
  final double? originalPrice;
  final String image;
  final String color;
  final String storage;
  final double count;
  final List<Specification> specifications;
  final int category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.company,
    required this.price,
    this.originalPrice,
    required this.image,
    required this.color,
    required this.storage,
    required this.count,
    this.specifications = const [],
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
  double parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  return Product(
    id: json['id'],
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    company: json['company'] ?? '',
    price: parseToDouble(json['price']),
    originalPrice: json['original_price'] != null
        ? parseToDouble(json['original_price'])
        : null,
    image: json['image'] ?? '',
    color: json['color'] ?? '',
    storage: json['storage'] ?? '',
    count: parseToDouble(json['count']),
    specifications: (json['specifications'] as List?)
            ?.map((e) => Specification.fromJson(e))
            .toList() ??
        [],
    category: json['category'] ?? 0,
  );
}

}
