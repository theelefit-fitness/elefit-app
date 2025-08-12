class Product {
  final String id;
  final String title;
  final double price;
  final double? compareAtPrice;
  final String imageUrl;
  final List<String> images;
  final String description;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.title,
    required this.price,
    this.compareAtPrice,
    required this.imageUrl,
    required this.images,
    required this.description,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final node = json['node'];
    final priceRange = node['priceRange']['minVariantPrice'];
    final compareAtPriceRange = node['compareAtPriceRange']?['minVariantPrice'];
    final images = (node['images']['edges'] as List)
        .map((edge) => edge['node']['url'] as String)
        .toList();
    final variants = node['variants']['edges'] as List;

    return Product(
      id: node['id'],
      title: node['title'],
      price: double.parse(priceRange['amount'].toString()),
      compareAtPrice: compareAtPriceRange != null 
          ? double.parse(compareAtPriceRange['amount'].toString())
          : null,
      imageUrl: images.isNotEmpty ? images.first : '',
      images: images,
      description: node['description'],
      variants: variants.map((variant) => ProductVariant.fromJson(variant['node'])).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}

class ProductVariant {
  final String id;
  final String title;
  final double price;

  ProductVariant({
    required this.id,
    required this.title,
    required this.price,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      title: json['title'],
      price: double.parse(json['price']['amount']),
    );
  }
} 