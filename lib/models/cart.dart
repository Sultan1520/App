import 'package:flutter_application_1/models/product.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;
  final String user;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.user,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      user: json['user'],
    );
  }

  void addItem(int amount) {
    quantity += amount;
  }
}
