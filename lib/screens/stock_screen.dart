import 'package:flutter/material.dart';
import '../models/stock.dart';
import '../models/product.dart';
import '../database/app_database.dart';

/// Экран управления складами и остатками товаров
class StocksScreen extends StatefulWidget {
  const StocksScreen({Key? key}) : super(key: key);

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> with SingleTickerProviderStateMixin {
  final AppDatabase _dbHelper = AppDatabase.instance;
  List<Stock> _stocks = [];
  List<Stock> _filteredStocks = [];
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedWarehouse = 'Все склады';
  List<String> _warehouses = ['Все склады'];
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _loadData();
  }

  /// Загружает все данные из базы данных
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final stocks = await _dbHelper.getStocks();
      final products = await _dbHelper.getProducts();
      
      // Извлекаем уникальные названия складов
      final warehouseSet = stocks.map((s) => s.warehouse).toSet();
      
      setState(() {
        _stocks = stocks;
        _products = products;
        _warehouses = ['Все склады', ...warehouseSet.toList()..sort()];
        _isLoading = false;
        _applyFilters();
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Ошибка загрузки данных: $e', isError: true);
    }
  }

  /// Применяет все активные фильтры к списку остатков
  void _applyFilters() {
    List<Stock> filtered = List.from(_stocks);

    // Фильтр по выбранному складу
    if (_selectedWarehouse != 'Все склады') {
      filtered = filtered.where((s) => s.warehouse == _selectedWarehouse).toList();
    }

    // Поиск по названию товара или склада
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((stock) {
        final product = _getProduct(stock.gtin);
        return stock.warehouse.toLowerCase().contains(query) ||
               product.name.toLowerCase().contains(query) ||
               stock.gtin.toLowerCase().contains(query);
      }).toList();
    }

    // Сортировка по названию товара
    filtered.sort((a, b) {
      final productA = _getProduct(a.gtin);
      final productB = _getProduct(b.gtin);
      return productA.name.compareTo(productB.name);
    });

    setState(() => _filteredStocks = filtered);
  }

  /// Получает товар по GTIN
  Product _getProduct(String gtin) {
    return _products.firstWhere(
      (p) => p.gtin == gtin,
      orElse: () => Product(
        name: 'Неизвестный товар',
        gtin: gtin,
        status: 'unknown',
        price: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Показывает диалог добавления остатка
  void _showAddStockDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStockDialog(
        products: _products,
        existingStocks: _stocks,
        onSave: (gtin, warehouse, quantity) async {
          try {
            // Проверяем, есть ли уже товар на этом складе
            final existingStock = _stocks.firstWhere(
              (s) => s.gtin == gtin && s.warehouse == warehouse,
              orElse: () => Stock(
                gtin: '',
                warehouse: '',
                quantity: 0,
              ),
            );

            if (existingStock.gtin.isNotEmpty) {
              // Товар уже есть - увеличиваем количество
              existingStock.quantity += quantity;
              await _dbHelper.updateStock(existingStock);
              _showSnackBar('Количество товара увеличено на $quantity шт.');
            } else {
              // Создаем новую запись
              final newStock = Stock(
                gtin: gtin,
                warehouse: warehouse,
                quantity: quantity,
              );
              await _dbHelper.insertStock(newStock);
              _showSnackBar('Остаток добавлен');
            }
            
            _loadData();
          } catch (e) {
            _showSnackBar('Ошибка сохранения: $e', isError: true);
          }
        },
      ),
    );
  }

  /// Показывает диалог редактирования остатка
  void _showEditStockDialog(Stock stock) {
    showDialog(
      context: context,
      builder: (context) => EditStockDialog(
        stock: stock,
        product: _getProduct(stock.gtin),
        onSave: (newQuantity) async {
          try {
            stock.quantity = newQuantity;
            await _dbHelper.updateStock(stock);
            _showSnackBar('Остаток обновлен');
            _loadData();
          } catch (e) {
            _showSnackBar('Ошибка обновления: $e', isError: true);
          }
        },
      ),
    );
  }

  /// С валидацией количества
  void _showRemoveStockDialog(Stock stock) {
    showDialog(
      context: context,
      builder: (context) => RemoveStockDialog(
        stock: stock,
        product: _getProduct(stock.gtin),
        onRemove: (quantity) async {
          try {
            if (quantity >= stock.quantity) {
              // Удаляем запись полностью
              await _dbHelper.deleteStock(stock.id!);
              _showSnackBar('Товар удален со склада');
            } else {
              // Уменьшаем количество
              stock.quantity -= quantity;
              await _dbHelper.updateStock(stock);
              _showSnackBar('Количество уменьшено на $quantity шт.');
            }
            _loadData();
          } catch (e) {
            _showSnackBar('Ошибка удаления: $e', isError: true);
          }
        },
      ),
    );
  }

  /// Показывает подробную статистику по складам
  void _showStatistics() {
    final totalProducts = _filteredStocks.length;
    final totalQuantity = _filteredStocks.fold<int>(0, (sum, s) => sum + s.quantity);
    
    // Статистика по складам
    final warehouseStats = <String, Map<String, int>>{};
    for (var stock in _filteredStocks) {
      if (!warehouseStats.containsKey(stock.warehouse)) {
        warehouseStats[stock.warehouse] = {'positions': 0, 'quantity': 0};
      }
      warehouseStats[stock.warehouse]!['positions'] = 
          (warehouseStats[stock.warehouse]!['positions'] ?? 0) + 1;
      warehouseStats[stock.warehouse]!['quantity'] = 
          (warehouseStats[stock.warehouse]!['quantity'] ?? 0) + stock.quantity;
    }

    // Товары с низкими остатками
    final lowStockItems = _filteredStocks.where((s) => s.quantity < 10).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Статистика складов',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Общая статистика
              _buildStatCard(
                icon: Icons.inventory_2,
                title: 'Всего позиций',
                value: '$totalProducts',
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.numbers,
                title: 'Общее количество',
                value: '$totalQuantity шт.',
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.warehouse,
                title: 'Складов',
                value: '${warehouseStats.length}',
                color: Colors.orange,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Статистика по складам
              Text(
                'По складам',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...warehouseStats.entries.map((entry) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warehouse, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatChip(
                            'Позиций: ${entry.value['positions']}',
                            Colors.blue,
                          ),
                          _buildStatChip(
                            'Количество: ${entry.value['quantity']} шт.',
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),

              if (lowStockItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Низкие остатки (< 10 шт.)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...lowStockItems.map((stock) {
                  final product = _getProduct(stock.gtin);
                  return ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text(product.name),
                    subtitle: Text(stock.warehouse),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${stock.quantity} шт.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Создает карточку со статистикой
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Создает чип для статистики
  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// Показывает SnackBar с сообщением
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Управление складами'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatistics,
            tooltip: 'Статистика',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Панель поиска и фильтров
                _buildSearchAndFilters(isDark),

                // Информационная панель
                if (_filteredStocks.isNotEmpty) _buildInfoPanel(),

                // Список остатков
                Expanded(child: _buildStocksList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStockDialog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
        elevation: 4,
      ),
    );
  }

  /// Создает панель поиска и фильтров
  Widget _buildSearchAndFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Поиск
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск по товару, складу или GTIN',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (_) => _applyFilters(),
          ),
          const SizedBox(height: 12),

          // Фильтр по складу
          DropdownButtonFormField<String>(
            value: _selectedWarehouse,
            decoration: InputDecoration(
              labelText: 'Фильтр по складу',
              prefixIcon: const Icon(Icons.warehouse),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: _warehouses.map((warehouse) {
              return DropdownMenuItem(
                value: warehouse,
                child: Text(warehouse),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedWarehouse = value!);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  /// Создает информационную панель с краткой статистикой
  Widget _buildInfoPanel() {
    final totalQuantity = _filteredStocks.fold<int>(0, (sum, s) => sum + s.quantity);
    final lowStockCount = _filteredStocks.where((s) => s.quantity < 10).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: Icons.inventory_2,
            label: 'Позиций',
            value: '${_filteredStocks.length}',
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildInfoItem(
            icon: Icons.numbers,
            label: 'Всего шт.',
            value: '$totalQuantity',
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildInfoItem(
            icon: Icons.warning_amber,
            label: 'Низкий остаток',
            value: '$lowStockCount',
          ),
        ],
      ),
    );
  }

  /// Создает элемент информационной панели
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Создает список остатков
  Widget _buildStocksList() {
    if (_filteredStocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warehouse_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _stocks.isEmpty ? 'Нет остатков' : 'Ничего не найдено',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _stocks.isEmpty
                  ? 'Добавьте первый остаток товара'
                  : 'Попробуйте изменить фильтры',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStocks.length,
        itemBuilder: (context, index) {
          final stock = _filteredStocks[index];
          return _buildStockCard(stock, index);
        },
      ),
    );
  }

  /// Создает карточку остатка товара
  Widget _buildStockCard(Stock stock, int index) {
    final product = _getProduct(stock.gtin);
    final isLowStock = stock.quantity < 10;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showEditStockDialog(stock),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Иконка товара
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLowStock
                              ? [Colors.orange[300]!, Colors.orange[500]!]
                              : [Colors.blue[300]!, Colors.blue[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isLowStock ? Colors.orange : Colors.blue)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Информация о товаре
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GTIN: ${stock.gtin}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Количество
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? Colors.orange.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLowStock
                              ? Colors.orange.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${stock.quantity}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? Colors.orange[700] : Colors.green[700],
                            ),
                          ),
                          Text(
                            'шт.',
                            style: TextStyle(
                              fontSize: 10,
                              color: isLowStock ? Colors.orange[600] : Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Склад и кнопки действий
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warehouse,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stock.warehouse,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Кнопки действий
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: Colors.blue,
                      onPressed: () => _showEditStockDialog(stock),
                      tooltip: 'Редактировать',
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, size: 20),
                      color: Colors.orange,
                      onPressed: () => _showRemoveStockDialog(stock),
                      tooltip: 'Уменьшить/Удалить',
                    ),
                  ],
                ),

                // Предупреждение о низком остатке
                if (isLowStock)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Низкий остаток - требуется пополнение',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}


/// Автоматически увеличивает количество для существующих товаров
class AddStockDialog extends StatefulWidget {
  final List<Product> products;
  final List<Stock> existingStocks;
  final Function(String gtin, String warehouse, int quantity) onSave;

  const AddStockDialog({
    Key? key,
    required this.products,
    required this.existingStocks,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _warehouseController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String? _selectedGtin;
  
  // Предопределенные склады для быстрого выбора
  final List<String> _predefinedWarehouses = [
    'Основной склад',
    'Склад №1',
    'Склад №2',
    'Региональный склад',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_box, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Добавить остаток',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Выбор товара
                DropdownButtonFormField<String>(
                  value: _selectedGtin,
                  decoration: InputDecoration(
                    labelText: 'Товар *',
                    prefixIcon: const Icon(Icons.inventory_2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  items: widget.products.map((product) {
                    return DropdownMenuItem<String>(
                      value: product.gtin,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'GTIN: ${product.gtin}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGtin = value),
                  validator: (value) => value == null ? 'Выберите товар' : null,
                  isExpanded: true,
                ),
                const SizedBox(height: 16),

                // Название склада с автозаполнением
                Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _predefinedWarehouses;
                    }
                    return _predefinedWarehouses.where((warehouse) =>
                      warehouse.toLowerCase().contains(textEditingValue.text.toLowerCase())
                    );
                  },
                  onSelected: (value) => _warehouseController.text = value,
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    _warehouseController.text = controller.text;
                    controller.addListener(() {
                      _warehouseController.text = controller.text;
                    });
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Название склада *',
                        prefixIcon: const Icon(Icons.warehouse),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      validator: (value) => 
                        value?.isEmpty == true ? 'Введите название склада' : null,
                      onEditingComplete: onEditingComplete,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Количество
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Количество *',
                    prefixIcon: const Icon(Icons.numbers),
                    suffixText: 'шт.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Введите количество';
                    final quantity = int.tryParse(value!);
                    if (quantity == null) return 'Введите целое число';
                    if (quantity <= 0) return 'Количество должно быть больше 0';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Информационное сообщение
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Если товар уже есть на складе, количество будет увеличено',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Кнопки
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Добавить'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _selectedGtin!,
        _warehouseController.text.trim(),
        int.parse(_quantityController.text),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _warehouseController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}

/// Диалог редактирования остатка
class EditStockDialog extends StatefulWidget {
  final Stock stock;
  final Product product;
  final Function(int newQuantity) onSave;

  const EditStockDialog({
    Key? key,
    required this.stock,
    required this.product,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditStockDialog> createState() => _EditStockDialogState();
}

class _EditStockDialogState extends State<EditStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.stock.quantity.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Редактировать остаток',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Информация о товаре
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.warehouse, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.stock.warehouse,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GTIN: ${widget.stock.gtin}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Поле количества
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Новое количество *',
                  prefixIcon: const Icon(Icons.numbers),
                  suffixText: 'шт.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Введите количество';
                  final quantity = int.tryParse(value!);
                  if (quantity == null) return 'Введите целое число';
                  if (quantity < 0) return 'Количество не может быть отрицательным';
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 24),

              // Кнопки
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Сохранить'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(int.parse(_quantityController.text));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}

/// Диалог удаления/уменьшения остатка с валидацией
class RemoveStockDialog extends StatefulWidget {
  final Stock stock;
  final Product product;
  final Function(int quantity) onRemove;

  const RemoveStockDialog({
    Key? key,
    required this.stock,
    required this.product,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<RemoveStockDialog> createState() => _RemoveStockDialogState();
}

class _RemoveStockDialogState extends State<RemoveStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  bool _removeAll = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.remove_circle, color: Colors.red, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Уменьшить остаток',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Информация о товаре
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.warehouse, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.stock.warehouse,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Текущий остаток: ${widget.stock.quantity} шт.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Поле количества
              if (!_removeAll)
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Количество для удаления *',
                    prefixIcon: const Icon(Icons.remove),
                    suffixText: 'шт.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_removeAll) return null;
                    if (value?.isEmpty == true) return 'Введите количество';
                    final quantity = int.tryParse(value!);
                    if (quantity == null) return 'Введите целое число';
                    if (quantity <= 0) return 'Количество должно быть больше 0';
                    if (quantity > widget.stock.quantity) {
                      return 'Нельзя удалить больше, чем есть (${widget.stock.quantity})';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
              const SizedBox(height: 16),

              // Чекбокс "Удалить все"
              CheckboxListTile(
                value: _removeAll,
                onChanged: (value) => setState(() => _removeAll = value ?? false),
                title: const Text('Удалить весь остаток'),
                subtitle: Text(
                  'Будет удалено ${widget.stock.quantity} шт.',
                  style: const TextStyle(fontSize: 12),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: Colors.red.withOpacity(0.05),
              ),
              const SizedBox(height: 24),

              // Кнопки
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _remove,
                    icon: const Icon(Icons.check),
                    label: Text(_removeAll ? 'Удалить все' : 'Уменьшить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _remove() {
    if (_formKey.currentState!.validate()) {
      final quantity = _removeAll 
          ? widget.stock.quantity 
          : int.parse(_quantityController.text);
      widget.onRemove(quantity);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}