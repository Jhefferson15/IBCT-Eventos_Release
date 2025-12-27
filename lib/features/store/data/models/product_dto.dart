import '../../domain/models/product.dart';

class ProductDto {
  final String id;
  final String eventId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final String category;

  ProductDto({
    required this.id,
    required this.eventId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'category': category,
    };
  }

  factory ProductDto.fromMap(Map<String, dynamic> map, String id) {
    return ProductDto(
      id: id,
      eventId: map['event_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'] ?? '',
      isAvailable: map['is_available'] ?? true,
      category: map['category'] ?? '',
    );
  }

  factory ProductDto.fromDomain(Product product) {
    return ProductDto(
      id: product.id,
      eventId: product.eventId,
      name: product.name,
      description: product.description,
      price: product.price,
      imageUrl: product.imageUrl,
      isAvailable: product.isAvailable,
      category: product.category,
    );
  }

  Product toDomain() {
    return Product(
      id: id,
      eventId: eventId,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
      category: category,
    );
  }
}
