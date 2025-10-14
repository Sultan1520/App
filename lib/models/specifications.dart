class Specification {
  final String name;
  final String value;

  Specification({
    required this.name,
    required this.value,
  });

  factory Specification.fromJson(Map<String, dynamic> json) {
    return Specification(
      name: json['name'],
      value: json['value'],
    );
  }
}
