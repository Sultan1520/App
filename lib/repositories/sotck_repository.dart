import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/stock.dart';

class StockRepository {
  Future<int> insertStock(Stock stock) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('stock', stock.toMap());
  }

  Future<List<Stock>> getStockByGTIN(String gtin) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('stock', where: 'gtin = ?', whereArgs: [gtin]);
    return result.map((e) => Stock.fromMap(e)).toList();
  }
}
