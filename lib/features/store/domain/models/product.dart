class Product {
  final String id;
  final String eventId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final String category;

  Product({
    required this.id,
    required this.eventId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.category,
  });

  Product copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Product &&
      other.id == id &&
      other.eventId == eventId &&
      other.name == name &&
      other.description == description &&
      other.price == price &&
      other.imageUrl == imageUrl &&
      other.isAvailable == isAvailable &&
      other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      eventId.hashCode ^
      name.hashCode ^
      description.hashCode ^
      price.hashCode ^
      imageUrl.hashCode ^
      isAvailable.hashCode ^
      category.hashCode;
  }
}
