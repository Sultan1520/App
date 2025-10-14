import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/specifications.dart';
import '../models/category.dart';
import '../models/cart.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Ошибка загрузки данных');
    }
  }

  static Future<Product> fetchProductDetail(int productId) async {
  final response = await http.get(Uri.parse('$baseUrl/api/products/$productId/'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return Product.fromJson(data);
  } else {
    throw Exception('Ошибка загрузки данных о товаре');
  }
}

static Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при загрузке категорий');
    }
  }

  Future<List<CartItem>> fetchCartItems(String token) async {
  final response = await http.get(
    Uri.parse('http://127.0.0.1:8000/cart/'),
    headers: {'Authorization': 'Token $token'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => CartItem.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load cart');
  }
}

}
