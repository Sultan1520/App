import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product.dart';
import '../database/app_database.dart';
import 'package:intl/intl.dart';

/// Главный экран управления товарами с поиском, фильтрацией и статистикой
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final AppDatabase _dbHelper = AppDatabase.instance;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  
  // Здесь реализовано состояние фильтров и сортировки
  String _sortBy = 'date'; // 'date' или 'name'
  bool _isAscending = false;
  double _minPrice = 0;
  double _maxPrice = double.infinity;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// Здесь реализовано загрузка всех товаров из базы данных
  Future<void> _loadProducts() async {
    final products = await _dbHelper.getProducts();
    setState(() {
      _products = products;
      _applyFiltersAndSort();
    });
  }

  /// Применяет фильтры и сортировку к списку товаров
  void _applyFiltersAndSort() {
    List<Product> filtered = List.from(_products);

    // Поиск по GTIN или названию
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.gtin.contains(_searchController.text) ||
            product.name.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    }

    // Фильтр по цене
    filtered = filtered.where((product) {
      return product.price >= _minPrice && product.price <= _maxPrice;
    }).toList();

    // Сортировка
    if (_sortBy == 'date') {
      filtered.sort((a, b) {
        final dateA = a.createdAt != null ? DateTime.parse(a.createdAt!) : DateTime(0);
        final dateB = b.createdAt != null ? DateTime.parse(b.createdAt!) : DateTime(0);
        return _isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    } else {
      filtered.sort((a, b) => _isAscending
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name));
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  /// Показывает диалог добавления/редактирования товара
  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        product: product,
        onSave: (savedProduct) async {
          if (product == null) {
            await _dbHelper.insertProduct(savedProduct);
          } else {
            await _dbHelper.updateProduct(savedProduct);
          }
          _loadProducts();
        },
      ),
    );
  }

  /// Показывает диалог подтверждения удаления
  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить товар "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbHelper.deleteProduct(product.id!);
              Navigator.pop(context);
              _loadProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Товар удален')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  /// Показывает панель со статистикой
  void _showStatistics() {
    final totalProducts = _products.length;
    final totalValue = _products.fold<double>(0, (sum, p) => sum + p.price);
    final avgPrice = totalProducts > 0 ? totalValue / totalProducts : 0;
    final maxPrice = _products.isEmpty ? 0 : _products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final minPrice = _products.isEmpty ? 0 : _products.map((p) => p.price).reduce((a, b) => a < b ? a : b);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статистика товаров', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            _buildStatRow('Всего товаров:', '$totalProducts'),
            _buildStatRow('Общая стоимость:', '${totalValue.toStringAsFixed(2)} ₸'),
            _buildStatRow('Средняя цена:', '${avgPrice.toStringAsFixed(2)} ₸'),
            _buildStatRow('Максимальная цена:', '${maxPrice.toStringAsFixed(2)} ₸'),
            _buildStatRow('Минимальная цена:', '${minPrice.toStringAsFixed(2)} ₸'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление товарами'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStatistics,
            tooltip: 'Статистика',
          ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Фильтры',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по GTIN или названию',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFiltersAndSort();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => _applyFiltersAndSort(),
            ),
          ),

          // Панель фильтров и сортировки
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? Colors.grey[850] : Colors.grey[200],
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: const InputDecoration(
                            labelText: 'Сортировка',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'date', child: Text('По дате')),
                            DropdownMenuItem(value: 'name', child: Text('По названию')),
                          ],
                          onChanged: (value) {
                            setState(() => _sortBy = value!);
                            _applyFiltersAndSort();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                        onPressed: () {
                          setState(() => _isAscending = !_isAscending);
                          _applyFiltersAndSort();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Мин. цена',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _minPrice = double.tryParse(value) ?? 0;
                            _applyFiltersAndSort();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Макс. цена',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _maxPrice = double.tryParse(value) ?? double.infinity;
                            _applyFiltersAndSort();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Список товаров
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _products.isEmpty ? 'Нет товаров' : 'Ничего не найдено',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Добавить товар'),
      ),
    );
  }

  /// Создает карточку товара
  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDialog(product: product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Изображение товара
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.image != null && product.image!.isNotEmpty
                    ? Image.network(
                        product.image!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 16),
              // Информация о товаре
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GTIN: ${product.gtin}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text('${NumberFormat('#,###', 'ru_RU').format(product.price).replaceAll(',', ' ')} ₸',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                    Text(
                      _formatDate(DateTime.parse(product.createdAt!)),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Кнопки действий
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showProductDialog(product: product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(product),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[300],
      child: const Icon(Icons.inventory_2, color: Colors.grey),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Диалог для добавления/редактирования товара
class ProductDialog extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductDialog({Key? key, this.product, required this.onSave}) : super(key: key);

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _gtinController;
  late TextEditingController _priceController;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _gtinController = TextEditingController(text: widget.product?.gtin ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _imagePath = widget.product?.image;
  }

  /// Позволяет пользователю ввести URL изображения вручную
Future<void> _enterImageUrl() async {
  final TextEditingController urlController = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Введите URL изображения'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, urlController.text.trim()),
            child: const Text('ОК'),
          ),
        ],
      );
    },
  );

  if (result != null && result.isNotEmpty) {
    setState(() => _imagePath = result);
  }
}


  /// Валидация GTIN (13 цифр)
  String? _validateGtin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите GTIN';
    }
    if (value.length != 13) {
      return 'GTIN должен содержать 13 цифр';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'GTIN должен содержать только цифры';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product == null ? 'Добавить товар' : 'Редактировать товар',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                
                // Изображение
                Center(
                  child: GestureDetector(
                    onTap: _enterImageUrl,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Добавить фото', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Название
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название товара *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Введите название' : null,
                ),
                const SizedBox(height: 16),

                // GTIN
                TextFormField(
                  controller: _gtinController,
                  decoration: const InputDecoration(
                    labelText: 'GTIN (13 цифр) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 13,
                  validator: _validateGtin,
                ),
                const SizedBox(height: 16),

                // Цена
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Цена *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    suffixText: '₸',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Введите цену';
                    if (double.tryParse(value!) == null) return 'Введите корректную цену';
                    return null;
                  },
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
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final product = Product(
                            id: widget.product?.id,
                            name: _nameController.text,
                            gtin: _gtinController.text,
                            price: double.parse(_priceController.text),
                            status: widget.product?.status ?? 'активен',
                            image: _imagePath,
                            createdAt: widget.product?.createdAt ?? DateTime.now().toIso8601String(),
                          );
                          widget.onSave(product);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Сохранить'),
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

  @override
  void dispose() {
    _nameController.dispose();
    _gtinController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}