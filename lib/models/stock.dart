class Stock {
  final int? id;
  final String warehouse;
  final String gtin;
  int quantity;

  Stock({
    this.id,
    required this.warehouse,
    required this.gtin,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouse': warehouse,
      'gtin': gtin,
      'quantity': quantity,
    };
  }

  factory Stock.fromMap(Map<String, dynamic> map) => Stock(
        id: map['id'],
        warehouse: map['warehouse'],
        gtin: map['gtin'],
        quantity: map['quantity'],
      );
}
