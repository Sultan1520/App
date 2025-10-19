class Product {
  final int? id;
  final String name;
  final String gtin;
  final String status;
  final double price;
  final String? image;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  Product({
    this.id,
    required this.name,
    required this.gtin,
    required this.status,
    required this.price,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gtin': gtin,
      'status': status,
      'price': price,
      'image': image,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'],
        name: map['name'],
        gtin: map['gtin'],
        status: map['status'],
        price: map['price'],
        image: map['image'],
        createdAt: map['created_at'],
        updatedAt: map['updated_at'],
        deletedAt: map['deleted_at'],
      );
}
