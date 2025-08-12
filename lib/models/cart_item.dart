class CartItem {
  final String variantId;
  final int quantity;
  final String title;
  final double price;
  final String? imageUrl;

  CartItem({
    required this.variantId,
    required this.quantity,
    required this.title,
    required this.price,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'quantity': quantity,
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      variantId: json['variantId'] as String,
      quantity: json['quantity'] as int,
      title: json['title'] as String,
      price: json['price'] as double,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
