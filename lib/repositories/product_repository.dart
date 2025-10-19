import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/product.dart';

class ProductRepository {
  Future<int> insertProduct(Product product) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('products');
    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<Product?> getProductByGTIN(String gtin) async {
    final db = await AppDatabase.instance.database;
    final result =
        await db.query('products', where: 'gtin = ?', whereArgs: [gtin]);
    if (result.isNotEmpty) return Product.fromMap(result.first);
    return null;
  }
}
