class CartEntity {
  final String id;
  final String cartId;
  final String itemName;
  final String shopName;
  final String imageUrl;
  final double price;
  final int quantity;
  final String measure;

  CartEntity({
    required this.id,
    required this.cartId,
    required this.itemName,
    required this.shopName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.measure,
  });

  // Add the copyWith method
  CartEntity copyWith({
    String? id,
    String? cartId,
    String? itemName,
    String? shopName,
    String? imageUrl,
    double? price,
    int? quantity,
    String? measure,
  }) {
    return CartEntity(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      itemName: itemName ?? this.itemName,
      shopName: shopName ?? this.shopName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      measure: measure ?? this.measure,
    );
  }
}
