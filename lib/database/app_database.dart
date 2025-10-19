import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/stock.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Таблица Товары
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gtin TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL,
        price REAL NOT NULL,
        image TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // Таблица Остатки
    await db.execute('''
      CREATE TABLE stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warehouse TEXT NOT NULL,
        gtin TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (gtin) REFERENCES products (gtin)
      )
    ''');
  }

  Future close() async {
    final db = await database;
    db.close();
  }

  Future<List<Product>> getProducts() async {
    final db = await instance.database;

    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  // для добавления товара
  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
  final db = await instance.database;

  return await db.update(
    'products',
    product.toMap(),
    where: 'id = ?',
    whereArgs: [product.id],
  );
}

Future<int> deleteProduct(int id) async {
  final db = await instance.database;

  return await db.delete(
    'products',
    where: 'id = ?',
    whereArgs: [id],
  );
}

/// Добавление нового остатка
  Future<int> insertStock(Stock stock) async {
    final db = await database;
    return await db.insert('stock', stock.toMap());
  }

  /// Получение всех остатков
  Future<List<Stock>> getStocks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('stock');
    return List.generate(maps.length, (i) => Stock.fromMap(maps[i]));
  }

  /// Получение остатков по товару
  Future<List<Stock>> getStocksByProduct(String gtin) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock',
      where: 'gtin = ?',
      whereArgs: [gtin],
    );
    return List.generate(maps.length, (i) => Stock.fromMap(maps[i]));
  }

  /// Получение остатков по складу
  Future<List<Stock>> getStocksByWarehouse(String warehouse) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock',
      where: 'warehouse = ?',
      whereArgs: [warehouse],
    );
    return List.generate(maps.length, (i) => Stock.fromMap(maps[i]));
  }

  /// Обновление остатка
  Future<int> updateStock(Stock stock) async {
    final db = await database;
    return await db.update(
      'stock',
      stock.toMap(),
      where: 'id = ?',
      whereArgs: [stock.id],
    );
  }

  /// Удаление остатка
  Future<int> deleteStock(int id) async {
    final db = await database;
    return await db.delete('stock', where: 'id = ?', whereArgs: [id]);
  }

  /// Получение общего количества товара на всех складах
  Future<int> getTotalQuantityForProduct(String gtin) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM stock WHERE gtin = ?',
      [gtin],
    );
    return result.first['total'] as int? ?? 0;
  }


}
