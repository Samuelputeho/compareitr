class OrderItemEntity {
  final String productId;
  final String itemName;
  final String shopName;
  final String imageUrl;
  final double price;
  final int quantity;
  final String measure;

  const OrderItemEntity({
    required this.productId,
    required this.itemName,
    required this.shopName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.measure,
  });
}
