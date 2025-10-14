import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/specifications.dart';
import '../models/product.dart';
import '../models/cart.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final CartItem? cartItem;
  // final Specification specification;
  

  const ProductDetailScreen({super.key, required this.product, this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(product.name, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        backgroundColor: Colors.blueAccent.shade700,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Фото товара
            Container(
              color: Colors.white,
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  product.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.image_not_supported, size: 50)),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 🧾 Название и цена
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)} ₸',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (product.originalPrice != null)
                        Text(
                          '${product.originalPrice!.toStringAsFixed(0)} ₸',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Компания: ${product.company}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Характеристики',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildSpecRow('Цвет', product.color),
                  _buildSpecRow('Память', product.storage),
                  _buildSpecRow('В наличии', product.count.toString()),

                  const Text(
                    'Дополнительные характеристики',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  ...product.specifications.map((spec) {
                    return _buildSpecRow(spec.name, spec.value);
                  }).toList(),
                  
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Описание',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10, width: double.infinity),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'Описание отсутствует.',
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80), // отступ под кнопку
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
              cartItem?.addItem(cartItem!.quantity); 
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} добавлен в корзину')),
              );
            },
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              label: const Text(
                'Добавить в корзину',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // вспомогательная функция для вывода строк характеристики
  Widget _buildSpecRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black87)),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
